#pragma once

#include <qbytearray.h>
#include <qchar.h>
#include <qcontainerfwd.h>
#include <qhash.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtypes.h>

#include <vector>

namespace vast {

    class FuzzyMatcher {
      public:
        // Multiplicative recency boost ceiling in SearchEngine::searchApps
        // (finalScore = base * (1 + recency * K_RECENCY_WEIGHT)), scale-free
        // against fzy's unbounded raw scores.
        static constexpr double K_RECENCY_WEIGHT = 0.40;

        // Multiplier for edit-distance scores on the typo-tolerance fallback,
        // which only runs when the fzy subsequence path fails; keeps typo
        // hits ranked below organic matches of comparable quality.
        static constexpr double K_TYPO_FALLBACK_WEIGHT = 0.5;

        // A query word encoded once per keystroke, reused across every
        // candidate field.
        struct EncodedWord {
            QString    text;
            QByteArray utf8;
            qsizetype  charCount = 0;
        };

        // A candidate field's normalized text plus its UTF-8 encoding,
        // cacheable across keystrokes for static data (app names, walked
        // paths). The normalized QString stays alive for the typo-fallback
        // edit-distance path.
        struct CachedText {
            QString    normalized;
            QByteArray utf8;
        };

        [[nodiscard]] static QChar   normalizeChar(QChar c);
        [[nodiscard]] static QString normalizeText(const QString& text);
        [[nodiscard]] static QString escapeHtml(const QString& text);
        [[nodiscard]] static QString highlightedHtml(const QString& text, const QString& query, const QString& color);

        [[nodiscard]] static double  fuzzyScore(const QString& query, const QString& text);
        [[nodiscard]] static double  multiWordScore(const QStringList& queryWords, const QString& normalizedText);
        [[nodiscard]] static double  multiFieldScore(const QStringList& queryWords, const QString& normQuery, const QString& primaryField, const QString& secondaryField = {},
                                                     const QString& tertiaryField = {}, double secondaryWeight = 0.7, double tertiaryWeight = 0.5);

        // Hot-path variants: query words and candidate fields are supplied
        // pre-encoded, so a keystroke encodes the query once and reuses
        // per-candidate encodings from cache instead of re-encoding per
        // word x field pair.
        [[nodiscard]] static std::vector<EncodedWord> encodeWords(const QStringList& normalizedWords);
        [[nodiscard]] static CachedText               cacheText(const QString& normalizedText);
        [[nodiscard]] static double                   multiWordScoreUtf8(const std::vector<EncodedWord>& words, const CachedText& field);
        [[nodiscard]] static double                   multiFieldScoreUtf8(const std::vector<EncodedWord>& words, qsizetype queryChars, const CachedText& primaryField,
                                                                          const CachedText* secondaryField = nullptr, const CachedText* tertiaryField = nullptr, double secondaryWeight = 0.7,
                                                                          double tertiaryWeight = 0.5);

      private:
        [[nodiscard]] static qsizetype                  levenshteinDistance(const QString& a, const QString& b);
        [[nodiscard]] static double                     distanceScore(const QString& a, const QString& b);

        [[nodiscard]] static const QHash<QChar, QChar>& charLookup();
    };
}
