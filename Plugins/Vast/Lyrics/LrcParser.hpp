#pragma once

#include <qlist.h>
#include <qstring.h>
#include <qvariant.h>
#include <qtypes.h>

namespace vast {

    /// Parses LRC-format (line- and optionally word-synced) or plain-text
    /// lyrics into the QVariantList shape LyricsProvider exposes to QML.
    /// Pure — no network, no disk, no playback state.
    class LrcParser {
      public:
        struct Result {
            QVariantList lines;
            QVariantList wordLines;
            bool         synced{false};
            bool         wordSynced{false};
        };

        /// Parses LRC-format text (with [mm:ss.xx] line tags and optional
        /// <mm:ss.xx> word tags). totalDurationSecs is used as a fallback
        /// end-time for the final line if it can't be inferred from spacing.
        [[nodiscard]] static Result parseLrc(const QString& lrc, double totalDurationSecs);

        /// Parses plain (unsynced) lyrics — one line per row, no timestamps.
        [[nodiscard]] static Result parsePlain(const QString& plain);

      private:
        [[nodiscard]] static qint64       parseTimestamp(const QString& mm, const QString& ss, const QString& frac);
        [[nodiscard]] static QVariantList interpolateWords(const QString& text, qint64 lineStartMs, qint64 lineEndMs);
    };
}