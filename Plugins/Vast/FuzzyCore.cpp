#include "FuzzyCore.hpp"

#include <qassert.h>
#include <qbytearray.h>

#include <qtypes.h>
#include <cstddef>
#include <vector>

#include "match.h"

namespace vast::fzy {

    static_assert(K_MATCH_MAX_LEN == MATCH_MAX_LEN);

    namespace {

        constexpr double K_SENTINEL_FLOOR = 2.0 * K_MATCH_MAX_LEN;

        bool             isUtf8Continuation(char byte) {
            return (static_cast<unsigned char>(byte) & 0xC0) == 0x80;
        }

        std::vector<int> byteToCharMap(const QByteArray& utf8) {
            std::vector<int> map(static_cast<size_t>(utf8.size()) + 1, 0);
            int              charIndex = 0;
            qsizetype        byte      = 0;
            while (byte < utf8.size()) {
                map[static_cast<size_t>(byte)] = charIndex;
                do {
                    ++byte;
                } while (byte < utf8.size() && isUtf8Continuation(utf8.at(byte)));
                ++charIndex;
            }
            map[static_cast<size_t>(utf8.size())] = charIndex;
            return map;
        }

        double clampScore(double raw, qsizetype needleLength) {
            if (raw > K_SENTINEL_FLOOR)
                return 2.0 * static_cast<double>(needleLength);
            if (raw < -K_SENTINEL_FLOOR)
                return -K_SENTINEL_FLOOR;
            return raw;
        }

    }

    bool hasMatch(const QString& needle, const QString& haystack) {
        if (needle.isEmpty())
            return false;

        const QByteArray needleUtf8   = needle.toUtf8();
        const QByteArray haystackUtf8 = haystack.toUtf8();

        return ::has_match(needleUtf8.constData(), haystackUtf8.constData()) != 0;
    }

    double score(const QString& needle, const QString& haystack) {
        Q_ASSERT(hasMatch(needle, haystack));

        const QByteArray needleUtf8   = needle.toUtf8();
        const QByteArray haystackUtf8 = haystack.toUtf8();

        return clampScore(::match(needleUtf8.constData(), haystackUtf8.constData()), needle.length());
    }

    namespace {

        // Shared gate+DP core: both strings are encoded exactly once by the
        // caller and reused across the gate and the scoring pass.
        ScoreOutcome coreScore(const QByteArray& needleUtf8, qsizetype needleCharCount, const QByteArray& haystackUtf8) {
            if (needleUtf8.isEmpty())
                return {.matched = false, .score = 0.0};

            if (::has_match(needleUtf8.constData(), haystackUtf8.constData()) == 0)
                return {.matched = false, .score = 0.0};

            return {.matched = true, .score = clampScore(::match(needleUtf8.constData(), haystackUtf8.constData()), needleCharCount)};
        }

        MatchResult corePositions(const QByteArray& needleUtf8, qsizetype needleCharCount, const QByteArray& haystackUtf8) {
            MatchResult     result{.matched = false, .score = 0.0, .positions = {}};

            const qsizetype needleBytes = needleUtf8.size();
            if (needleBytes == 0 || haystackUtf8.size() > K_MATCH_MAX_LEN || needleBytes > haystackUtf8.size())
                return result;

            if (::has_match(needleUtf8.constData(), haystackUtf8.constData()) == 0)
                return result;

            std::vector<std::size_t> bytePositions(static_cast<size_t>(needleBytes), 0);
            const score_t            raw = ::match_positions(needleUtf8.constData(), haystackUtf8.constData(), bytePositions.data());
            result.matched               = true;
            result.score                 = clampScore(raw, needleCharCount);

            const std::vector<int> haystackMap = byteToCharMap(haystackUtf8);
            for (qsizetype i = 0; i < needleBytes; ++i) {
                if (!isUtf8Continuation(needleUtf8.at(i)))
                    result.positions.push_back(haystackMap[static_cast<std::size_t>(bytePositions[static_cast<size_t>(i)])]);
            }

            return result;
        }

    }

    ScoreOutcome scoredMatch(const QString& needle, const QString& haystack) {
        const QByteArray needleUtf8 = needle.toUtf8();
        return coreScore(needleUtf8, needle.length(), haystack.toUtf8());
    }

    MatchResult matchPositions(const QString& needle, const QString& haystack) {
        const QByteArray needleUtf8 = needle.toUtf8();
        return corePositions(needleUtf8, needle.length(), haystack.toUtf8());
    }

    ScoreOutcome scoredMatchUtf8(const QByteArray& needle, qsizetype needleCharCount, const QByteArray& haystack) {
        return coreScore(needle, needleCharCount, haystack);
    }

    MatchResult matchPositionsUtf8(const QByteArray& needle, qsizetype needleCharCount, const QByteArray& haystack) {
        return corePositions(needle, needleCharCount, haystack);
    }

}
