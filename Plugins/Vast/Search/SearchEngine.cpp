#include "SearchEngine.hpp"
#include "../FuzzyMatcher.hpp"
#include "FileSearchModel.hpp"
#include "LaunchHistoryStore.hpp"

#include <qassert.h>
#include <qcontainerfwd.h>
#include <qlist.h>
#include <qlogging.h>
#include <qnamespace.h>
#include <qobject.h>
#include <qobjectdefs.h>
#include <qregularexpression.h>
#include <qset.h>
#include <qstring.h>
#include <qthread.h>
#include <qthreadpool.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>
#include <algorithm>
#include <atomic>
#include <cmath>
#include <qstringview.h>
#include <vector>

namespace vast {

    namespace {
        constexpr double K_SCORE_TIE_EPSILON = 0.001;
    }

    SearchEngine::SearchEngine(QObject* parent) : QObject(parent), mHistory(new LaunchHistoryStore(this)), mFileResults(new FileSearchModel(this)) {
        connect(mHistory, &LaunchHistoryStore::historyLimitChanged, this, &SearchEngine::historyLimitChanged);
    }

    SearchEngine::CachedApp SearchEngine::cachedAppFields(const QObject* entry) const {
        // The cache mutates lazily inside this const method; it is only safe
        // because searchApps runs on the owning (UI) thread. Tripwire for
        // anyone moving it onto a worker like searchFilesAsync.
        Q_ASSERT(this->thread() == QThread::currentThread());

        const QString id = entry->property("id").toString();

        CachedApp     cached;
        if (const auto it = mAppCache.constFind(id); it != mAppCache.constEnd())
            cached = it.value();

        const QString rawName        = entry->property("name").toString();
        const QString rawGenericName = entry->property("genericName").toString();
        const QString rawComment     = entry->property("comment").toString();

        // Raw-string comparison invalidates exactly the fields whose source
        // changed (app updates), at a fraction of a normalizeText pass.
        if (cached.name.raw != rawName) {
            cached.name.text.normalized = FuzzyMatcher::normalizeText(rawName);
            cached.name.text.utf8       = cached.name.text.normalized.toUtf8();
            cached.name.raw             = rawName;
        }
        if (cached.genericName.raw != rawGenericName) {
            cached.genericName.text.normalized = FuzzyMatcher::normalizeText(rawGenericName);
            cached.genericName.text.utf8       = cached.genericName.text.normalized.toUtf8();
            cached.genericName.raw             = rawGenericName;
        }
        if (cached.comment.raw != rawComment) {
            cached.comment.text.normalized = FuzzyMatcher::normalizeText(rawComment);
            cached.comment.text.utf8       = cached.comment.text.normalized.toUtf8();
            cached.comment.raw             = rawComment;
        }

        mAppCache.insert(id, cached);
        return cached;
    }

    void SearchEngine::pruneAppCache(QHash<QString, CachedApp>& cache, const QSet<QString>& activeIds) {
        if (cache.size() <= activeIds.size())
            return;
        cache.removeIf([&](auto it) { return !activeIds.contains(it.key()); });
    }

    QVariantList SearchEngine::searchApps(const QVariantList& apps, const QString& query) const {
        // Ids seen this call drive cache pruning below, so entries removed
        // from the launcher (uninstalls, list refreshes) evict exactly their
        // own cached fields.
        QSet<QString> activeIds;
        activeIds.reserve(apps.size());

        if (query.trimmed().isEmpty()) {
            QList<QPair<double, QVariant>> hits;
            hits.reserve(apps.size());
            for (const QVariant& v : apps) {
                auto* entry = qvariant_cast<QObject*>(v);
                if (!entry)
                    continue;
                const QString id = entry->property("id").toString();
                activeIds.insert(id);
                const double r = mHistory->recencyScore(id);
                hits.append({r, v});
            }
            pruneAppCache(mAppCache, activeIds);
            std::ranges::stable_sort(hits, [](const QPair<double, QVariant>& a, const QPair<double, QVariant>& b) { return a.first > b.first; });
            QVariantList out;
            out.reserve(hits.size());
            for (const auto& h : hits)
                out.append(h.second);
            return out;
        }

        const QString     normQuery      = FuzzyMatcher::normalizeText(query).trimmed();
        const QStringList normQueryWords = normQuery.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

        // Query words are encoded exactly once per keystroke and reused
        // across every app x field pair below.
        const std::vector<FuzzyMatcher::EncodedWord> encodedWords = FuzzyMatcher::encodeWords(normQueryWords);

        qsizetype                                    queryChars = 0;
        for (const FuzzyMatcher::EncodedWord& word : encodedWords)
            queryChars += word.charCount;

        struct Hit {
            double   score;
            QVariant variant;
            QString  name;
        };
        QList<Hit> hits;

        for (const QVariant& v : apps) {
            auto* entry = qvariant_cast<QObject*>(v);
            if (!entry)
                continue;

            const QString appId = entry->property("id").toString();
            activeIds.insert(appId);

            const SearchEngine::CachedApp&  fields = cachedAppFields(entry);

            const FuzzyMatcher::CachedText* generic = fields.genericName.raw.isEmpty() ? nullptr : &fields.genericName.text;
            const FuzzyMatcher::CachedText* comment = fields.comment.raw.isEmpty() ? nullptr : &fields.comment.text;

            const double                    base = FuzzyMatcher::multiFieldScoreUtf8(encodedWords, queryChars, fields.name.text, generic, comment);
            if (base < mAppThreshold * static_cast<double>(queryChars))
                continue;

            const double recency    = mHistory->recencyScore(appId);
            const double finalScore = base * (1.0 + recency * FuzzyMatcher::K_RECENCY_WEIGHT);

            hits.append({.score = finalScore, .variant = v, .name = entry->property("name").toString()});
        }

        pruneAppCache(mAppCache, activeIds);

        std::ranges::sort(hits, [](const Hit& a, const Hit& b) {
            if (std::abs(a.score - b.score) < K_SCORE_TIE_EPSILON)
                return a.name.length() < b.name.length();
            return a.score > b.score;
        });

        QVariantList out;
        out.reserve(hits.size());
        for (const Hit& h : hits)
            out.append(h.variant);
        return out;
    }

