#pragma once

#include <qcontainerfwd.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qtmetamacros.h>
#include <qmap.h>
#include <qlist.h>
#include <qvariant.h>

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
    explicit SearchResult(QObject* parent = nullptr) : QObject(parent) {}

    void setType(const QString& v) {
        mType = v;
    }
    void setTitle(const QString& v) {
        mTitle = v;
    }
    void setSubtitle(const QString& v) {
        mSubtitle = v;
    }
    void setIcon(const QString& v) {
        mIcon = v;
    }
    void setScore(double v) {
        mScore = v;
    }
    void setData(const QVariantMap& v) {
        mData = v;
    }
    void setHighlightRanges(const QVariantList& v) {
        mHighlightRanges = v;
    }

    static SearchResult*  makeFile(const QString& title, const QString& subtitle, const QString& icon, double score, const QVariantMap& data, const QVariantList& ranges,
                                   QObject* parent = nullptr);

    [[nodiscard]] QString type() const {
        return mType;
    }
    [[nodiscard]] QString title() const {
        return mTitle;
    }
    [[nodiscard]] QString subtitle() const {
        return mSubtitle;
    }
    [[nodiscard]] QString icon() const {
        return mIcon;
    }
    [[nodiscard]] double score() const {
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
    QString                 mType;
    QString                 mTitle;
    QString                 mSubtitle;
    QString                 mIcon;
    double                  mScore = 0.0;
    QMap<QString, QVariant> mData;
    QList<QVariant>         mHighlightRanges;
};
