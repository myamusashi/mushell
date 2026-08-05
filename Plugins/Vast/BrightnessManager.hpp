#pragma once

#include <QtQml/qqmlregistration.h>
#include <qobject.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qvariantmap.h>

#include <atomic>
#include <condition_variable>
#include <expected>
#include <filesystem>
#include <mutex>
#include <optional>
#include <shared_mutex>
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
        explicit DdcHandle(DDCA_Display_Handle h) noexcept : m_handle(h) {}
        ~DdcHandle() noexcept {
            reset();
        }

        DdcHandle(const DdcHandle&)            = delete;
        DdcHandle& operator=(const DdcHandle&) = delete;

        DdcHandle(DdcHandle&& o) noexcept : m_handle(std::exchange(o.m_handle, nullptr)) {}

        DdcHandle& operator=(DdcHandle&& o) noexcept {
            if (this != &o) {
                reset();
                m_handle = std::exchange(o.m_handle, nullptr);
            }
            return *this;
        }

        [[nodiscard]] bool valid() const noexcept {
            return m_handle != nullptr;
        }
        [[nodiscard]] DDCA_Display_Handle get() const noexcept {
            return m_handle;
        }

        void reset() noexcept {
            if (m_handle) {
                ddca_close_display(m_handle);
                m_handle = nullptr;
            }
        }

      private:
        DDCA_Display_Handle m_handle{nullptr};
    };

    enum class DisplayType {
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
        explicit DisplayWorker(DisplayMeta meta, int initialBrightness) noexcept : m_meta(std::move(meta)), m_currentBrightness(initialBrightness) {}

        ~DisplayWorker()                                            = default;
        DisplayWorker(const DisplayWorker&)                         = delete;
        DisplayWorker& operator=(const DisplayWorker&)              = delete;
        DisplayWorker(DisplayWorker&&)                              = delete;
        DisplayWorker&                   operator=(DisplayWorker&&) = delete;

        [[nodiscard]] const DisplayMeta& meta() const noexcept {
            return m_meta;
        }
        [[nodiscard]] int currentBrightness() const noexcept {
            return m_currentBrightness.load(std::memory_order_acquire);
        }

        // push a pending value WITHOUT notifying, used in group/atomic operations
        // so all displays get their value before any thread wakes
        void pushPending(int percent) noexcept {
            m_pendingValue.store(percent, std::memory_order_release);
        }

        // wake the worker thread so it can process m_pendingValue
        void notifyWorker() noexcept {
            m_cv.notify_one();
        }

        void enqueue(int percent) noexcept {
            pushPending(percent);
            notifyWorker();
        }

        void spawnThread(std::function<void(std::stop_token)> fn) {
            m_thread = std::jthread(std::move(fn));
        }

        // blocks the calling thread until a new value arrives or stop is requested
        // returns the clamped value, or nullopt on stop
        [[nodiscard]] std::optional<int> waitForValue(std::stop_token st) {
            std::unique_lock lock(m_mutex);
            const bool       notStopped = m_cv.wait(lock, st, [this] { return m_pendingValue.load(std::memory_order_acquire) != kEmpty; });
            if (!notStopped)
                return std::nullopt;
            const int v = m_pendingValue.exchange(kEmpty, std::memory_order_acq_rel);
            return v == kEmpty ? std::nullopt : std::make_optional(v);
        }

        void setCurrentBrightness(int v) noexcept {
            m_currentBrightness.store(v, std::memory_order_release);
        }

      private:
        static constexpr int        kEmpty = -1;

        DisplayMeta                 m_meta;
        std::atomic<int>            m_pendingValue{kEmpty};
        std::atomic<int>            m_currentBrightness{kEmpty};
        std::mutex                  m_mutex;
        std::condition_variable_any m_cv;
        std::jthread                m_thread;
    };

    class BrightnessManager final : public QObject {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

      public:
        explicit BrightnessManager(QObject* parent = nullptr);
        ~BrightnessManager() override = default;

        Q_INVOKABLE void initialize();

        // returns list of QVariantMap { id, name, brightness, isInternal }
        [[nodiscard]] Q_INVOKABLE QVariantList displays() const;

        Q_INVOKABLE void                       setBrightness(const QString& displayId, int percent);
        Q_INVOKABLE void                       setBrightnessGroup(const QVariantMap& targets);
        Q_INVOKABLE void                       setBrightnessAll(int percent);

        Q_INVOKABLE void                       saveProfile(const QString& name, const QVariantMap& targets);
        Q_INVOKABLE void                       applyProfile(const QString& name);
        Q_INVOKABLE void                       removeProfile(const QString& name);
        [[nodiscard]] Q_INVOKABLE QStringList  profileNames() const;

      signals:
        void brightnessChanged(const QString& displayId, int percent);
        void initializationFailed(const QString& reason);
        void displayListChanged();

      private:
        using WorkerMap  = std::map<QString, std::unique_ptr<DisplayWorker>>;
        using ProfileMap = std::map<QString, QVariantMap>;

        [[nodiscard]] std::expected<DdcHandle, BrightnessError> openDdcHandle(DDCA_Display_Ref ref) const noexcept;
        [[nodiscard]] std::expected<int, BrightnessError>       readDdcBrightness(const DdcHandle& handle) const noexcept;
        [[nodiscard]] std::expected<void, BrightnessError>      writeDdcBrightness(const DdcHandle& handle, int percent) const noexcept;

        [[nodiscard]] std::expected<int, BrightnessError>       readBacklightBrightness(const std::filesystem::path& root) const noexcept;
        [[nodiscard]] std::expected<void, BrightnessError>      writeBacklightBrightness(const std::filesystem::path& root, int percent) const noexcept;

        void                                                    spawnWorkerThread(const QString& id, DisplayWorker& worker);
        void                                                    workerLoop(const QString& id, DisplayWorker& worker, std::stop_token st);

        [[nodiscard]] static constexpr int                      clampPercent(int v) noexcept;

        WorkerMap                                               m_workers;
        ProfileMap                                              m_profiles;
        mutable std::shared_mutex                               m_workersMutex;
    };

}
