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
        return mCurLine;
    }
    [[nodiscard]] int currentWordIndex() const {
        return mCurWord;
    }
    [[nodiscard]] qint64 currentWordDuration() const {
        return mCurWordDuration;
    }
    [[nodiscard]] int offsetMs() const {
        return mOffsetMs;
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
    // Dead-reckoning: returns current estimated position in ms
    [[nodiscard]] qint64 currentPositionMs() const;

    // Seek m_boundaryPos to the correct entry for posMs, update m_curLine/m_curWord
    void seekTo(qint64 posMs);

    // Schedule singleShot for the next word boundary after posMs
    void scheduleNext();

    // Fired by m_wordTimer
    void                         onWordTimer();

    void                         setState(State s);
    bool                         parseLrc(const QString& lrc, double totalDurationSecs);
    void                         parsePlain(const QString& plain);
    void                         rebuildBoundaries();

    static qint64                parseTimestamp(const QString& mm, const QString& ss, const QString& frac);
    static QVariantList          interpolateWords(const QString& text, qint64 lineStartMs, qint64 lineEndMs);

    [[nodiscard]] static QString cacheKey(const QString& title, const QString& artist, double durationSecs);
    [[nodiscard]] static QString cachePath(const QString& key);
    [[nodiscard]] bool           loadFromCache(const QString& key);
    static void                  saveToCache(const QString& key, const QByteArray& data);

    QNetworkAccessManager*       mNam;

    // Lyrics data
    QVariantList mLines;
    QVariantList mWordLines;
    State        mState      = State::Idle;
    bool         mSynced     = false;
    bool         mWordSynced = false;

    // Flat sorted list of every word boundary for O(1) scheduling
    struct WordBoundary {
        qint64 timeMs;
        int    lineIndex;
        int    wordIndex;
    };
    QList<WordBoundary> mBoundaries;
    qsizetype           mBoundaryPos = 0;

    // Current playback state
    int    mCurLine         = -1;
    int    mCurWord         = -1;
    qint64 mCurWordDuration = 0;
    int    mOffsetMs        = 150;

    // Dead-reckoning anchors
    qint64 mAnchorMs   = 0;
    qint64 mAnchorWall = 0; // QDateTime::currentMSecsSinceEpoch() at last setPlayback()
    double mRate       = 1.0;
    bool   mPlaying    = false;

    QTimer mWordTimer;
};
