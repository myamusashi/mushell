#include "SearchResult.hpp"
#include "../FuzzyMatcher.hpp"
#include <qobject.h>
#include <qcontainerfwd.h>
#include <qvariant.h>

namespace vast {

SearchResult* SearchResult::makeFile(const QString& title, const QString& subtitle, const QString& icon, double score, const QVariantMap& data, const QVariantList& ranges,
                                     QObject* parent) {
    return new SearchResult(QStringLiteral("file"), title, subtitle, icon, score, data, ranges, parent);
}

QString SearchResult::highlightedTitle(const QString& color) const {
    if (mHighlightRanges.isEmpty())
        return FuzzyMatcher::escapeHtml(mTitle);

    QString result;
    int     last = 0;

    for (const QVariant& rv : mHighlightRanges) {
        const auto rm     = rv.toMap();
        const auto start  = rm.value("start").toInt();
        const auto length = rm.value("length").toInt();

        if (start > last)
            result += FuzzyMatcher::escapeHtml(mTitle.mid(last, start - last));

        result += QStringLiteral("<span style=\"color:%1;font-weight:600;\">").arg(color);
        result += FuzzyMatcher::escapeHtml(mTitle.mid(start, length));
        result += QStringLiteral("</span>");

        last = start + length;
    }

    if (last < mTitle.length())
        result += FuzzyMatcher::escapeHtml(mTitle.mid(last));

    return result;
}

}
