#pragma once

#include <qnetworkaccessmanager.h>
#include <qobject.h>
#include <qtimer.h>
#include <qvariantlist.h>
#include <QtQml/qqmlregistration.h>

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
    enum class State {
        Idle,
        Loading,
        Ready,
        NotFound,
        Error
    };
    Q_ENUM(State)

    explicit LyricsProvider(QObject* parent = nullptr);

    [[nodiscard]] State state() const {
        return m_state;
    }
    [[nodiscard]] bool synced() const {
        return m_synced;
    }
    [[nodiscard]] bool wordSynced() const {
        return m_wordSynced;
    }
    [[nodiscard]] QVariantList lines() const {
        return m_lines;
    }
    [[nodiscard]] QVariantList wordLines() const {
        return m_wordLines;
    }
    [[nodiscard]] int currentLineIndex() const {
        return m_curLine;
    }
    [[nodiscard]] int currentWordIndex() const {
        return m_curWord;
    }
    [[nodiscard]] qint64 currentWordDuration() const {
        return m_curWordDuration;
    }
    [[nodiscard]] int offsetMs() const {
        return m_offsetMs;
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
    void                         saveToCache(const QString& key, const QByteArray& data);

    QNetworkAccessManager*       m_nam;

    // Lyrics data
    QVariantList m_lines;
    QVariantList m_wordLines;
    State        m_state      = State::Idle;
    bool         m_synced     = false;
    bool         m_wordSynced = false;

    // Flat sorted list of every word boundary for O(1) scheduling
    struct WordBoundary {
        qint64 timeMs;
        int    lineIndex;
        int    wordIndex;
    };
    QList<WordBoundary> m_boundaries;
    qsizetype           m_boundaryPos = 0;

    // Current playback state
    int    m_curLine         = -1;
    int    m_curWord         = -1;
    qint64 m_curWordDuration = 0;
    int    m_offsetMs        = 150;

    // Dead-reckoning anchors
    qint64 m_anchorMs   = 0;
    qint64 m_anchorWall = 0; // QDateTime::currentMSecsSinceEpoch() at last setPlayback()
    double m_rate       = 1.0;
    bool   m_playing    = false;

    QTimer m_wordTimer;
};
