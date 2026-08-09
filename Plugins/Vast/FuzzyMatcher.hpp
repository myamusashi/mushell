#pragma once

#include <qchar.h>
#include <qcontainerfwd.h>
#include <qhash.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtypes.h>

namespace vast {

class FuzzyMatcher {
  public:
    static constexpr double           K_PREFIX_WEIGHT        = 0.30;
    static constexpr double           K_DISTANCE_WEIGHT      = 0.20;
    static constexpr double           K_CONSECUTIVE_WEIGHT   = 0.15;
    static constexpr double           K_WORD_BOUNDARY_WEIGHT = 0.10;
    static constexpr double           K_ACRONYM_WEIGHT       = 0.25;
    static constexpr double           K_RECENCY_WEIGHT       = 0.40;

    [[nodiscard]] static QChar        normalizeChar(QChar c);
    [[nodiscard]] static QString      normalizeText(const QString& text);
    [[nodiscard]] static QVariantList highlightRanges(const QString& text, const QString& query);
    [[nodiscard]] static QString      highlightedHtml(const QString& text, const QString& query, const QString& color);
    [[nodiscard]] static QString      escapeHtml(const QString& text);
    [[nodiscard]] static double       getScore(const QString& q, const QString& t, const QStringList& tWords);
    [[nodiscard]] static double       getMultiWordScore(const QStringList& qWords, const QString& t, const QStringList& tWords);
    [[nodiscard]] static double       multiFieldScore(const QStringList& queryWords, const QString& normQuery, const QString& primaryField,
                                                      const QString& secondaryField = {}, const QString& tertiaryField = {}, double secondaryWeight = 0.7,
                                                      double tertiaryWeight = 0.5);
    [[nodiscard]] static double       fuzzyScore(const QString& query, const QString& text);

  private:
    [[nodiscard]] static bool                       isSubsequence(const QString& q, const QString& t);
    [[nodiscard]] static double                     subsequenceScore(const QString& q, const QString& t);
    [[nodiscard]] static qsizetype                  levenshteinDistance(const QString& a, const QString& b);
    [[nodiscard]] static double                     distanceScore(const QString& a, const QString& b);
    [[nodiscard]] static double                     prefixScore(const QString& q, const QString& t, const QStringList& tWords);
    [[nodiscard]] static double                     wordBoundaryScore(const QString& q, const QStringList& tWords);
    [[nodiscard]] static double                     acronymScore(const QString& q, const QStringList& tWords);

    [[nodiscard]] static const QHash<QChar, QChar>& charLookup();
};
}
