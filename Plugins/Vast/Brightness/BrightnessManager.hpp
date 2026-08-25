#pragma once

#include "BrightnessProfileStore.hpp"

#include <ddcutil_types.h>
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
#include <cstdint>
#include <expected>
#include <filesystem>
#include <string>
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

    enum class DisplayType : uint8_t {
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

    // Per-display state shared between the UI thread and the single JobExecutor
    // worker that performs every hardware write. No thread per display anymore:
    // rapid changes coalesce into the one pending slot, and a single queued
    // write per display drains whatever value is latest by the time it runs.
    class DisplayWorker final {
      public:
        ~DisplayWorker()                          = default;
        DisplayWorker(DisplayWorker&&)            = delete;
        DisplayWorker& operator=(DisplayWorker&&) = delete;
        explicit DisplayWorker(DisplayMeta meta, int initialBrightness) : mMeta(std::move(meta)), mCurrentBrightness(initialBrightness) {}

        DisplayWorker(const DisplayWorker&)                              = delete;
        DisplayWorker&                   operator=(const DisplayWorker&) = delete;

        [[nodiscard]] const DisplayMeta& meta() const noexcept {
            return mMeta;
        }

        [[nodiscard]] int currentBrightness() const noexcept {
            return mCurrentBrightness;
        }
        void setCurrentBrightness(int v) noexcept {
            mCurrentBrightness = v;
        }

        void storePending(int percent) noexcept {
            mPendingValue.store(percent, std::memory_order_release);
        }
        [[nodiscard]] bool hasPending() const noexcept {
            return mPendingValue.load(std::memory_order_acquire) != K_EMPTY;
        }
        [[nodiscard]] int takePending() noexcept {
            return mPendingValue.exchange(K_EMPTY, std::memory_order_acq_rel);
        }

        // Serializes hardware access: at most one queued write per display.
        [[nodiscard]] bool beginWrite() noexcept {
            return !mWriteInFlight.exchange(true, std::memory_order_acq_rel);
        }
        void endWrite() noexcept {
            mWriteInFlight.store(false, std::memory_order_release);
        }

      private:
        static constexpr int K_EMPTY = -1;

        DisplayMeta          mMeta;
        std::atomic<int>     mPendingValue{K_EMPTY};
        std::atomic<bool>    mWriteInFlight{false};
        int                  mCurrentBrightness; // main-thread only
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
        using WorkerMap = std::map<QString, std::shared_ptr<DisplayWorker>>;
        [[nodiscard]] static std::expected<DdcHandle, BrightnessError> openDdcHandle(DDCA_Display_Ref ref) noexcept;
        [[nodiscard]] static std::expected<int, BrightnessError>       readDdcBrightness(const DdcHandle& handle) noexcept;
        [[nodiscard]] static std::expected<void, BrightnessError>      writeDdcBrightness(const DdcHandle& handle, int percent) noexcept;

        [[nodiscard]] static std::expected<int, BrightnessError>       readBacklightBrightness(const std::filesystem::path& root) noexcept;
        [[nodiscard]] static std::expected<void, BrightnessError>      writeBacklightBrightness(const std::filesystem::path& root, int percent) noexcept;

        void                                                           dispatchWrite(const QString& id, const std::shared_ptr<DisplayWorker>& worker);

        [[nodiscard]] static constexpr int                             clampPercent(int v) noexcept;

        WorkerMap                                                      mWorkers;
        BrightnessProfileStore                                         mProfileStore;
    };

} // namespace vast
