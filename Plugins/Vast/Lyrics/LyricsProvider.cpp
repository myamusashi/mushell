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
#include <qminmax.h>
#include <qnetworkreply.h>
#include <qnetworkrequest.h>
#include <qobject.h>
#include <qnumeric.h>
#include <qregularexpression.h>
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
            parseLrc(lrc, durationSecs);
            saveToCache(key, data);
            return;
        }

        const QString plain = json["plainLyrics"].toString();
        if (!plain.isEmpty()) {
            parsePlain(plain);
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

qint64 LyricsProvider::parseTimestamp(const QString& mm, const QString& ss, const QString& frac) {
    const int min = mm.toInt();
    const int sec = ss.toInt();
    const int ms  = (frac.length() == 2) ? frac.toInt() * 10 : frac.toInt();
    return static_cast<qint64>(min * 60 + sec) * 1000 + ms;
}

bool LyricsProvider::parseLrc(const QString& lrc, double totalDurationSecs) {
    static const QRegularExpression lineRe(R"(\[(\d{2}):(\d{2})\.(\d{2,3})\](.*))");
    static const QRegularExpression wordRe(R"(<(\d{2}):(\d{2})\.(\d{2,3})>([^<]*))");

    struct RawLine {
        qint64  timeMs;
        QString content;
    };
    QList<RawLine> raw;

    for (const QString& line : lrc.split('\n')) {
        auto m = lineRe.match(line.trimmed());
        if (!m.hasMatch())
            continue;
        raw.append({.timeMs = parseTimestamp(m.captured(1), m.captured(2), m.captured(3)), .content = m.captured(4).trimmed()});
    }
    if (raw.isEmpty())
        return false;

    bool         foundWordTs = false;
    QVariantList newLines;
    QVariantList newWordLines;
    const auto   totalMs = static_cast<qint64>(totalDurationSecs * 1000.0);

    for (int i = 0; i < raw.size(); ++i) {
        const qint64  lineStart = raw[i].timeMs;
        const QString content   = raw[i].content;
        const qint64  lineEnd   = (i + 1 < raw.size()) ? raw[i + 1].timeMs : qMax(lineStart + 5000, totalMs);
        if (content.isEmpty())
            continue;

        const qsizetype caretIdx  = content.indexOf('^');
        const QString   srcText   = (caretIdx >= 0) ? content.left(caretIdx).trimmed() : content;
        const QString   transText = (caretIdx >= 0) ? content.mid(caretIdx + 1).trimmed() : QString();

        QVariantMap     lineEntry;
        lineEntry["time"]        = lineStart;
        lineEntry["text"]        = srcText;
        lineEntry["translation"] = transText;
        newLines.append(lineEntry);

        QVariantList words;
        auto         wit = wordRe.globalMatch(srcText);
        if (wit.hasNext()) {
            foundWordTs = true;
            while (wit.hasNext()) {
                auto          wm   = wit.next();
                const QString text = wm.captured(4).trimmed();
                if (text.isEmpty())
                    continue;
                QVariantMap w;
                w["time"] = parseTimestamp(wm.captured(1), wm.captured(2), wm.captured(3));
                w["text"] = text;
                words.append(w);
            }
            for (int j = 0; j < words.size(); ++j) {
                QVariantMap  w     = words[j].toMap();
                qint64 const t     = w["time"].toLongLong();
                qint64       nextT = lineEnd;
                if (j + 1 < words.size())
                    nextT = words[j + 1].toMap()["time"].toLongLong();
                else {
                    qint64 const maxLastWord = 1500;
                    if (nextT - t > maxLastWord)
                        nextT = t + maxLastWord;
                }
                w["duration"] = qMax<qint64>(0, nextT - t);
                words.replace(j, w);
            }
        } else {
            QString plain = srcText;
            plain.remove(QRegularExpression(R"(<[^>]+>)"));
            words = interpolateWords(plain.trimmed(), lineStart, lineEnd);
        }

        QVariantMap wlEntry;
        wlEntry["time"]  = lineStart;
        wlEntry["words"] = words;
        newWordLines.append(wlEntry);
    }

    mLines      = newLines;
    mWordLines  = newWordLines;
    mSynced     = true;
    mWordSynced = foundWordTs;

    rebuildBoundaries();
    setState(State::Ready);
    emit         lyricsChanged();

    const qint64 posMs = currentPositionMs();
    seekTo(posMs);
    if (mPlaying)
        scheduleNext();

    return foundWordTs;
}

void LyricsProvider::parsePlain(const QString& plain) {
    QVariantList newLines;
    QVariantList newWordLines;
    for (const QString& raw : plain.split('\n')) {
        const QString text = raw.trimmed();
        if (text.isEmpty())
            continue;

        const qsizetype caretIdx  = text.indexOf('^');
        const QString   srcText   = (caretIdx >= 0) ? text.left(caretIdx).trimmed() : text;
        const QString   transText = (caretIdx >= 0) ? text.mid(caretIdx + 1).trimmed() : QString();

        QVariantMap     lineEntry;
        lineEntry["time"]        = -1;
        lineEntry["text"]        = srcText;
        lineEntry["translation"] = transText;
        newLines.append(lineEntry);

        QVariantList words;
        for (const QString& word : srcText.split(' ', Qt::SkipEmptyParts)) {
            QVariantMap w;
            w["time"]     = -1;
            w["text"]     = word;
            w["duration"] = 0;
            words.append(w);
        }
        QVariantMap wlEntry;
        wlEntry["time"]  = -1;
        wlEntry["words"] = words;
        newWordLines.append(wlEntry);
    }

    mLines      = newLines;
    mWordLines  = newWordLines;
    mSynced     = false;
    mWordSynced = false;
    rebuildBoundaries();
    setState(State::Ready);
    emit lyricsChanged();
}

QVariantList LyricsProvider::interpolateWords(const QString& text, qint64 lineStartMs, qint64 lineEndMs) {
    const QStringList tokens = text.split(' ', Qt::SkipEmptyParts);
    if (tokens.isEmpty())
        return {};

    qint64 totalLen = 0;
    for (const QString& t : tokens) {
        totalLen += t.length();
    }

    qint64       durationGap = lineEndMs - lineStartMs;
    const qint64 maxDuration = tokens.size() * 800;
    durationGap              = std::min(durationGap, maxDuration);

    const auto   totalWeight = static_cast<double>(totalLen + tokens.size());

    QVariantList words;
    qint64       currentMs = lineStartMs;
    for (int i = 0; i < tokens.size(); ++i) {
        const double fraction  = static_cast<double>(tokens[i].length() + 1) / totalWeight;
        const auto   wDuration = static_cast<qint64>(static_cast<double>(durationGap) * fraction);

        QVariantMap  w;
        w["time"]     = currentMs;
        w["text"]     = tokens[i];
        w["duration"] = wDuration;
        words.append(w);
        currentMs += wDuration;
    }
    return words;
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
        parseLrc(lrc, 0);
        return true;
    }
    const QString plain = json["plainLyrics"].toString();
    if (!plain.isEmpty()) {
        parsePlain(plain);
        return true;
    }
    return false;
}

void LyricsProvider::saveToCache(const QString& key, const QByteArray& data) {
    QFile f(cachePath(key));
    if (f.open(QIODevice::WriteOnly))
        f.write(data);
}
