#pragma once

#include <qbytearray.h>
#include <qstring.h>
#include <optional>

namespace vast {

    /// Disk-backed cache of raw lyrics API responses, keyed by a hash of
    /// title+artist+duration. Stores/returns raw JSON bytes only — parsing
    /// is the caller's responsibility (see LrcParser).
    class LyricsCache {
      public:
        [[nodiscard]] static QString key(const QString& title, const QString& artist, double durationSecs);

        /// Returns the cached raw JSON bytes for `cacheKey`, or nullopt if absent.
        [[nodiscard]] static std::optional<QByteArray> load(const QString& cacheKey);

        /// Persists raw JSON bytes for `cacheKey`.
        static void save(const QString& cacheKey, const QByteArray& data);

      private:
        [[nodiscard]] static QString path(const QString& cacheKey);
    };
}