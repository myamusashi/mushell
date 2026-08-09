#include "LyricsProvider.hpp"

#include <iterator>
#include <qcontainerfwd.h>
#include <qcryptographichash.h>
#include <qdatetime.h>
#include <qdir.h>
#include <qfile.h>
#include <qhashfunctions.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qnetworkaccessmanager.h>
#include <qnamespace.h>
#include <qlist.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qobject.h>
#include <qnumeric.h>
#include <qstandardpaths.h>
#include <qtypes.h>
#include <qtmetamacros.h>
#include <qurlquery.h>

#include <algorithm>
#include <qvariant.h>

LyricsProvider::LyricsProvider(QObject* parent) : QObject(parent), mNam(new QNetworkAccessManager(this)) {
    mWordTimer.setSingleShot(true);
    mWordTimer.setTimerType(Qt::PreciseTimer);
    connect(&mWordTimer, &QTimer::timeout, this, &LyricsProvider::onWordTimer);
}

qint64 LyricsProvider::currentPositionMs() const {
    if (!mPlaying)
        return mAnchorMs;
    const qint64 wallNow       = QDateTime::currentMSecsSinceEpoch();
    const auto   elapsed       = static_cast<double>(wallNow - mAnchorWall);
    const auto   scaledElapsed = static_cast<qint64>(std::llround(elapsed * mRate));
    return mAnchorMs + scaledElapsed + mOffsetMs;
}

void LyricsProvider::setPlayback(double positionSecs, double rate, bool playing) {
    mAnchorMs   = static_cast<qint64>(positionSecs * 1000.0);
    mAnchorWall = QDateTime::currentMSecsSinceEpoch();
    mRate       = rate;
    mPlaying    = playing;

    mWordTimer.stop();

    if (!mSynced || mBoundaries.isEmpty())
        return;

    const qint64 posMs = currentPositionMs();
    seekTo(posMs);

    if (mPlaying)
        scheduleNext();
}

void LyricsProvider::setOffsetMs(int offset) {
    if (mOffsetMs == offset)
        return;
    mOffsetMs = offset;
    emit offsetMsChanged();

    if (!mSynced || mBoundaries.isEmpty())
        return;

    mWordTimer.stop();
    const qint64 posMs = currentPositionMs();
    seekTo(posMs);

    if (mPlaying)
        scheduleNext();
}

void LyricsProvider::fetch(const QString& title, const QString& artist, double durationSecs) {
    if (title.isEmpty() && artist.isEmpty()) {
        clear();
        return;
    }

    const QString key = cacheKey(title, artist, durationSecs);
    if (loadFromCache(key))
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
            saveToCache(key, data);
            return;
        }

        const QString plain = json["plainLyrics"].toString();
        if (!plain.isEmpty()) {
            applyParseResult(vast::LrcParser::parsePlain(plain));
            saveToCache(key, data);
            return;
        }

        setState(State::NotFound);
    });
}

void LyricsProvider::clear() {
    mWordTimer.stop();
    mLines.clear();
    mWordLines.clear();
    mBoundaries.clear();
    mSynced          = false;
    mWordSynced      = false;
    mCurLine         = -1;
    mCurWord         = -1;
    mCurWordDuration = 0;
    setState(State::Idle);
    emit lyricsChanged();
    emit currentIndexChanged();
}

void LyricsProvider::seekTo(qint64 posMs) {
    // Find the last boundary with timeMs <= posMs using upper_bound - 1
    auto            it    = std::ranges::upper_bound(mBoundaries, posMs, {}, &WordBoundary::timeMs);
    const qsizetype found = (it != mBoundaries.begin()) ? std::distance(mBoundaries.begin(), std::prev(it)) : -1;

    const int       newLine = (found >= 0) ? mBoundaries[found].lineIndex : -1;
    const int       newWord = (found >= 0) ? mBoundaries[found].wordIndex : -1;

    bool            durationChanged = false;
    qint64          newDuration     = 0;
    if (newLine >= 0 && newWord >= 0 && newLine < mWordLines.size()) {
        const auto wl    = mWordLines[newLine].toMap();
        const auto words = wl["words"].toList();
        if (newWord < words.size())
            newDuration = words[newWord].toMap()["duration"].toLongLong();
    }

    if (newDuration != mCurWordDuration) {
        mCurWordDuration = newDuration;
        durationChanged  = true;
    }

    if (newLine != mCurLine || newWord != mCurWord) {
        mCurLine = newLine;
        mCurWord = newWord;
        emit currentIndexChanged();
    }

    if (durationChanged)
        emit currentWordDurationChanged();

    // store where we are in the boundary list for O(1) next-boundary lookup
    mBoundaryPos = found + 1;
}

