#pragma once

#include <qlist.h>
#include <qobject.h>
#include <qtimer.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

namespace vast {

    /// Owns dead-reckoning playback-position estimation and O(1) word-boundary
    /// scheduling for synced lyrics. Independent of network/parsing/caching —
    /// only needs the parsed wordLines list (for per-word duration lookups)
    /// and playback updates from the host (position/rate/playing + offset).
    class LyricsScheduler : public QObject {
        Q_OBJECT

      public:
        explicit LyricsScheduler(QObject* parent = nullptr);

        /// Rebuild the boundary list from a freshly-parsed wordLines list.
        /// Call this whenever lyrics change (new fetch, cache load, clear).
        void setWordLines(const QVariantList& wordLines);

        /// Call on every playback position/rate/state update from the host.
        void              setPlayback(double positionSecs, double rate, bool playing);

        void              setOffsetMs(int offset);
        [[nodiscard]] int offsetMs() const noexcept {
            return mOffsetMs;
        }

        void              reset();

        [[nodiscard]] int currentLineIndex() const noexcept {
            return mCurLine;
        }
        [[nodiscard]] int currentWordIndex() const noexcept {
            return mCurWord;
        }
        [[nodiscard]] qint64 currentWordDuration() const noexcept {
            return mCurWordDuration;
        }

      signals:
        void currentIndexChanged();
        void currentWordDurationChanged();

      private:
        struct WordBoundary {
            qint64 timeMs;
            int    lineIndex;
            int    wordIndex;
        };

        [[nodiscard]] qint64 currentPositionMs() const;
        void                 seekTo(qint64 posMs);
        void                 scheduleNext();
        void                 onWordTimer();
        void                 rebuildBoundaries();
        void                 reschedule(); // stop timer, seek, schedule — shared by setPlayback/setOffsetMs

        QVariantList         mWordLines; // kept only for per-word duration lookups in seekTo/onWordTimer

        QList<WordBoundary>  mBoundaries;
        qsizetype            mBoundaryPos{0};

        int                  mCurLine{-1};
        int                  mCurWord{-1};
        qint64               mCurWordDuration{0};
        int                  mOffsetMs{150};

        qint64               mAnchorMs{0};
        qint64               mAnchorWall{0};
        double               mRate{1.0};
        bool                 mPlaying{false};

        QTimer               mWordTimer;
    };
}