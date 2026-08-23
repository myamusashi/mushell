#include "FuzzyMatcher.hpp"
#include "FuzzyCore.hpp"

#include <qhash.h>
#include <array>
#include <iterator>
#include <qlatin1stringview.h>
#include <qcontainerfwd.h>
#include <qhashfunctions.h>
#include <cstddef>
#include <qnamespace.h>
#include <qregularexpression.h>
#include <algorithm>
#include <cmath>
#include <qtypes.h>
#include <utility>
#include <vector>

namespace vast {

    namespace {
        constexpr double K_DECISIVE_PER_CHAR = 1.0;
    }

    // char normalisation table
    const QHash<QChar, QChar>& FuzzyMatcher::charLookup() {
        static QHash<QChar, QChar> const map = []() {
            static constexpr std::array entries = {
                std::pair{'a', "aàáâãäåāăą4@"}, std::pair{'e', "eèéêëēėę3"}, std::pair{'i', "iìíîïīįı1!|l"}, std::pair{'o', "oòóôõöøōő0"},
                std::pair{'u', "uùúûüūůű"},     std::pair{'c', "cçćč"},      std::pair{'n', "nñńň"},         std::pair{'s', "sśšş5$"},
                std::pair{'z', "zźżž2"},        std::pair{'l', "l1!|i"},     std::pair{'g', "g9"},           std::pair{'t', "t7+"},
            };
            QHash<QChar, QChar> h;
            for (const auto& [key, chars] : entries) {
                const QString str = QString::fromUtf8(chars);
                const QChar   canon(key);
                for (QChar const c : str)
                    h.insert(c, canon);
            }
            return h;
        }();
        return map;
    }

    QChar FuzzyMatcher::normalizeChar(QChar c) {
        const QChar lower = c.toLower();
        return charLookup().value(lower, lower);
    }

    QString FuzzyMatcher::normalizeText(const QString& text) {
        QString out;
        out.reserve(text.size());
        std::ranges::transform(text, std::back_inserter(out), &FuzzyMatcher::normalizeChar);
        return out;
    }

    QString FuzzyMatcher::escapeHtml(const QString& text) {
        QString out;
        out.reserve(text.size() + text.size() / 10);
        for (QChar c : text)
            switch (c.unicode()) {
                case '&': out += QLatin1String("&amp;"); break;
                case '<': out += QLatin1String("&lt;"); break;
                case '>': out += QLatin1String("&gt;"); break;
                case '"': out += QLatin1String("&quot;"); break;
                case '\'': out += QLatin1String("&#039;"); break;
                default: out += c;
            }

        return out;
    }

    QString FuzzyMatcher::highlightedHtml(const QString& text, const QString& query, const QString& color) {
        if (query.trimmed().isEmpty())
            return escapeHtml(text);

        const QString normQuery = normalizeText(query).trimmed();
        if (normQuery.isEmpty())
            return escapeHtml(text);

        const QString normText = normalizeText(text);
        if (normText.length() > fzy::K_MATCH_MAX_LEN)
            return escapeHtml(text);

        // Single combined gate + DP + backtrace pass over one encoding pair.
        const fzy::MatchResult result = fzy::matchPositions(normQuery, normText);
        if (!result.matched)
            return escapeHtml(text);

        QString   out;
        qsizetype last = 0;

        for (size_t i = 0; i < result.positions.size();) {
            const int runStart = result.positions[i];
            int       runEnd   = runStart;
            ++i;
            while (i < result.positions.size() && result.positions[i] == runEnd + 1) {
                runEnd = result.positions[i];
                ++i;
            }

            const qsizetype start = runStart;
            if (start > last)
                out += escapeHtml(text.mid(last, start - last));

            out += QStringLiteral("<span style=\"color:%1;font-weight:600;\">").arg(color);
            out += escapeHtml(text.mid(start, runEnd - start + 1));
            out += QStringLiteral("</span>");

            last = runEnd + 1;
        }

        if (last < text.length())
            out += escapeHtml(text.mid(last));

        return out;
    }

    [[nodiscard]] qsizetype FuzzyMatcher::levenshteinDistance(const QString& a, const QString& b) {
        if (a.isEmpty())
            return b.length();
        if (b.isEmpty())
            return a.length();

        const QString&      shorter = a.length() <= b.length() ? a : b;
        const QString&      longer  = a.length() <= b.length() ? b : a;

        const qsizetype     shortLength  = shorter.length();
        const qsizetype     longerLength = longer.length();

        const auto          uShortLength  = static_cast<size_t>(shortLength);
        const auto          uLongerLength = static_cast<size_t>(longerLength);

        std::vector<size_t> prev(uShortLength + 1);
        std::vector<size_t> curr(uShortLength + 1);
        for (size_t i = 0; i <= uShortLength; ++i)
            prev[i] = i;

        for (size_t i = 1; i <= uLongerLength; ++i) {
            curr[0]       = i;
            size_t rowMin = curr[0];

            for (size_t j = 1; j <= uShortLength; ++j) {
                const size_t cost = (longer[static_cast<qsizetype>(i - 1)] == shorter[static_cast<qsizetype>(j - 1)]) ? 0 : 1;
                curr[j]           = std::min({prev[j] + 1, curr[j - 1] + 1, prev[j - 1] + cost});
                rowMin            = std::min(rowMin, curr[j]);
            }

            if (rowMin > uShortLength)
                return static_cast<qsizetype>(rowMin);

            std::swap(prev, curr);
        }
        return static_cast<qsizetype>(curr[uShortLength]);
    }

