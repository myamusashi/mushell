#pragma once

#include <qcontainerfwd.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qtmetamacros.h>
#include <qmap.h>
#include <qlist.h>
#include <qvariant.h>

#include <utility>

namespace vast {

    class SearchResult : public QObject {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Created by SearchEngine")

        Q_PROPERTY(QString type READ type CONSTANT)
        Q_PROPERTY(QString title READ title CONSTANT)
        Q_PROPERTY(QString subtitle READ subtitle CONSTANT)
        Q_PROPERTY(QString icon READ icon CONSTANT)
        Q_PROPERTY(double score READ score CONSTANT)
        Q_PROPERTY(QVariantMap data READ data CONSTANT)
        Q_PROPERTY(QVariantList highlightRanges READ highlightRanges CONSTANT)

      public:
        [[nodiscard]] static SearchResult* makeFile(const QString& title, const QString& subtitle, const QString& icon, double score, const QVariantMap& data,
                                                    const QVariantList& ranges, QObject* parent = nullptr);

        [[nodiscard]] QString              type() const noexcept {
            return mType;
        }
        [[nodiscard]] QString title() const noexcept {
            return mTitle;
        }
        [[nodiscard]] QString subtitle() const noexcept {
            return mSubtitle;
        }
        [[nodiscard]] QString icon() const noexcept {
            return mIcon;
        }
        [[nodiscard]] double score() const noexcept {
            return mScore;
        }
        [[nodiscard]] QVariantMap data() const {
            return mData;
        }
        [[nodiscard]] QVariantList highlightRanges() const {
            return mHighlightRanges;
        }

        [[nodiscard]] Q_INVOKABLE QString highlightedTitle(const QString& color) const;

      private:
        explicit SearchResult(QString type, QString title, QString subtitle, QString icon, double score, QVariantMap data, QVariantList highlightRanges,
                              QObject* parent = nullptr) :
            QObject(parent), mType(std::move(type)), mTitle(std::move(title)), mSubtitle(std::move(subtitle)), mIcon(std::move(icon)), mScore(score), mData(std::move(data)),
            mHighlightRanges(std::move(highlightRanges)) {}

        const QString                 mType;            // NOLINT(readability-identifier-naming)
        const QString                 mTitle;           // NOLINT(readability-identifier-naming)
        const QString                 mSubtitle;        // NOLINT(readability-identifier-naming)
        const QString                 mIcon;            // NOLINT(readability-identifier-naming)
        const double                  mScore;           // NOLINT(readability-identifier-naming)
        const QMap<QString, QVariant> mData;            // NOLINT(readability-identifier-naming)
        const QList<QVariant>         mHighlightRanges; // NOLINT(readability-identifier-naming)
    };
}
