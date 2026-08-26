#pragma once

#include <qcontainerfwd.h>
#include <qjsengine.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>
#include <qtimer.h>
#include <qtypes.h>
#include <memory>
#include <vector>

#include "AudioCardsModel.hpp"

class AudioProfilesWatcher : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(AudioCardsModel* cards READ cards NOTIFY cardsChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

  public:
    static AudioProfilesWatcher* create(QQmlEngine* engine, QJSEngine* jsEngine);

    explicit AudioProfilesWatcher(QObject* parent = nullptr);
    ~AudioProfilesWatcher() override;
    AudioProfilesWatcher(const AudioProfilesWatcher&)                = delete;
    AudioProfilesWatcher& operator=(const AudioProfilesWatcher&)     = delete;
    AudioProfilesWatcher(AudioProfilesWatcher&&)                     = delete;
    AudioProfilesWatcher&          operator=(AudioProfilesWatcher&&) = delete;

    [[nodiscard]] AudioCardsModel* cards() const {
        return mCards;
    }
    [[nodiscard]] bool connected() const {
        return mConnected;
    }

  signals:
    void cardsChanged();
    void connectedChanged();

  private:
    void                 poll();

    static constexpr int K_MIN_POLL_MS = 100;
    static constexpr int K_MAX_POLL_MS = 2000;

    AudioCardsModel*     mCards          = nullptr;
    QTimer*              mTimer          = nullptr;
    int                  mPollIntervalMs = K_MIN_POLL_MS;
    bool                 mConnected      = false;

    struct PwState;
    std::unique_ptr<PwState> mPw;
};
