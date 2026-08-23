#pragma once

#include <qbytearray.h>
#include <qstring.h>
#include <qtypes.h>

#include <vector>

namespace vast::fzy {

    // Candidates longer than this are unscoreable for fzy; they still count
    // as matches but rank below any reasonably sized candidate.
    // Kept in sync with upstream MATCH_MAX_LEN (static_assert in the .cpp).
    inline constexpr int K_MATCH_MAX_LEN = 1024;

    // Cheap case-insensitive subsequence gate — call before score(); score()
    // is undefined otherwise (fzy's own contract). Empty needles never match.
    [[nodiscard]] bool hasMatch(const QString& needle, const QString& haystack);

    // Optimal-alignment fuzzy score on fzy's raw scale (~0..needleLength,
    // unbounded above by bonuses). Same-length matches return a finite
    // exact-match proxy of 2 * needleLength instead of fzy's SCORE_MAX
    // sentinel; unscoreable inputs return a large negative value instead of
    // SCORE_MIN (-infinity), so results are always safe to blend arithmetically.
    [[nodiscard]] double score(const QString& needle, const QString& haystack);

    struct ScoreOutcome {
        bool   matched = false;
        double score   = 0.0;
    };

    struct MatchResult {
        bool             matched = false;
        double           score   = 0.0;
        std::vector<int> positions;
    };

    // Combined gate + score: encodes both strings once and runs fzy's gate
    // before its DP on the same buffers. Hot-path API for callers that would
    // otherwise do hasMatch() + score() back to back on identical inputs.
    [[nodiscard]] ScoreOutcome scoredMatch(const QString& needle, const QString& haystack);

    // Same as scoredMatch(), plus the matched QChar indices into the haystack
    // (strictly ascending) recovered from fzy's optimal-alignment backtrace.
    // positions is empty when !matched.
    [[nodiscard]] MatchResult matchPositions(const QString& needle, const QString& haystack);

    // UTF-8 overloads for hot paths that cache encodings across keystrokes
    // (static app fields, walked file paths): the caller encodes each side
    // once and reuses the buffers. needleCharCount is the Unicode character
    // count of the needle; it scales the exact-match proxy.
    [[nodiscard]] ScoreOutcome scoredMatchUtf8(const QByteArray& needle, qsizetype needleCharCount, const QByteArray& haystack);
    [[nodiscard]] MatchResult  matchPositionsUtf8(const QByteArray& needle, qsizetype needleCharCount, const QByteArray& haystack);

}

// TODO(unicode): fzy operates on UTF-8 bytes and its tolower/isupper bonus
// logic is ASCII-only, so multi-byte codepoints only ever match byte-wise and
// earn no boundary bonuses. The diacritic-folding pre-pass in
// FuzzyMatcher::normalizeText collapses most non-ASCII Latin text before it
// reaches here; remaining scripts still subsequence-match correctly at the
// char level via the byte<->QChar offset mapping, just without bonuses.
