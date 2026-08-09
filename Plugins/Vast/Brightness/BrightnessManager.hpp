#pragma once

#include <ddcutil_types.h>
#include <functional>
#include <qcontainerfwd.h>
#include <map>
#include <memory>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtmetamacros.h>
#include <qvariant.h>
#include <qvariantmap.h>

#include <atomic>
#include <condition_variable>
#include <cstdint>
#include <expected>
#include <filesystem>
#include <mutex>
#include <optional>
#include <shared_mutex>
#include <stop_token>
#include <string>
#include <thread>
#include <utility>

extern "C" {
#include <ddcutil_c_api.h>
}

namespace vast {

    struct BrightnessError {
        std::string message;
        int         code{0};
    };

    class DdcHandle final {
      public:
        DdcHandle() noexcept = default;
        explicit DdcHandle(DDCA_Display_Handle h) noexcept : mHandle(h) {}
        ~DdcHandle() noexcept {
            reset();
        }

        DdcHandle(const DdcHandle&)            = delete;
        DdcHandle& operator=(const DdcHandle&) = delete;

        DdcHandle(DdcHandle&& o) noexcept : mHandle(std::exchange(o.mHandle, nullptr)) {}

        DdcHandle& operator=(DdcHandle&& o) noexcept {
            if (this != &o) {
                reset();
                mHandle = std::exchange(o.mHandle, nullptr);
            }
            return *this;
        }

        [[nodiscard]] bool valid() const noexcept {
            return mHandle != nullptr;
        }
        [[nodiscard]] DDCA_Display_Handle get() const noexcept {
            return mHandle;
        }

        void reset() noexcept {
            if (mHandle) {
                ddca_close_display(mHandle);
                mHandle = nullptr;
            }
        }

      private:
        DDCA_Display_Handle mHandle{nullptr};
    };

    enum class DisplayType : std::uint8_t {
        Ddc,
        Backlight
    };

    struct DisplayMeta {
        QString               id;
        QString               name;
        DisplayType           type;
        std::filesystem::path backlightPath;
        DdcHandle             ddcHandle;
    };

    // owns a jthread + a single "latest pending value" slot
    // non-copyable and non-movable (mutex/cv members)
    class DisplayWorker final {
      public:
        explicit DisplayWorker(DisplayMeta meta, int initialBrightness) noexcept : mMeta(std::move(meta)), mCurrentBrightness(initialBrightness) {}

        ~DisplayWorker()                                            = default;
        DisplayWorker(const DisplayWorker&)                         = delete;
        DisplayWorker& operator=(const DisplayWorker&)              = delete;
        DisplayWorker(DisplayWorker&&)                              = delete;
        DisplayWorker&                   operator=(DisplayWorker&&) = delete;

        [[nodiscard]] const DisplayMeta& meta() const noexcept {
            return mMeta;
        }
        [[nodiscard]] int currentBrightness() const noexcept {
            return mCurrentBrightness.load(std::memory_order_acquire);
        }

        // push a pending value WITHOUT notifying, used in group/atomic operations
        // so all displays get their value before any thread wakes
        void pushPending(int percent) noexcept {
            mPendingValue.store(percent, std::memory_order_release);
        }

        // wake the worker thread so it can process m_pendingValue
        void notifyWorker() noexcept {
            mCv.notify_one();
        }

        void enqueue(int percent) noexcept {
            pushPending(percent);
            notifyWorker();
        }

        void spawnThread(std::function<void(std::stop_token)> fn) {
            mThread = std::jthread(std::move(fn));
        }

        // blocks the calling thread until a new value arrives or stop is requested
        // returns the clamped value, or nullopt on stop
        [[nodiscard]] std::optional<int> waitForValue(std::stop_token st) {
            std::unique_lock lock(mMutex);
            const bool       notStopped = mCv.wait(lock, std::move(st), [this] { return mPendingValue.load(std::memory_order_acquire) != K_EMPTY; });
            if (!notStopped)
                return std::nullopt;
            const int v = mPendingValue.exchange(K_EMPTY, std::memory_order_acq_rel);
            return v == K_EMPTY ? std::nullopt : std::make_optional(v);
        }

        void setCurrentBrightness(int v) noexcept {
            mCurrentBrightness.store(v, std::memory_order_release);
        }

      private:
        static constexpr int        K_EMPTY = -1;

        DisplayMeta                 mMeta;
        std::atomic<int>            mPendingValue{K_EMPTY};
        std::atomic<int>            mCurrentBrightness{K_EMPTY};
        std::mutex                  mMutex;
        std::condition_variable_any mCv;
        std::jthread                mThread;
    };

    class BrightnessManager final : public QObject {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

      public:
        explicit BrightnessManager(QObject* parent = nullptr);
        ~BrightnessManager() override                            = default;
        BrightnessManager(const BrightnessManager&)              = delete;
        BrightnessManager& operator=(const BrightnessManager&)   = delete;
        BrightnessManager(BrightnessManager&&)                   = delete;
        BrightnessManager&        operator=(BrightnessManager&&) = delete;

        [[nodiscard]] Q_INVOKABLE QList<QVariant> displays() const;
        Q_INVOKABLE void                          initialize();

        Q_INVOKABLE void                          setBrightness(const QString& displayId, int percent);
        Q_INVOKABLE void                          setBrightnessGroup(const QVariantMap& targets);
        Q_INVOKABLE void                          setBrightnessAll(int percent);

        Q_INVOKABLE void                          saveProfile(const QString& name, const QVariantMap& targets);
        Q_INVOKABLE void                          applyProfile(const QString& name);
        Q_INVOKABLE void                          removeProfile(const QString& name);
        [[nodiscard]] Q_INVOKABLE QStringList     profileNames() const;

      signals:
        void brightnessChanged(const QString& displayId, int percent);
        void initializationFailed(const QString& reason);
        void displayListChanged();

      private:
        using WorkerMap  = std::map<QString, std::unique_ptr<DisplayWorker>>;
        using ProfileMap = std::map<QString, QVariantMap>;

        [[nodiscard]] static std::expected<DdcHandle, BrightnessError> openDdcHandle(DDCA_Display_Ref ref) noexcept;
        [[nodiscard]] static std::expected<int, BrightnessError>       readDdcBrightness(const DdcHandle& handle) noexcept;
        [[nodiscard]] static std::expected<void, BrightnessError>      writeDdcBrightness(const DdcHandle& handle, int percent) noexcept;

        [[nodiscard]] static std::expected<int, BrightnessError>       readBacklightBrightness(const std::filesystem::path& root) noexcept;
        [[nodiscard]] static std::expected<void, BrightnessError>      writeBacklightBrightness(const std::filesystem::path& root, int percent) noexcept;

        void                                                           spawnWorkerThread(const QString& id, DisplayWorker& worker);
        void                                                           workerLoop(const QString& id, DisplayWorker& worker, const std::stop_token& st);

        [[nodiscard]] static constexpr int                             clampPercent(int v) noexcept;

        WorkerMap                                                      mWorkers;
        ProfileMap                                                     mProfiles;
        mutable std::shared_mutex                                      mWorkersMutex;
        mutable std::shared_mutex                                      mProfilesMutex;
    };

}
