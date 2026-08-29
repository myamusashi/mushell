#include "PaletteAnimator.hpp"
#include "ColorUtils.hpp"

PaletteAnimator::PaletteAnimator(QObject* parent) : QObject(parent), mAnim(new QVariantAnimation(this)) {
    mAnim->setStartValue(0.0);
    mAnim->setEndValue(1.0);
    mAnim->setDuration(300);
    mAnim->setEasingCurve(QEasingCurve::OutCubic);

    connect(mAnim, &QVariantAnimation::valueChanged, this, [this](const QVariant& v) {
        auto p   = v.toReal();
        mCurrent = ColorUtils::blendPalettes(mFrom, mTarget, p);
        emit currentPaletteChanged();
    });
}

void PaletteAnimator::transitionTo(const QVariantMap& targetPalette) {
    if (mAnim->state() == QAbstractAnimation::Running)
        mAnim->stop();

    mFrom   = mCurrent;
    mTarget = targetPalette;
    mAnim->start();
}