    double FuzzyMatcher::distanceScore(const QString& a, const QString& b) {
        const int maxLen = static_cast<int>(std::max(a.length(), b.length()));
        if (maxLen == 0)
            return 1.0;

        // skip Levenshtein when the length gap makes a good match impossible
        const int lenDiff = static_cast<int>(std::abs(a.length() - b.length()));
        if (static_cast<double>(lenDiff) / maxLen > 0.7)
            return 0.0;

        const qsizetype dist  = levenshteinDistance(a, b);
        const double    ratio = static_cast<double>(maxLen - dist) / maxLen;
        return std::pow(ratio, 1.5);
    }

    std::vector<FuzzyMatcher::EncodedWord> FuzzyMatcher::encodeWords(const QStringList& normalizedWords) {
        std::vector<EncodedWord> out;
        out.reserve(static_cast<size_t>(normalizedWords.size()));
        for (const QString& word : normalizedWords)
            out.push_back({.text = word, .utf8 = word.toUtf8(), .charCount = word.length()});
        return out;
    }

    FuzzyMatcher::CachedText FuzzyMatcher::cacheText(const QString& normalizedText) {
        return {.normalized = normalizedText, .utf8 = normalizedText.toUtf8()};
    }

    double FuzzyMatcher::multiWordScoreUtf8(const std::vector<EncodedWord>& words, const CachedText& field) {
        if (words.empty())
            return 0.0;

        double total = 0.0;
        for (const EncodedWord& word : words) {
            // One gate + DP pass over pre-encoded buffers; the edit-distance
            // fallback only runs when the subsequence path fails.
            const fzy::ScoreOutcome outcome = fzy::scoredMatchUtf8(word.utf8, word.charCount, field.utf8);
            if (outcome.matched)
                total += outcome.score;
            else
                total += distanceScore(word.text, field.normalized) * K_TYPO_FALLBACK_WEIGHT;
        }

        return total / static_cast<double>(words.size());
    }

    double FuzzyMatcher::multiFieldScoreUtf8(const std::vector<EncodedWord>& words, qsizetype queryChars, const CachedText& primaryField, const CachedText* secondaryField,
                                             const CachedText* tertiaryField, double secondaryWeight, double tertiaryWeight) {
        const double primaryScore = multiWordScoreUtf8(words, primaryField);

        double       best = primaryScore;
        if (primaryScore >= static_cast<double>(queryChars) * K_DECISIVE_PER_CHAR)
            return best;

        if (secondaryField)
            best = std::max(best, multiWordScoreUtf8(words, *secondaryField) * secondaryWeight);

        if (tertiaryField)
            best = std::max(best, multiWordScoreUtf8(words, *tertiaryField) * tertiaryWeight);

        return best;
    }

    double FuzzyMatcher::multiWordScore(const QStringList& queryWords, const QString& normalizedText) {
        return multiWordScoreUtf8(encodeWords(queryWords), cacheText(normalizedText));
    }

    double FuzzyMatcher::multiFieldScore(const QStringList& queryWords, const QString& normQuery, const QString& primaryField, const QString& secondaryField,
                                         const QString& tertiaryField, double secondaryWeight, double tertiaryWeight) {
        const std::vector<EncodedWord> words     = encodeWords(queryWords);
        const CachedText               primary   = cacheText(primaryField);
        const CachedText               secondary = cacheText(secondaryField);
        const CachedText               tertiary  = cacheText(tertiaryField);

        return multiFieldScoreUtf8(words, normQuery.length(), primary, secondaryField.isEmpty() ? nullptr : &secondary, tertiaryField.isEmpty() ? nullptr : &tertiary,
                                   secondaryWeight, tertiaryWeight);
    }

    double FuzzyMatcher::fuzzyScore(const QString& query, const QString& text) {
        static const QRegularExpression kWhitespace(R"(\s+)");

        if (query.isEmpty())
            return 0.0;

        const QString normQuery = normalizeText(query).trimmed();
        if (normQuery.isEmpty())
            return 0.0;

        const QStringList queryWords = normQuery.split(kWhitespace, Qt::SkipEmptyParts);

        return multiWordScore(queryWords, normalizeText(text));
    }

}
