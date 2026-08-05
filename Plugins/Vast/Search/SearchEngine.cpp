#include "SearchEngine.hpp"
#include "FuzzyMatcher.hpp"

#include <qdatetime.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qregularexpression.h>
#include <algorithm>
#include <cmath>

SearchEngine::SearchEngine(QObject* parent) : QObject(parent) {
    m_settings = new QSettings("vast-shell", "myamusashi", this);
    loadHistory();
}

void SearchEngine::loadHistory() {
    m_history.clear();
    const QByteArray raw = m_settings->value("launchHistory").toByteArray();
    if (raw.isEmpty())
        return;

    const QJsonArray arr = QJsonDocument::fromJson(raw).array();
    for (const QJsonValue& v : arr) {
        const QJsonObject obj = v.toObject();
        HistoryEntry      e;
        e.id        = obj["id"].toString();
        e.timestamp = obj["timestamp"].toVariant().toLongLong();
        e.count     = obj["count"].toInt();
        if (!e.id.isEmpty())
            m_history.append(e);
    }
}

void SearchEngine::saveHistory() {
    QJsonArray arr;
    for (const HistoryEntry& e : m_history) {
        QJsonObject obj;
        obj["id"]        = e.id;
        obj["timestamp"] = e.timestamp;
        obj["count"]     = e.count;
        arr.append(obj);
    }
    m_settings->setValue("launchHistory", QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

double SearchEngine::recencyScore(const QString& appId) const {
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    auto         it  = std::ranges::find_if(m_history, [&](const HistoryEntry& e) { return e.id == appId; });

    if (it == m_history.end())
        return 0.0;

    const double age       = static_cast<double>(now - it->timestamp);
    const double recency   = std::exp(-age / (86400000.0 * 7.0));
    const double frequency = std::min(it->count / 10.0, 1.0);
    return recency * 0.7 + frequency * 0.3;
}

double SearchEngine::scoreApp(QObject* entry, const QStringList& normQueryWords, const QString& normQuery) const {
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
            QObject* entry = qvariant_cast<QObject*>(v);
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
        QObject* entry = qvariant_cast<QObject*>(v);
        if (!entry)
            continue;

        const double base = scoreApp(entry, normQueryWords, normQuery);
        if (base < m_appThreshold)
            continue;

        const double finalScore = base + recencyScore(entry->property("id").toString()) * FuzzyMatcher::kRecencyWeight;

        hits.append({finalScore, v, entry->property("name").toString()});
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
    auto         it  = std::ranges::find_if(m_history, [&](const HistoryEntry& e) { return e.id == appId; });

    if (it != m_history.end()) {
        it->timestamp = now;
        it->count++;
    } else
        m_history.append({appId, now, 1});

    if (m_history.size() > m_historyLimit) {
        std::ranges::sort(m_history, [](const HistoryEntry& a, const HistoryEntry& b) { return a.timestamp > b.timestamp; });
        m_history.resize(m_historyLimit);
    }

    saveHistory();
}

void SearchEngine::clearHistory() {
    m_history.clear();
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
        if (s >= m_fileThreshold)
            hits.append({s, v, name});
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

QString SearchEngine::highlightedHtml(const QString& text, const QString& query, const QString& color) const {
    return FuzzyMatcher::highlightedHtml(text, query, color);
}

QVariantList SearchEngine::highlightRanges(const QString& text, const QString& query) const {
    return FuzzyMatcher::highlightRanges(text, query);
}

double SearchEngine::score(const QString& query, const QString& text) const {
    return FuzzyMatcher::fuzzyScore(query, text);
}
