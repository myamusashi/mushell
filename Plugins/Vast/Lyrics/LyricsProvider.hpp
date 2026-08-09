#pragma once

#include <cstdint>
#include <qcontainerfwd.h>
#include <qhashfunctions.h>
#include <qlist.h>
#include <qnetworkaccessmanager.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtimer.h>
#include <qtmetamacros.h>
#include <qtypes.h>

#include "LrcParser.hpp"
#include "LyricsCache.hpp"
#include "LyricsScheduler.hpp"

class LyricsProvider : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(QVariantList lines READ lines NOTIFY lyricsChanged)
    Q_PROPERTY(QVariantList wordLines READ wordLines NOTIFY lyricsChanged)
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(bool synced READ synced NOTIFY lyricsChanged)
    Q_PROPERTY(bool wordSynced READ wordSynced NOTIFY lyricsChanged)
    Q_PROPERTY(int offsetMs READ offsetMs WRITE setOffsetMs NOTIFY offsetMsChanged)

    Q_PROPERTY(int currentLineIndex READ currentLineIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(int currentWordIndex READ currentWordIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(qint64 currentWordDuration READ currentWordDuration NOTIFY currentWordDurationChanged)

  public:
    enum class State : uint8_t {
        Idle,
        Loading,
        Ready,
        NotFound,
        Error
    };
    Q_ENUM(State)

    explicit LyricsProvider(QObject* parent = nullptr);

    [[nodiscard]] State state() const {
        return mState;
    }
    [[nodiscard]] bool synced() const {
        return mSynced;
    }
    [[nodiscard]] bool wordSynced() const {
        return mWordSynced;
    }
    [[nodiscard]] QVariantList lines() const {
        return mLines;
    }
    [[nodiscard]] QVariantList wordLines() const {
        return mWordLines;
    }
    [[nodiscard]] int currentLineIndex() const {
        return mScheduler->currentLineIndex();
    }
    [[nodiscard]] int currentWordIndex() const {
        return mScheduler->currentWordIndex();
    }
    [[nodiscard]] qint64 currentWordDuration() const {
        return mScheduler->currentWordDuration();
    }
    [[nodiscard]] int offsetMs() const {
        return mScheduler->offsetMs();
    }
    void setOffsetMs(int offset);

    // Call this from QML whenever position/playback state changes.
    // positionSecs: current track position in seconds
    // rate:         playback rate (normally 1.0)
    // playing:      true if MprisPlaybackState.Playing
    Q_INVOKABLE void setPlayback(double positionSecs, double rate, bool playing);
    Q_INVOKABLE void fetch(const QString& title, const QString& artist, double durationSecs);
    Q_INVOKABLE void clear();

  signals:
    void stateChanged();
    void lyricsChanged();
    void currentIndexChanged();
    void currentWordDurationChanged();
    void offsetMsChanged();

  private:
    void                   setState(State s);
    void                   applyParseResult(const vast::LrcParser::Result& result);
    [[nodiscard]] bool     tryLoadFromCache(const QString& cacheKey);

    QNetworkAccessManager* mNam;
    vast::LyricsScheduler* mScheduler;

    // Lyrics data
    QVariantList mLines;
    QVariantList mWordLines;
    State        mState      = State::Idle;
    bool         mSynced     = false;
    bool         mWordSynced = false;
};
