#pragma once

#include <qbytearray.h>
#include <qjsondocument.h>
#include <qstring.h>
#include <optional>

namespace vast {

    /// Disk-backed cache of raw lyrics API responses, keyed by a hash of
    /// title+artist+duration. Stores/returns raw JSON bytes only — parsing
    /// is the caller's responsibility (see LrcParser).
    class LyricsCache {
      public:
        struct CachedLyrics {
            QByteArray rawJson;
            double     durationSecs{0};
        };

        [[nodiscard]] static QString key(const QString& title, const QString& artist, double durationSecs);

        /// Returns the cached payload for `cacheKey`, or nullopt if absent.
        /// Old-format (raw API passthrough) files fail envelope parsing and
        /// surface as a miss — they self-heal by re-fetching in the new format.
        [[nodiscard]] static std::optional<CachedLyrics> load(const QString& cacheKey);

        /// Persists `rawJson` alongside the track duration the fetch used.
        static void save(const QString& cacheKey, const QByteArray& rawJson, double durationSecs);

      private:
        [[nodiscard]] static QString path(const QString& cacheKey);
    };
}