#include "BrightnessManager.hpp"

#include <cstdint>
#include <expected>
#include <ddcutil_types.h>
#include <ddcutil_c_api.h>
#include <filesystem>
#include <memory>
#include <mutex>
#include <qcontainerfwd.h>
#include <qdebug.h>

#include <algorithm>
#include <fstream>
#include <qlist.h>
#include <qobject.h>
#include <qlogging.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <ranges>
#include <string>
#include <utility>
#include <string_view>
#include <vector>
#include <stop_token>
#include <shared_mutex>

namespace vast {

    namespace {
        constexpr std::uint8_t K_VCP_BRIGHTNESS = 0x10;
        constexpr int          K_MIN_PERCENT    = 0;
        constexpr int          K_MAX_PERCENT    = 100;
    }

    constexpr int BrightnessManager::clampPercent(int v) noexcept {
        return std::clamp(v, K_MIN_PERCENT, K_MAX_PERCENT);
    }

    BrightnessManager::BrightnessManager(QObject* parent) : QObject(parent) {}

    /* NOTE: no explicit destructor body needed
	 * each DisplayWorkers m_thread is a std::jthread, its destructor calls
     * request_stop() then join() automatically. The stop_token wakes the
     * condition_variable_any::wait, so every worker exits cleanly with zero
     * explicit teardown code here
	 */

    std::expected<DdcHandle, BrightnessError> BrightnessManager::openDdcHandle(DDCA_Display_Ref ref) noexcept {
        DDCA_Display_Handle h{};
        const DDCA_Status   rc = ddca_open_display2(ref, /*wait=*/false, &h);
        if (rc != 0) {
            return std::unexpected(BrightnessError{
                .message = ddca_rc_desc(rc),
                .code    = static_cast<int>(rc),
            });
        }
        return DdcHandle{h};
    }

    std::expected<int, BrightnessError> BrightnessManager::readDdcBrightness(const DdcHandle& handle) noexcept {
        DDCA_Non_Table_Vcp_Value val{};
        const DDCA_Status        rc = ddca_get_non_table_vcp_value(handle.get(), K_VCP_BRIGHTNESS, &val);
        if (rc != 0) {
            return std::unexpected(BrightnessError{
                .message = ddca_rc_desc(rc),
                .code    = static_cast<int>(rc),
            });
        }
        const int current = (val.sh << 8) | val.sl;
        const int max     = (val.mh << 8) | val.ml;
        if (max == 0) {
            return std::unexpected(BrightnessError{.message = "monitor reported max brightness of 0"});
        }
        return (current * K_MAX_PERCENT) / max;
    }

    std::expected<void, BrightnessError> BrightnessManager::writeDdcBrightness(const DdcHandle& handle, int percent) noexcept {
        // most modern monitors use a 0–100 native range for VCP 0x10
        // hi_byte = 0, lo_byte = percent
        const DDCA_Status rc = ddca_set_non_table_vcp_value(handle.get(), K_VCP_BRIGHTNESS,
                                                            /*hi_byte=*/static_cast<uint8_t>(percent >> 8),
                                                            /*lo_byte=*/static_cast<uint8_t>(percent & 0xFF));
        if (rc != 0) {
            return std::unexpected(BrightnessError{
                .message = ddca_rc_desc(rc),
                .code    = static_cast<int>(rc),
            });
        }
        return {};
    }

    std::expected<int, BrightnessError> BrightnessManager::readBacklightBrightness(const std::filesystem::path& root) noexcept {
        std::ifstream bStream(root / "brightness");
        std::ifstream mStream(root / "max_brightness");

        if (!bStream || !mStream) {
            return std::unexpected(BrightnessError{
                .message = std::string("cannot read sysfs backlight at ") + root.string(),
            });
        }

        int current{0};
        int max{0};
        bStream >> current;
        mStream >> max;

        if (max == 0) {
            return std::unexpected(BrightnessError{.message = "max_brightness is 0"});
        }
        return (current * K_MAX_PERCENT) / max;
    }

    std::expected<void, BrightnessError> BrightnessManager::writeBacklightBrightness(const std::filesystem::path& root, int percent) noexcept {
        std::ifstream mStream(root / "max_brightness");
        if (!mStream) {
            return std::unexpected(BrightnessError{
                .message = "cannot write " + root.string() + "/brightness — add user to 'video' group or check udev rules",
            });
        }
        int max{0};
        mStream >> max;

        std::ofstream bStream(root / "brightness");
        if (!bStream) {
            return std::unexpected(BrightnessError{
                .message = "cannot write brightness — missing i2c group membership?",
            });
        }
        bStream << (percent * max / K_MAX_PERCENT);
        return {};
    }