    void SearchEngine::searchFilesAsync(const QVariantList& files, const QString& query) {
        const int    generation       = mFileSearchGeneration.fetchAndAddRelaxed(1) + 1;
        const double thresholdPerChar = mFileThreshold;

        emit         fileSearchStarted();

        QThreadPool::globalInstance()->start([this, generation, thresholdPerChar, files, query]() {
            static const QRegularExpression kWhitespace(R"(\s+)");

            const QString                   normQuery  = FuzzyMatcher::normalizeText(query).trimmed();
            const QStringList               queryWords = normQuery.split(kWhitespace, Qt::SkipEmptyParts);

            // Query words encoded once for the whole candidate sweep.
            const std::vector<FuzzyMatcher::EncodedWord> encodedWords = FuzzyMatcher::encodeWords(queryWords);

            qsizetype                                    queryChars = 0;
            for (const FuzzyMatcher::EncodedWord& word : encodedWords)
                queryChars += word.charCount;

            if (queryChars == 0) {
                QMetaObject::invokeMethod(
                    this,
                    [this, generation]() {
                        if (mFileSearchGeneration.loadRelaxed() != generation)
                            return;
                        mFileResults->clear();
                    },
                    Qt::QueuedConnection);
                return;
            }

            struct Hit {
                double   score;
                QVariant variant;
                QString  path;
            };

            QList<Hit> hits;
            hits.reserve(files.size());

            for (const QVariant& v : files) {
                // Score the relative path, not the bare name: fzy's slash
                // bonus makes path-aware queries ("src main") rank naturally.
                // The normalized/encoded forms were baked in at walk time;
                // recompute only if an entry somehow lacks them.
                const QVariantMap entryMap = v.toMap();
                const QString     relPath  = entryMap.value(QStringLiteral("relativePath")).toString();
                QString           normRel  = entryMap.value(QStringLiteral("relativePathNorm")).toString();
                QByteArray        relUtf8  = entryMap.value(QStringLiteral("relativePathUtf8")).toByteArray();

                if (normRel.isEmpty() && !relPath.isEmpty()) {
                    // Results stay correct but silently degrade to
                    // per-keystroke recomputation; make a producer regression
                    // (DirectoryWalker dropping its baked fields) visible.
                    static std::atomic<bool> warnedOnce{false};
                    if (!warnedOnce.exchange(true))
                        qWarning() << "file search: entry missing precomputed relativePathNorm/Utf8; falling back to per-search encoding";

                    normRel = FuzzyMatcher::normalizeText(relPath);
                    relUtf8 = normRel.toUtf8();
                }

                const double baseScore = FuzzyMatcher::multiWordScoreUtf8(encodedWords, {.normalized = normRel, .utf8 = relUtf8});
                if (baseScore >= thresholdPerChar * static_cast<double>(queryChars))
                    hits.append({.score = baseScore, .variant = v, .path = relPath});
            }

            std::ranges::sort(hits, [](const Hit& a, const Hit& b) {
                if (std::abs(a.score - b.score) < K_SCORE_TIE_EPSILON)
                    return a.path.length() < b.path.length();
                return a.score > b.score;
            });

            QVariantList out;
            out.reserve(hits.size());
            for (const Hit& h : hits)
                out.append(h.variant);

            QMetaObject::invokeMethod(
                this,
                [this, generation, out]() {
                    if (mFileSearchGeneration.loadRelaxed() != generation)
                        return;
                    mFileResults->setEntries(out);
                },
                Qt::QueuedConnection);
        });
    }

    void SearchEngine::recordLaunch(const QString& appId) {
        mHistory->recordLaunch(appId);
    }

    double SearchEngine::recencyScore(const QString& appId) const {
        return mHistory->recencyScore(appId);
    }

    void SearchEngine::clearHistory() {
        mHistory->clearHistory();
    }

    void SearchEngine::clearFileResults() {
        mFileResults->clear();
    }

    QString SearchEngine::highlightedHtml(const QString& text, const QString& query, const QString& color) {
        return FuzzyMatcher::highlightedHtml(text, query, color);
    }

    double SearchEngine::score(const QString& query, const QString& text) {
        return FuzzyMatcher::fuzzyScore(query, text);
    }

}