void LyricsProvider::scheduleNext() {
    const qint64 nowMs = currentPositionMs();

    // Skip past all boundaries already in the past (iterative, no recursion)
    while (mBoundaryPos < mBoundaries.size() && mBoundaries[mBoundaryPos].timeMs <= nowMs) {
        ++mBoundaryPos;
    }

    if (mBoundaryPos >= mBoundaries.size())
        return;

    const qint64 delayMs = mBoundaries[mBoundaryPos].timeMs - nowMs;
    if (delayMs > 60'000)
        return;

    mWordTimer.start(static_cast<int>(delayMs));
}

void LyricsProvider::onWordTimer() {
    if (!mPlaying)
        return;

    const qint64 nowMs = currentPositionMs();

    bool         changedIndex = false;
    while (mBoundaryPos < mBoundaries.size() && mBoundaries[mBoundaryPos].timeMs <= nowMs) {
        const auto& b = mBoundaries[mBoundaryPos];
        mCurLine      = b.lineIndex;
        mCurWord      = b.wordIndex;
        changedIndex  = true;
        ++mBoundaryPos;
    }

    if (changedIndex) {
        emit   currentIndexChanged();

        qint64 newDuration = 0;
        if (mCurLine >= 0 && mCurWord >= 0 && mCurLine < mWordLines.size()) {
            const auto wl    = mWordLines[mCurLine].toMap();
            const auto words = wl["words"].toList();
            if (mCurWord < words.size())
                newDuration = words[mCurWord].toMap()["duration"].toLongLong();
        }
        if (newDuration != mCurWordDuration) {
            mCurWordDuration = newDuration;
            emit currentWordDurationChanged();
        }
    }

    scheduleNext();
}

// parsing
void LyricsProvider::rebuildBoundaries() {
    mBoundaries.clear();
    for (int li = 0; li < mWordLines.size(); ++li) {
        const auto& wlEntry = mWordLines[li].toMap();
        const auto  words   = wlEntry["words"].toList();
        for (int wi = 0; wi < words.size(); ++wi) {
            const auto   word = words[wi].toMap();
            const qint64 t    = word["time"].toLongLong();
            if (t < 0)
                continue;
            mBoundaries.append({.timeMs = t, .lineIndex = li, .wordIndex = wi});
        }
    }
    std::ranges::stable_sort(mBoundaries, {}, &WordBoundary::timeMs);
}

void LyricsProvider::setState(State s) {
    if (mState == s)
        return;
    mState = s;
    emit stateChanged();
}

QString LyricsProvider::cacheKey(const QString& title, const QString& artist, double durationSecs) {
    const QString raw = artist + "|" + title + "|" + QString::number(qRound(durationSecs));
    return QCryptographicHash::hash(raw.toUtf8(), QCryptographicHash::Sha1).toHex();
}

QString LyricsProvider::cachePath(const QString& key) {
    const QString dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/lyrics";
    QDir().mkpath(dir);
    return dir + "/" + key + ".json";
}

bool LyricsProvider::loadFromCache(const QString& key) {
    QFile f(cachePath(key));
    if (!f.open(QIODevice::ReadOnly))
        return false;
    const auto json = QJsonDocument::fromJson(f.readAll()).object();
    f.close();
    const QString lrc = json["syncedLyrics"].toString();
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

void LyricsProvider::saveToCache(const QString& key, const QByteArray& data) {
    QFile f(cachePath(key));
    if (f.open(QIODevice::WriteOnly))
        f.write(data);
}
