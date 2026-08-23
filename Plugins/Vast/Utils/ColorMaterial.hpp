#pragma once

#include <qcolor.h>
#include <cstdint>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtimer.h>
#include <qurl.h>
#include <qvariant.h>

class ColorMaterial : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QUrl source READ source WRITE setSource NOTIFY sourceChanged)
    Q_PROPERTY(int rescaleSize READ rescaleSize WRITE setRescaleSize NOTIFY rescaleSizeChanged)
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)
    Q_PROPERTY(Scheme scheme READ scheme WRITE setScheme NOTIFY schemeChanged)
    Q_PROPERTY(double contrastLevel READ contrastLevel WRITE setContrastLevel NOTIFY contrastLevelChanged)
    Q_PROPERTY(bool smart READ smart WRITE setSmart NOTIFY smartChanged)

    Q_PROPERTY(QVariantMap colors READ colors NOTIFY colorsChanged)
    Q_PROPERTY(QColor sourceColor READ sourceColor NOTIFY sourceColorChanged)
    Q_PROPERTY(bool ready READ ready NOTIFY readyChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

  public:
    enum Scheme : std::uint8_t {
        TonalSpot,
        Vibrant,
        Expressive,
        FruitSalad,
        Monochrome,
        Rainbow,
        Fidelity,
        Content,
        Neutral
    };
    Q_ENUM(Scheme)

    explicit ColorMaterial(QObject* parent = nullptr);

    [[nodiscard]] QUrl        source() const;
    void                      setSource(const QUrl& source);

    [[nodiscard]] int         rescaleSize() const;
    void                      setRescaleSize(int rescaleSize);

    [[nodiscard]] bool        darkMode() const;
    void                      setDarkMode(bool darkMode);

    [[nodiscard]] Scheme      scheme() const;
    void                      setScheme(Scheme scheme);

    [[nodiscard]] double      contrastLevel() const;
    void                      setContrastLevel(double contrastLevel);

    [[nodiscard]] bool        smart() const;
    void                      setSmart(bool smart);

    [[nodiscard]] QVariantMap colors() const;
    [[nodiscard]] QColor      sourceColor() const;
    [[nodiscard]] bool        ready() const;
    [[nodiscard]] QString     error() const;

  signals:
    void sourceChanged();
    void rescaleSizeChanged();
    void darkModeChanged();
    void schemeChanged();
    void contrastLevelChanged();
    void smartChanged();
    void colorsChanged();
    void sourceColorChanged();
    void readyChanged();
    void errorChanged();

  private:
    void          scheduleRebuild();
    void          rebuild();
    void          applyResult(const QVariantMap& colors, const QColor& sourceColor, const QString& error);

    QUrl          mSource;
    int           mRescaleSize   = 128;
    bool          mDarkMode      = true;
    Scheme        mScheme        = TonalSpot;
    double        mContrastLevel = 0.0;
    bool          mSmart         = false;

    QTimer        mDebounce;
    std::uint64_t mGeneration = 0;

    QVariantMap   mColors;
    QColor        mSourceColor;
    bool          mReady = false;
    QString       mError;
};
