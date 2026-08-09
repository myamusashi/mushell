#include "LyricsProvider.hpp"

#include <qcontainerfwd.h>
#include <qhashfunctions.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qnetworkaccessmanager.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qobject.h>
#include <qnumeric.h>
#include <qtypes.h>
#include <qtmetamacros.h>
#include <qurlquery.h>

#include <qvariant.h>

LyricsProvider::LyricsProvider(QObject* parent) : QObject(parent), mNam(new QNetworkAccessManager(this)), mScheduler(new vast::LyricsScheduler(this)) {
    connect(mScheduler, &vast::LyricsScheduler::currentIndexChanged, this, &LyricsProvider::currentIndexChanged);
    connect(mScheduler, &vast::LyricsScheduler::currentWordDurationChanged, this, &LyricsProvider::currentWordDurationChanged);
}

void LyricsProvider::setPlayback(double positionSecs, double rate, bool playing) {
    mScheduler->setPlayback(positionSecs, rate, playing);
}

void LyricsProvider::setOffsetMs(int offset) {
    if (mScheduler->offsetMs() == offset)
        return;
    mScheduler->setOffsetMs(offset);
    emit offsetMsChanged();
}

void LyricsProvider::fetch(const QString& title, const QString& artist, double durationSecs) {
    if (title.isEmpty() && artist.isEmpty()) {
        clear();
        return;
    }

    const QString key = vast::LyricsCache::key(title, artist, durationSecs);
    if (tryLoadFromCache(key))
        return;

    setState(State::Loading);

    QUrl      url("https://lrclib.net/api/get");
    QUrlQuery q;
    q.addQueryItem("track_name", title);
    q.addQueryItem("artist_name", artist);
    if (durationSecs > 0)
        q.addQueryItem("duration", QString::number(qRound(durationSecs)));
    url.setQuery(q);

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::UserAgentHeader, "Vast Shell/1.0");

    auto* reply = mNam->get(req);
    connect(reply, &QNetworkReply::finished, this, [this, reply, key, durationSecs] {
        reply->deleteLater();
        if (reply->error() != QNetworkReply::NoError) {
            setState(State::Error);
            return;
        }

        const QByteArray data = reply->readAll();
        const auto       json = QJsonDocument::fromJson(data).object();

        if (json.contains("code")) {
            setState(State::NotFound);
            return;
        }

        const QString lrc = json["syncedLyrics"].toString();
        if (!lrc.isEmpty()) {
            applyParseResult(vast::LrcParser::parseLrc(lrc, durationSecs));
            vast::LyricsCache::save(key, data);
            return;
        }

        const QString plain = json["plainLyrics"].toString();
        if (!plain.isEmpty()) {
            applyParseResult(vast::LrcParser::parsePlain(plain));
            vast::LyricsCache::save(key, data);
            return;
        }

        setState(State::NotFound);
    });
}

void LyricsProvider::clear() {
    mLines.clear();
    mWordLines.clear();
    mSynced     = false;
    mWordSynced = false;
    mScheduler->reset(); // emits currentIndexChanged itself
    setState(State::Idle);
    emit lyricsChanged();
}

void LyricsProvider::setState(State s) {
    if (mState == s)
        return;
    mState = s;
    emit stateChanged();
}

void LyricsProvider::applyParseResult(const vast::LrcParser::Result& result) {
    mLines      = result.lines;
    mWordLines  = result.wordLines;
    mSynced     = result.synced;
    mWordSynced = result.wordSynced;

    mScheduler->setWordLines(result.wordLines); // rebuilds boundaries + reschedules internally

    setState(State::Ready);
    emit lyricsChanged();
}

bool LyricsProvider::tryLoadFromCache(const QString& cacheKey) {
    const auto raw = vast::LyricsCache::load(cacheKey);
    if (!raw)
        return false;

    const auto    json = QJsonDocument::fromJson(*raw).object();
    const QString lrc  = json["syncedLyrics"].toString();
    if (!lrc.isEmpty()) {
        applyParseResult(vast::LrcParser::parseLrc(lrc, 0));
        return true;
    }
    const QString plain = json["plainLyrics"].toString();
    if (!plain.isEmpty()) {
        applyParseResult(vast::LrcParser::parsePlain(plain));
        return true;
    }
    return false;
}
