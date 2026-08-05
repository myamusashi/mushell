#pragma once

#include <qobject.h>
#include <qqmlengine.h>
#include <qstring.h>
#include <qvariantlist.h>
#include <qvariantmap.h>

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
        m_type = v;
    }
    void setTitle(const QString& v) {
        m_title = v;
    }
    void setSubtitle(const QString& v) {
        m_subtitle = v;
    }
    void setIcon(const QString& v) {
        m_icon = v;
    }
    void setScore(double v) {
        m_score = v;
    }
    void setData(const QVariantMap& v) {
        m_data = v;
    }
    void setHighlightRanges(const QVariantList& v) {
        m_highlightRanges = v;
    }

    static SearchResult*  makeFile(const QString& title, const QString& subtitle, const QString& icon, double score, const QVariantMap& data, const QVariantList& ranges,
                                   QObject* parent = nullptr);

    [[nodiscard]] QString type() const {
        return m_type;
    }
    [[nodiscard]] QString title() const {
        return m_title;
    }
    [[nodiscard]] QString subtitle() const {
        return m_subtitle;
    }
    [[nodiscard]] QString icon() const {
        return m_icon;
    }
    [[nodiscard]] double score() const {
        return m_score;
    }
    [[nodiscard]] QVariantMap data() const {
        return m_data;
    }
    [[nodiscard]] QVariantList highlightRanges() const {
        return m_highlightRanges;
    }

    [[nodiscard]] Q_INVOKABLE QString highlightedTitle(const QString& color) const;

  private:
    QString      m_type;
    QString      m_title;
    QString      m_subtitle;
    QString      m_icon;
    double       m_score = 0.0;
    QVariantMap  m_data;
    QVariantList m_highlightRanges;
};
