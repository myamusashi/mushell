#pragma once
#include <qobject.h>
#include <qvariantmap.h>
#include <qvariantanimation.h>
#include <qqmlintegration.h>

class PaletteAnimator : public QObject {
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(QVariantMap currentPalette READ currentPalette NOTIFY currentPaletteChanged)
    Q_PROPERTY(int duration READ duration WRITE setDuration NOTIFY durationChanged)

  public:
    explicit PaletteAnimator(QObject* parent = nullptr);

    [[nodiscard]] QVariantMap currentPalette() const {
        return mCurrent;
    }
    [[nodiscard]] int duration() const {
        return mAnim->duration();
    }
    void setDuration(int ms) {
        mAnim->setDuration(ms);
        emit durationChanged();
    }

    Q_INVOKABLE void transitionTo(const QVariantMap& targetPalette);

  signals:
    void currentPaletteChanged();
    void durationChanged();

  private:
    QVariantMap        mCurrent;
    QVariantMap        mFrom;
    QVariantMap        mTarget;
    QVariantAnimation* mAnim;
};
