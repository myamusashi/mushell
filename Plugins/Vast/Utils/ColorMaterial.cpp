#include "ColorMaterial.hpp"

#include <qcolor.h>
#include <qthreadpool.h>
#include <qstring.h>
#include <qurl.h>
#include <qvariant.h>
#include <qcontainerfwd.h>
#include <qnamespace.h>
#include <qlatin1stringview.h>
#include <qobject.h>
#include <algorithm>
#include <cmath>
#include <cstdint>

#include "PaletteBuilder.hpp"

namespace {

    QString schemeToString(ColorMaterial::Scheme scheme) {
        switch (scheme) {
            case ColorMaterial::Vibrant: return QStringLiteral("vibrant");
            case ColorMaterial::Expressive: return QStringLiteral("expressive");
            case ColorMaterial::FruitSalad: return QStringLiteral("fruit-salad");
            case ColorMaterial::Monochrome: return QStringLiteral("monochrome");
            case ColorMaterial::Rainbow: return QStringLiteral("rainbow");
            case ColorMaterial::Fidelity: return QStringLiteral("fidelity");
            case ColorMaterial::Content: return QStringLiteral("content");
            case ColorMaterial::Neutral: return QStringLiteral("neutral");
            case ColorMaterial::TonalSpot: break;
        }
        return QStringLiteral("tonal-spot");
    }

} // namespace

ColorMaterial::ColorMaterial(QObject* parent) : QObject(parent) {
    mDebounce.setSingleShot(true);
    mDebounce.setInterval(0);
    connect(&mDebounce, &QTimer::timeout, this, &ColorMaterial::rebuild);
}

QUrl ColorMaterial::source() const {
    return mSource;
}

void ColorMaterial::setSource(const QUrl& source) {
    if (mSource == source)
        return;
    mSource = source;
    sourceChanged();
    scheduleRebuild();
}

int ColorMaterial::rescaleSize() const {
    return mRescaleSize;
}

void ColorMaterial::setRescaleSize(int rescaleSize) {
    if (mRescaleSize == rescaleSize)
        return;
    mRescaleSize = rescaleSize;
    rescaleSizeChanged();
    scheduleRebuild();
}

bool ColorMaterial::darkMode() const {
    return mDarkMode;
}

void ColorMaterial::setDarkMode(bool darkMode) {
    if (mDarkMode == darkMode)
        return;
    mDarkMode = darkMode;
    darkModeChanged();
    scheduleRebuild();
}

ColorMaterial::Scheme ColorMaterial::scheme() const {
    return mScheme;
}

void ColorMaterial::setScheme(Scheme scheme) {
    if (mScheme == scheme)
        return;
    mScheme = scheme;
    schemeChanged();
    scheduleRebuild();
}

double ColorMaterial::contrastLevel() const {
    return mContrastLevel;
}

namespace {
    constexpr bool safeCompare(double a, double b, double epsilon = 1e-9) {
        return std::abs(a - b) <= (epsilon * std::max({1.0, std::abs(a), std::abs(b)}));
    }
}

void ColorMaterial::setContrastLevel(double contrastLevel) {
    if (safeCompare(mContrastLevel, contrastLevel))
        return;
    mContrastLevel = contrastLevel;
    contrastLevelChanged();
    scheduleRebuild();
}

bool ColorMaterial::smart() const {
    return mSmart;
}

void ColorMaterial::setSmart(bool smart) {
    if (mSmart == smart)
        return;
    mSmart = smart;
    smartChanged();
    scheduleRebuild();
}

QVariantMap ColorMaterial::colors() const {
    return mColors;
}

QColor ColorMaterial::sourceColor() const {
    return mSourceColor;
}

bool ColorMaterial::ready() const {
    return mReady;
}

QString ColorMaterial::error() const {
    return mError;
}

void ColorMaterial::scheduleRebuild() {
    mDebounce.start();
}

void ColorMaterial::rebuild() {
    ++mGeneration;
    const std::uint64_t generation = mGeneration;

    // Accepts both file:// URLs and plain absolute paths (MPRIS art paths
    // arrive without a scheme).
    QString path;
    if (mSource.isLocalFile())
        path = mSource.toLocalFile();
    else if (mSource.scheme().isEmpty() && mSource.path().startsWith(QLatin1Char('/')))
        path = mSource.path();

    if (path.isEmpty()) {
        applyResult({}, {}, QString());
        return;
    }
    const QString mode          = mDarkMode ? QStringLiteral("dark") : QStringLiteral("light");
    const QString scheme        = schemeToString(mScheme);
    const int     rescaleSize   = mRescaleSize;
    const double  contrastLevel = mContrastLevel;
    const bool    smart         = mSmart;

    QThreadPool::globalInstance()->start([this, generation, path, mode, scheme, rescaleSize, contrastLevel, smart] {
        const auto result = buildPalette(path, mode, scheme, smart, rescaleSize, contrastLevel);
        QMetaObject::invokeMethod(
            this,
            [this, generation, result] {
                if (generation != mGeneration)
                    return;
                applyResult(colorsToVariantMap(result.colors), QColor(result.colors.value(QStringLiteral("sourceColor"))), result.error);
            },
            Qt::QueuedConnection);
    });
}

void ColorMaterial::applyResult(const QVariantMap& colors, const QColor& sourceColor, const QString& error) {
    const bool ready = !colors.isEmpty() && error.isEmpty();

    const bool colorsDirty      = mColors != colors;
    const bool sourceColorDirty = mSourceColor != sourceColor;
    const bool readyDirty       = mReady != ready;
    const bool errorDirty       = mError != error;

    mColors      = colors;
    mSourceColor = sourceColor;
    mReady       = ready;
    mError       = error;

    if (colorsDirty)
        colorsChanged();
    if (sourceColorDirty)
        sourceColorChanged();
    if (readyDirty)
        readyChanged();
    if (errorDirty)
        errorChanged();
}
