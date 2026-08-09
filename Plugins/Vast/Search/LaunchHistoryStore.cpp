#include "LaunchHistoryStore.hpp"

#include <qbytearray.h>
#include <qdatetime.h>
#include <qjsonarray.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qobject.h>
#include <qobjectdefs.h>
#include <qsettings.h>
#include <qtmetamacros.h>
#include <qtypes.h>

#include <algorithm>
#include <cmath>

namespace vast {

LaunchHistoryStore::LaunchHistoryStore(QObject* parent) : QObject(parent) {
    mSettings = new QSettings("vast-shell", "myamusashi", this);
    loadHistory();
}

void LaunchHistoryStore::setHistoryLimit(int value) {
    if (mHistoryLimit != value) {
        mHistoryLimit = value;
        emit historyLimitChanged();
    }
}

void LaunchHistoryStore::loadHistory() {
    mHistory.clear();
    const QByteArray raw = mSettings->value("launchHistory").toByteArray();
    if (raw.isEmpty())
        return;

    const QJsonArray arr = QJsonDocument::fromJson(raw).array();
    for (const auto& value : arr) {
        const QJsonObject object = value.toObject();
        HistoryEntry      entry;
        entry.id        = object["id"].toString();
        entry.timestamp = object["timestamp"].toVariant().toLongLong();
        entry.count     = object["count"].toInt();
        if (!entry.id.isEmpty())
            mHistory.append(entry);
    }
}

void LaunchHistoryStore::saveHistory() {
    QJsonArray arr;
    for (const HistoryEntry& entry : mHistory) {
        QJsonObject object;
        object["id"]        = entry.id;
        object["timestamp"] = entry.timestamp;
        object["count"]     = entry.count;
        arr.append(object);
    }
    mSettings->setValue("launchHistory", QJsonDocument(arr).toJson(QJsonDocument::Compact));
}

double LaunchHistoryStore::recencyScore(const QString& appId) const {
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    auto         it  = std::ranges::find_if(mHistory, [&](const HistoryEntry& entry) { return entry.id == appId; });

    if (it == mHistory.end())
        return 0.0;

    const auto   age       = static_cast<double>(now - it->timestamp);
    const double recency   = std::exp(-age / (86400000.0 * 7.0));
    const double frequency = std::min(it->count / 10.0, 1.0);
    return recency * 0.7 + frequency * 0.3;
}

void LaunchHistoryStore::recordLaunch(const QString& appId) {
    const qint64 now = QDateTime::currentMSecsSinceEpoch();
    auto         it  = std::ranges::find_if(mHistory, [&](const HistoryEntry& entry) { return entry.id == appId; });

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

void LaunchHistoryStore::clearHistory() {
    mHistory.clear();
    saveHistory();
}

}
