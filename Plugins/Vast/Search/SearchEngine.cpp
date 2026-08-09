#include "SearchEngine.hpp"
#include "../FuzzyMatcher.hpp"
#include "LaunchHistoryStore.hpp"

#include <qcontainerfwd.h>
#include <qobject.h>
#include <qnamespace.h>
#include <qlist.h>
#include <qregularexpression.h>
#include <algorithm>
#include <cmath>
#include <qstringview.h>
#include <qvariant.h>

namespace vast {

SearchEngine::SearchEngine(QObject* parent) : QObject(parent), mHistory(new LaunchHistoryStore(this)) {
    connect(mHistory, &LaunchHistoryStore::historyLimitChanged, this, &SearchEngine::historyLimitChanged);
}

QVariantList SearchEngine::searchApps(const QVariantList& apps, const QString& query) const {
    if (query.trimmed().isEmpty()) {
        QList<QPair<double, QVariant>> hits;
        hits.reserve(apps.size());
        for (const QVariant& v : apps) {
            auto* entry = qvariant_cast<QObject*>(v);
            if (!entry)
                continue;
            const double r = mHistory->recencyScore(entry->property("id").toString());
            hits.append({r, v});
        }
        std::ranges::stable_sort(hits, [](const QPair<double, QVariant>& a, const QPair<double, QVariant>& b) { return a.first > b.first; });
        QVariantList out;
        out.reserve(hits.size());
        for (const auto& h : hits)
            out.append(h.second);
        return out;
    }

    const QString     normQuery      = FuzzyMatcher::normalizeText(query).trimmed();
    const QStringList normQueryWords = normQuery.split(QRegularExpression("\\s+"), Qt::SkipEmptyParts);

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

        const double base = FuzzyMatcher::multiFieldScore(
            normQueryWords, normQuery, FuzzyMatcher::normalizeText(entry->property("name").toString()), FuzzyMatcher::normalizeText(entry->property("genericName").toString()),
            FuzzyMatcher::normalizeText(entry->property("comment").toString()));
        if (base < mAppThreshold)
            continue;

        const double finalScore = base + mHistory->recencyScore(entry->property("id").toString()) * FuzzyMatcher::K_RECENCY_WEIGHT;

        hits.append({.score = finalScore, .variant = v, .name = entry->property("name").toString()});
    }

    std::ranges::sort(hits, [](const Hit& a, const Hit& b) {
        if (std::abs(a.score - b.score) < 0.001)
            return a.name.length() < b.name.length();
        return a.score > b.score;
    });

    QVariantList out;
    out.reserve(hits.size());
    for (const Hit& h : hits)
        out.append(h.variant);
    return out;
}

void SearchEngine::recordLaunch(const QString& appId) {
    mHistory->recordLaunch(appId);
}

void SearchEngine::clearHistory() {
    mHistory->clearHistory();
}

QVariantList SearchEngine::searchFiles(const QVariantList& files, const QString& query) const {
    if (query.trimmed().isEmpty())
        return files;

    struct Hit {
        double   score;
        QVariant variant;
        QString  name;
    };
    QList<Hit> hits;

    for (const QVariant& v : files) {
        const QString name = v.toMap().value("fileName").toString();
        const double  s    = FuzzyMatcher::fuzzyScore(query, name);
        if (s >= mFileThreshold)
            hits.append({.score = s, .variant = v, .name = name});
    }

    std::ranges::sort(hits, [](const Hit& a, const Hit& b) {
        if (std::abs(a.score - b.score) < 0.001)
            return a.name.length() < b.name.length();
        return a.score > b.score;
    });

    QVariantList out;
    out.reserve(hits.size());
    for (const Hit& h : hits)
        out.append(h.variant);
    return out;
}

QString SearchEngine::highlightedHtml(const QString& text, const QString& query, const QString& color) {
    return FuzzyMatcher::highlightedHtml(text, query, color);
}

QVariantList SearchEngine::highlightRanges(const QString& text, const QString& query) {
    return FuzzyMatcher::highlightRanges(text, query);
}

double SearchEngine::score(const QString& query, const QString& text) {
    return FuzzyMatcher::fuzzyScore(query, text);
}

}
