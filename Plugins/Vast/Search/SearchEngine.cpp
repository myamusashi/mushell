#include "SearchEngine.hpp"
#include "../FuzzyMatcher.hpp"

#include <qcontainerfwd.h>
#include <qdatetime.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qobject.h>
#include <qnamespace.h>
#include <qlist.h>
#include <qregularexpression.h>
#include <algorithm>
#include <cmath>
#include <qsettings.h>
#include <qstringview.h>
#include <qtypes.h>
#include <qvariant.h>

SearchEngine::SearchEngine(QObject* parent) : QObject(parent) {
    mSettings = new QSettings("vast-shell", "myamusashi", this);
    loadHistory();
}

void SearchEngine::loadHistory() {
    mHistory.clear();
    const QByteArray raw = mSettings->value("launchHistory").toByteArray();
    if (raw.isEmpty())
        return;

    const QJsonArray arr = QJsonDocument::fromJson(raw).array();
    for (const auto& v : arr) {
        const QJsonObject obj = v.toObject();
        HistoryEntry      e;
        e.id        = obj["id"].toString();
        e.timestamp = obj["timestamp"].toVariant().toLongLong();
        e.count     = obj["count"].toInt();
        if (!e.id.isEmpty())
            mHistory.append(e);
    }
}

void SearchEngine::saveHistory() {
    QJsonArray arr;
    for (const HistoryEntry& e : mHistory) {
        QJsonObject obj;
        obj["id"]        = e.id;
        obj["timestamp"] = e.timestamp;
        obj["count"]     = e.count;
        arr.append(obj);
    }
    mSettings->setValue("launchHistory", QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

double SearchEngine::recencyScore(const QString& appId) const {
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    auto         it  = std::ranges::find_if(mHistory, [&](const HistoryEntry& e) { return e.id == appId; });

    if (it == mHistory.end())
        return 0.0;

    const auto   age       = static_cast<double>(now - it->timestamp);
    const double recency   = std::exp(-age / (86400000.0 * 7.0));
    const double frequency = std::min(it->count / 10.0, 1.0);
    return recency * 0.7 + frequency * 0.3;
}

double SearchEngine::scoreApp(QObject* entry, const QStringList& normQueryWords, const QString& normQuery) {
    const QString                   name        = FuzzyMatcher::normalizeText(entry->property("name").toString());
    const QString                   genericName = FuzzyMatcher::normalizeText(entry->property("genericName").toString());
    const QString                   comment     = FuzzyMatcher::normalizeText(entry->property("comment").toString());
    static const QRegularExpression kWhitespace(R"(\s+)");

    const QStringList               nameWords = name.split(kWhitespace, Qt::SkipEmptyParts);

    double                          nameScore = 0.0;
    if (name == normQuery)
        nameScore = 1.0;
    else if (name.contains(normQuery))
        nameScore = 0.95;
    else
        nameScore = FuzzyMatcher::getMultiWordScore(normQueryWords, name, nameWords);

    if (nameScore >= 0.9)
        return nameScore;

    double genericScore = 0.0;
    if (!genericName.isEmpty()) {
        const QStringList gWords = genericName.split(kWhitespace, Qt::SkipEmptyParts);
        genericScore             = FuzzyMatcher::getMultiWordScore(normQueryWords, genericName, gWords) * 0.7;
    }

    double commentScore = 0.0;
    if (!comment.isEmpty()) {
        const QStringList cWords = comment.split(kWhitespace, Qt::SkipEmptyParts);
        commentScore             = FuzzyMatcher::getMultiWordScore(normQueryWords, comment, cWords) * 0.5;
    }

    return std::max({nameScore, genericScore, commentScore});
}

QVariantList SearchEngine::searchApps(const QVariantList& apps, const QString& query) const {
    if (query.trimmed().isEmpty()) {
        QList<QPair<double, QVariant>> hits;
        hits.reserve(apps.size());
        for (const QVariant& v : apps) {
            auto* entry = qvariant_cast<QObject*>(v);
            if (!entry)
                continue;
            const double r = recencyScore(entry->property("id").toString());
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

        const double base = scoreApp(entry, normQueryWords, normQuery);
        if (base < mAppThreshold)
            continue;

        const double finalScore = base + recencyScore(entry->property("id").toString()) * FuzzyMatcher::K_RECENCY_WEIGHT;

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
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    auto         it  = std::ranges::find_if(mHistory, [&](const HistoryEntry& e) { return e.id == appId; });

    if (it != mHistory.end()) {
        it->timestamp = now;
        it->count++;
    } else
        mHistory.append({.id = appId, .timestamp = now, .count = 1});

    if (mHistory.size() > mHistoryLimit) {
        std::ranges::sort(mHistory, [](const HistoryEntry& a, const HistoryEntry& b) { return a.timestamp > b.timestamp; });
        mHistory.resize(mHistoryLimit);
    }

    saveHistory();
}

void SearchEngine::clearHistory() {
    mHistory.clear();
    saveHistory();
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