    void BrightnessManager::initialize() {
        DDCA_Display_Info_List* infoList{};
        ddca_get_display_info_list2(/*include_invalid_displays=*/false, &infoList);

        if (infoList) {
            for (int i = 0; i < infoList->ct; ++i) {
                const auto& info = infoList->info[i];

                auto        handleResult = openDdcHandle(info.dref);
                if (!handleResult) {
                    qWarning() << "[BrightnessManager] DDC open failed:" << handleResult.error().message;
                    continue;
                }

                const int     initial = readDdcBrightness(*handleResult).value_or(50);
                const QString id      = QString::fromUtf8(info.model_name);
                const QString name    = QStringLiteral("%1 %2").arg(QString::fromUtf8(info.mfg_id)).arg(QString::fromUtf8(info.model_name));

                auto          meta = DisplayMeta{
                             .id            = id,
                             .name          = name,
                             .type          = DisplayType::Ddc,
                             .backlightPath = {},
                             .ddcHandle     = std::move(*handleResult),
                };

                auto worker = std::make_unique<DisplayWorker>(std::move(meta), initial);
                spawnWorkerThread(id, *worker);

                std::unique_lock const lock(mWorkersMutex);
                mWorkers.emplace(id, std::move(worker));
            }
            ddca_free_display_info_list(infoList);
        }

        constexpr std::string_view kBacklightRoot = "/sys/class/backlight";

        if (std::filesystem::exists(kBacklightRoot)) {
            // collect all backlight entries, sorted by max_brightness descending
            // prefer intel_backlight / amdgpu_bl* over acpi_video* which is a
            // virtual ACPI interface requiring root to write
            std::vector<std::filesystem::path> entries;
            for (const auto& e : std::filesystem::directory_iterator(kBacklightRoot)) {
                const auto name = e.path().filename().string();
                // acpi_video* requires root, skip entirely
                if (name.starts_with("acpi_video"))
                    continue;
                entries.push_back(e.path());
            }

            for (const auto& path : entries) {
                const int     initial = readBacklightBrightness(path).value_or(50);
                const QString id      = QString::fromStdString(path.filename().string());
                auto          meta    = DisplayMeta{
                                .id            = id,
                                .name          = QStringLiteral("Internal: %1").arg(id),
                                .type          = DisplayType::Backlight,
                                .backlightPath = path,
                                .ddcHandle     = {},
                };
                auto worker = std::make_unique<DisplayWorker>(std::move(meta), initial);
                spawnWorkerThread(id, *worker);
                std::unique_lock const lock(mWorkersMutex);
                mWorkers.emplace(id, std::move(worker));
            }
        }

        emit displayListChanged();
    }

    void BrightnessManager::spawnWorkerThread(const QString& id, DisplayWorker& worker) {
        worker.spawnThread([this, &worker, id](const std::stop_token& st) { workerLoop(id, worker, st); });
    }

    void BrightnessManager::workerLoop(const QString& id, DisplayWorker& worker, const std::stop_token& st) {
        while (!st.stop_requested()) {
            const auto maybeValue = worker.waitForValue(st);
            if (!maybeValue)
                break;

            const int          percent = clampPercent(*maybeValue);
            const DisplayMeta& meta    = worker.meta();

            const auto         result = [&]() -> std::expected<void, BrightnessError> {
                switch (meta.type) {
                    case DisplayType::Ddc: return writeDdcBrightness(meta.ddcHandle, percent);
                    case DisplayType::Backlight: return writeBacklightBrightness(meta.backlightPath, percent);
                }
                std::unreachable();
            }();

            if (result) {
                worker.setCurrentBrightness(percent);
                emit brightnessChanged(id, percent);
            } else {
                qWarning() << "[BrightnessManager] set failed for" << id << "—" << result.error().message;
            }
        }
    }

    QVariantList BrightnessManager::displays() const {
        std::shared_lock const lock(mWorkersMutex);
        QList<QVariant>        out;
        out.reserve(static_cast<qsizetype>(mWorkers.size()));

        for (const auto& [id, worker] : mWorkers) {
            const auto& meta = worker->meta();
            out.append(QVariantMap{
                {QStringLiteral("id"), id},
                {QStringLiteral("name"), meta.name},
                {QStringLiteral("brightness"), worker->currentBrightness()},
                {QStringLiteral("isInternal"), meta.type == DisplayType::Backlight},
            });
        }
        return out;
    }

    void BrightnessManager::setBrightness(const QString& displayId, int percent) {
        std::shared_lock const lock(mWorkersMutex);
        if (const auto it = mWorkers.find(displayId); it != mWorkers.end()) {
            it->second->enqueue(clampPercent(percent));
        }
    }

    void BrightnessManager::setBrightnessGroup(const QVariantMap& targets) {
        std::shared_lock const lock(mWorkersMutex);

        // 1. write all values before waking any thread
        // this guarantees the narrowest possible window between displays
        for (const auto& [id, value] : targets.asKeyValueRange())
            if (const auto it = mWorkers.find(id); it != mWorkers.end())
                it->second->pushPending(clampPercent(value.toInt()));

        // 2. notify all simultaneously
        for (const auto& [id, value] : targets.asKeyValueRange())
            if (const auto it = mWorkers.find(id); it != mWorkers.end())
                it->second->notifyWorker();
    }

    void BrightnessManager::setBrightnessAll(int percent) {
        std::shared_lock const lock(mWorkersMutex);
        const int              v = clampPercent(percent);

        std::ranges::for_each(mWorkers, [v](const auto& kv) { kv.second->pushPending(v); });
        std::ranges::for_each(mWorkers, [](const auto& kv) { kv.second->notifyWorker(); });
    }

    void BrightnessManager::saveProfile(const QString& name, const QVariantMap& targets) {
        mProfiles.insert_or_assign(name, targets);
    }

    void BrightnessManager::applyProfile(const QString& name) {
        if (const auto it = mProfiles.find(name); it != mProfiles.end())
            setBrightnessGroup(it->second);
    }

    void BrightnessManager::removeProfile(const QString& name) {
        mProfiles.erase(name);
    }

    QStringList BrightnessManager::profileNames() const {
        const auto keys = mProfiles | std::views::keys;
        return QStringList(std::ranges::begin(keys), std::ranges::end(keys));
    }

}
