#include "FuzzyMatcher.hpp"

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

// returns [{start, length}, …] covering every match of query inside text
QVariantList FuzzyMatcher::highlightRanges(const QString& text, const QString& query) {
    QVariantList ranges;
    if (query.trimmed().isEmpty())
        return ranges;

    const QString normQuery = normalizeText(query).trimmed();
    if (normQuery.isEmpty())
        return ranges;

    const QString normText = normalizeText(text);

    qsizetype     pos = 0;
    while ((pos = normText.indexOf(normQuery, pos)) != -1) {
        QVariantMap range;
        range["start"]  = pos;
        range["length"] = normQuery.length();
        ranges.append(range);
        pos += normQuery.length();
    }
    return ranges;
}

QString FuzzyMatcher::highlightedHtml(const QString& text, const QString& query, const QString& color) {
    if (query.trimmed().isEmpty())
        return escapeHtml(text);

    const QString normQuery = normalizeText(query).trimmed();
    if (normQuery.isEmpty())
        return escapeHtml(text);

    const QString normText = normalizeText(text);

    QString       result;
    qsizetype     last = 0;
    qsizetype     idx  = normText.indexOf(normQuery);

    while (idx != -1) {
        if (idx > last)
            result += escapeHtml(text.mid(last, idx - last));

        result += QStringLiteral("<span style=\"color:%1;font-weight:600;\">").arg(color);
        result += escapeHtml(text.mid(idx, normQuery.length()));
        result += QStringLiteral("</span>");

        last = idx + normQuery.length();
        idx  = normText.indexOf(normQuery, last);
    }

    if (last < text.length())
        result += escapeHtml(text.mid(last));

    return result;
}

bool FuzzyMatcher::isSubsequence(const QString& q, const QString& t) {
    int qi = 0;
    for (int i = 0; i < t.length() && qi < q.length(); ++i)
        if (t[i] == q[qi])
            ++qi;
    return qi == q.length();
}

double FuzzyMatcher::subsequenceScore(const QString& q, const QString& t) {
    if (q.isEmpty())
        return 1.0;

    int    qi          = 0;
    int    consecutive = 0;
    double bonus       = 0.0;

    for (int i = 0; i < t.length() && qi < q.length(); ++i) {
        if (t[i] == q[qi]) {
            ++consecutive;
            bonus += consecutive * (i == 0 || t[i - 1] == ' ' ? 2.0 : 1.0);
            ++qi;
        } else {
            consecutive = 0;
        }
    }
    if (qi < q.length())
        return 0.0;

    const auto maxBonus = static_cast<double>(q.length() * (q.length() + 1));
    return std::min(bonus / maxBonus, 1.0);
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

double FuzzyMatcher::prefixScore(const QString& q, const QString& t, const QStringList& tWords) {
    if (t.startsWith(q))
        return (q.length() == t.length()) ? 1.0 : 0.95;

    if (std::ranges::any_of(tWords, [&](const QString& w) { return w.startsWith(q); }))
        return 0.85;

    return 0.0;
}

double FuzzyMatcher::wordBoundaryScore(const QString& q, const QStringList& tWords) {
    const auto qlen = static_cast<double>(q.length());
    double     best = 0.0;

    for (const QString& word : tWords)
        if (word.contains(q))
            best = std::max(best, qlen / static_cast<double>(word.length()));

    return best;
}

double FuzzyMatcher::acronymScore(const QString& q, const QStringList& tWords) {
    if (tWords.size() < 2 || q.isEmpty())
        return 0.0;

    QString acronym;
    for (const QString& w : tWords)
        if (!w.isEmpty())
            acronym += w[0];

    if (acronym == q)
        return 1.0;
    if (acronym.startsWith(q))
        return 0.9;
    if (acronym.contains(q))
        return 0.75;
    if (isSubsequence(q, acronym))
        return 0.6;
    return 0.0;
}

double FuzzyMatcher::getScore(const QString& q, const QString& t, const QStringList& tWords) {
    if (t == q)
        return 1.0;
    if (t.contains(q))
        return 0.95;

    // Acronym path ("vsc" → "Visual Studio Code")
    const double acro = acronymScore(q, tWords);
    if (acro > 0.0)
        return acro * K_ACRONYM_WEIGHT + prefixScore(q, t, tWords) * K_PREFIX_WEIGHT + wordBoundaryScore(q, tWords) * K_WORD_BOUNDARY_WEIGHT;

    const double lenRatio = static_cast<double>(std::min(q.length(), t.length())) / static_cast<double>(std::max(q.length(), t.length()));
    if (lenRatio < 0.3 && !isSubsequence(q, t))
        return 0.0;

    return distanceScore(q, t) * K_DISTANCE_WEIGHT + prefixScore(q, t, tWords) * K_PREFIX_WEIGHT + subsequenceScore(q, t) * K_CONSECUTIVE_WEIGHT +
        wordBoundaryScore(q, tWords) * K_WORD_BOUNDARY_WEIGHT;
}

double FuzzyMatcher::getMultiWordScore(const QStringList& qWords, const QString& t, const QStringList& tWords) {
    if (qWords.size() == 1)
        return getScore(qWords[0], t, tWords);

    double    total   = 0.0;
    qsizetype matched = 0;

    for (const QString& qw : qWords) {
        const double s = getScore(qw, t, tWords);
        if (s > 0.0) {
            total += s;
            ++matched;
        }
    }
    // all query words must contribute
    if (matched < qWords.size())
        return 0.0;

    return total / static_cast<double>(qWords.size());
}

double FuzzyMatcher::multiFieldScore(const QStringList& queryWords, const QString& normQuery, const QString& primaryField, const QString& secondaryField,
                                     const QString& tertiaryField, double secondaryWeight, double tertiaryWeight) {
    static const QRegularExpression kWhitespace(R"(\s+)");

    const QStringList primaryWords = primaryField.split(kWhitespace, Qt::SkipEmptyParts);

    double primaryScore = 0.0;
    if (primaryField == normQuery)
        primaryScore = 1.0;
    else if (primaryField.contains(normQuery))
        primaryScore = 0.95;
    else
        primaryScore = getMultiWordScore(queryWords, primaryField, primaryWords);

    if (primaryScore >= 0.9)
        return primaryScore;

    double secondaryScore = 0.0;
    if (!secondaryField.isEmpty()) {
        const QStringList words = secondaryField.split(kWhitespace, Qt::SkipEmptyParts);
        secondaryScore          = getMultiWordScore(queryWords, secondaryField, words) * secondaryWeight;
    }

    double tertiaryScore = 0.0;
    if (!tertiaryField.isEmpty()) {
        const QStringList words = tertiaryField.split(kWhitespace, Qt::SkipEmptyParts);
        tertiaryScore           = getMultiWordScore(queryWords, tertiaryField, words) * tertiaryWeight;
    }

    return std::max({primaryScore, secondaryScore, tertiaryScore});
}

double FuzzyMatcher::fuzzyScore(const QString& query, const QString& text) {
    static const QRegularExpression kWhitespace(R"(\s+)");

    if (query.isEmpty())
        return 0.0;

    const QString normQuery = normalizeText(query).trimmed();
    if (normQuery.isEmpty())
        return 0.0;

    const QString normText = normalizeText(text);
    if (normText == normQuery)
        return 1.0;
    if (normText.contains(normQuery))
        return 0.95;

    const QStringList tWords     = normText.split(kWhitespace, Qt::SkipEmptyParts);
    const QStringList queryWords = normQuery.split(kWhitespace, Qt::SkipEmptyParts);

    return getMultiWordScore(queryWords, normText, tWords);
}
