#include "AudioProfilesWatcher.hpp"
#include "AudioProfilesModel.hpp"

#include <cstdint>
#include <array>
#include <cstddef>
#include <cstdio>
#include <cstring>
#include <qcontainerfwd.h>
#include <exception>
#include <qdebug.h>
#include <qjsengine.h>
#include <qhashfunctions.h>
#include <qlatin1stringview.h>
#include <qobject.h>
#include <qlogging.h>
#include <qlist.h>
#include <qqmlengine.h>
#include <qstringlist.h>

#include <algorithm>
#include <memory>
#include <mutex>
#include <spa/utils/dict.h>
#include <spa/pod/pod.h>
#include <spa/param/param.h>
#include <spa/utils/hook.h>
#include <spa/pod/body.h>
#include <qtimer.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <span>
#include <stdexcept>
#include <string_view>
#include <utility>
#include <vector>

extern "C" {
#include <pipewire/pipewire.h>
#include <spa/param/profile.h>
#include <spa/pod/iter.h>
}

struct PwThreadLoopDeleter {
    void operator()(pw_thread_loop* p) const {
        pw_thread_loop_destroy(p);
    }
};
struct PwContextDeleter {
    void operator()(pw_context* p) const {
        pw_context_destroy(p);
    }
};
struct PwCoreDeleter {
    void operator()(pw_core* p) const {
        pw_core_disconnect(p);
    }
};
struct PwRegistryDeleter {
    void operator()(pw_registry* p) const {
        pw_proxy_destroy(reinterpret_cast<pw_proxy*>(p));
    }
};

using UniquePwThreadLoop = std::unique_ptr<pw_thread_loop, PwThreadLoopDeleter>;
using UniquePwContext    = std::unique_ptr<pw_context, PwContextDeleter>;
using UniquePwCore       = std::unique_ptr<pw_core, PwCoreDeleter>;
using UniquePwRegistry   = std::unique_ptr<pw_registry, PwRegistryDeleter>;

constexpr int K_MAX_PROFILES = 64;
constexpr int K_MAX_STR      = 256;

struct ApProfileEntryT {
    int32_t                     index;
    std::array<char, K_MAX_STR> name{};
    std::array<char, K_MAX_STR> description{};
    std::array<char, 32>        available{};
};

struct ApDeviceNodeT {
    pw_proxy*                                   proxy = nullptr;
    spa_hook                                    deviceListener{};
    spa_hook                                    proxyListener{};

    uint32_t                                    pwId = 0;
    std::array<char, K_MAX_STR>                 name{};

    std::array<ApProfileEntryT, K_MAX_PROFILES> profiles{};
    int                                         profileCount = 0;

    std::array<ApProfileEntryT, K_MAX_PROFILES> staging{};
    int                                         stagingCount = 0;
    int                                         enumSeq      = 0;

    int32_t                                     activeIndex = -1;
    std::array<char, K_MAX_STR>                 activeName{};
    std::array<char, K_MAX_STR>                 activeDescription{};
    std::array<char, 32>                        activeAvailable{};

    int                                         dirty = 0;
};

namespace {

    void        apRegistryEventGlobal(void* data, uint32_t id, uint32_t permissions, const char* type, uint32_t version, const spa_dict* props);
    void        apRegistryEventGlobalRemove(void* data, uint32_t id);
    void        apDeviceEventInfo(void* data, const pw_device_info* info);
    void        apDeviceEventParam(void* data, int seq, uint32_t id, uint32_t index, uint32_t next, const spa_pod* param);
    void        apOnProxyDestroy(void* data);

    const char* apSafeLookup(const spa_dict* dict, const char* key) {
        if (!dict)
            return "";
        const char* v = spa_dict_lookup(dict, key);
        return v ? v : "";
    }

    template <std::size_t N>
    void apSafeCopy(std::array<char, N>& dst, const char* src) {
        if (!src) {
            dst[0] = '\0';
            return;
        }
        std::snprintf(dst.data(), N, "%s", src);
    }

    const char* apParseAvailability(const spa_pod* val) {
        uint32_t av = 0;
        if (spa_pod_get_id(val, &av) != 0)
            return "unknown";
        switch (av) {
            case SPA_PARAM_AVAILABILITY_yes: return "yes";
            case SPA_PARAM_AVAILABILITY_no: return "no";
            default: return "unknown";
        }
    }

    class PwApp {
      public:
        PwApp(const PwApp&)            = delete;
        PwApp& operator=(const PwApp&) = delete;
        PwApp(PwApp&&)                 = delete;
        PwApp& operator=(PwApp&&)      = delete;

        PwApp() {
            static std::once_flag sInit;
            std::call_once(sInit, [] {
                int argc = 0;
                pw_init(&argc, nullptr);
            });

            mLoop.reset(pw_thread_loop_new("pw-profiles", nullptr));
            if (!mLoop)
                throw std::runtime_error("pw_thread_loop_new failed");

            mContext.reset(pw_context_new(pw_thread_loop_get_loop(mLoop.get()), nullptr, 0));
            if (!mContext)
                throw std::runtime_error("pw_context_new failed");

            mCore.reset(pw_context_connect(mContext.get(), nullptr, 0));
            if (!mCore)
                throw std::runtime_error("pw_context_connect failed");

            mRegistry.reset(pw_core_get_registry(mCore.get(), PW_VERSION_REGISTRY, 0));
            if (!mRegistry)
                throw std::runtime_error("pw_core_get_registry failed");

            pw_registry_add_listener(mRegistry.get(), &mRegistryListener, &S_REGISTRY_EVENTS, this);

            if (pw_thread_loop_start(mLoop.get()) < 0)
                throw std::runtime_error("pw_thread_loop_start failed");
        }

        ~PwApp() {
            pw_thread_loop_stop(mLoop.get());
            std::ranges::for_each(mDevices, [](ApDeviceNodeT* d) { pw_proxy_destroy(d->proxy); });
            mDevices.clear();
            spa_hook_remove(&mRegistryListener);
        }

        [[nodiscard]] pw_thread_loop* loop() const {
            return mLoop.get();
        }
        [[nodiscard]] pw_registry* registry() const {
            return mRegistry.get();
        }

        std::vector<ApDeviceNodeT*>     mDevices;
        spa_hook                        mRegistryListener{};

        static const pw_registry_events S_REGISTRY_EVENTS;
        static const pw_device_events   S_DEVICE_EVENTS;
        static const pw_proxy_events    S_PROXY_EVENTS;

      private:
        UniquePwThreadLoop mLoop;
        UniquePwContext    mContext;
        UniquePwCore       mCore;
        UniquePwRegistry   mRegistry;
    };

    void apDeviceEventInfo(void* data, const pw_device_info* info) {
        auto* d = static_cast<ApDeviceNodeT*>(data);

        if (info->props) {
            const char* n = apSafeLookup(info->props, PW_KEY_DEVICE_NAME);
            if (*n)
                apSafeCopy(d->name, n);
        }

        if (info->change_mask & PW_DEVICE_CHANGE_MASK_PARAMS) {
            d->enumSeq      = pw_device_enum_params(reinterpret_cast<pw_device*>(d->proxy), 0, SPA_PARAM_EnumProfile, 0, UINT32_MAX, nullptr);
            d->stagingCount = 0;
            pw_device_enum_params(reinterpret_cast<pw_device*>(d->proxy), 0, SPA_PARAM_Profile, 0, UINT32_MAX, nullptr);
        }
    }

    void apDeviceEventParam(void* data, int seq, uint32_t id, uint32_t /*index*/, uint32_t /*next*/, const spa_pod* param) {
        auto* d = static_cast<ApDeviceNodeT*>(data);

        if (id == SPA_PARAM_EnumProfile) {
            if (seq != d->enumSeq)
                return;

            if (!param || !spa_pod_is_object(param)) {
                if (d->stagingCount > 0) {
                    std::copy_n(d->staging.begin(), static_cast<size_t>(d->stagingCount), d->profiles.begin());
                    d->profileCount = d->stagingCount;
                    d->stagingCount = 0;
                    d->dirty        = 1;
                }
                return;
            }

            if (d->stagingCount >= K_MAX_PROFILES)
                return;

            int32_t       pidx  = -1;
            const char*   name  = nullptr;
            const char*   desc  = nullptr;
            const char*   avail = "unknown";

            spa_pod_prop* prop = nullptr;
            SPA_POD_OBJECT_FOREACH(reinterpret_cast<const spa_pod_object*>(param), prop) {
                switch (prop->key) {
                    case SPA_PARAM_PROFILE_index: spa_pod_get_int(&prop->value, &pidx); break;
                    case SPA_PARAM_PROFILE_name: spa_pod_get_string(&prop->value, &name); break;
                    case SPA_PARAM_PROFILE_description: spa_pod_get_string(&prop->value, &desc); break;
                    case SPA_PARAM_PROFILE_available: avail = apParseAvailability(&prop->value); break;
                    default: break;
                }
            }

            auto& e = d->staging[static_cast<size_t>(d->stagingCount++)];
            e.index = pidx;
            apSafeCopy(e.name, name ? name : "");
            apSafeCopy(e.description, desc ? desc : "");
            apSafeCopy(e.available, avail);

        } else if (id == SPA_PARAM_Profile) {
            if (!param || !spa_pod_is_object(param))
                return;

            if (d->stagingCount > 0) {
                std::copy_n(d->staging.begin(), static_cast<size_t>(d->stagingCount), d->profiles.begin());
                d->profileCount = d->stagingCount;
                d->stagingCount = 0;
            }

            int32_t       pidx  = -1;
            const char*   name  = nullptr;
            const char*   desc  = nullptr;
            const char*   avail = "unknown";

            spa_pod_prop* prop = nullptr;
            SPA_POD_OBJECT_FOREACH(reinterpret_cast<const spa_pod_object*>(param), prop) {
                switch (prop->key) {
                    case SPA_PARAM_PROFILE_index: spa_pod_get_int(&prop->value, &pidx); break;
                    case SPA_PARAM_PROFILE_name: spa_pod_get_string(&prop->value, &name); break;
                    case SPA_PARAM_PROFILE_description: spa_pod_get_string(&prop->value, &desc); break;
                    case SPA_PARAM_PROFILE_available: avail = apParseAvailability(&prop->value); break;
                    default: break;
                }
            }

            d->activeIndex = pidx;
            apSafeCopy(d->activeName, name ? name : "");
            apSafeCopy(d->activeDescription, desc ? desc : "");
            apSafeCopy(d->activeAvailable, avail);
            d->dirty = 1;
        }
    }

    void apOnProxyDestroy(void* data) {
        auto* d = static_cast<ApDeviceNodeT*>(data);
        spa_hook_remove(&d->deviceListener);
        spa_hook_remove(&d->proxyListener);
        delete d;
    }

    void apRegistryEventGlobal(void* data, uint32_t id, uint32_t /*permissions*/, const char* type, uint32_t /*version*/, const spa_dict* props) {
        auto* app = static_cast<PwApp*>(data);

        if (strcmp(type, PW_TYPE_INTERFACE_Device) != 0)
            return;

        if (!std::string_view(apSafeLookup(props, PW_KEY_MEDIA_CLASS)).contains("Audio"))
            return;

        auto* d = new ApDeviceNodeT();
        d->pwId = id;
        apSafeCopy(d->name, apSafeLookup(props, PW_KEY_DEVICE_NAME));

        d->proxy = static_cast<pw_proxy*>(pw_registry_bind(app->registry(), id, PW_TYPE_INTERFACE_Device, PW_VERSION_DEVICE, 0));
        if (!d->proxy) {
            delete d;
            return;
        }

        pw_proxy_add_object_listener(d->proxy, &d->deviceListener, &PwApp::S_DEVICE_EVENTS, d);
        pw_proxy_add_listener(d->proxy, &d->proxyListener, &PwApp::S_PROXY_EVENTS, d);
        app->mDevices.push_back(d);
    }

    void apRegistryEventGlobalRemove(void* data, uint32_t id) {
        auto* app = static_cast<PwApp*>(data);

        auto  it = std::ranges::find_if(app->mDevices, [id](const ApDeviceNodeT* d) { return d->pwId == id; });

        if (it == app->mDevices.end())
            return;

        ApDeviceNodeT* d = *it;
        app->mDevices.erase(it);
        pw_proxy_destroy(d->proxy);
    }

    const pw_registry_events PwApp::S_REGISTRY_EVENTS = {
        .version       = PW_VERSION_REGISTRY_EVENTS,
        .global        = apRegistryEventGlobal,
        .global_remove = apRegistryEventGlobalRemove,
    };
    const pw_device_events PwApp::S_DEVICE_EVENTS = {
        .version = PW_VERSION_DEVICE_EVENTS,
        .info    = apDeviceEventInfo,
        .param   = apDeviceEventParam,
    };
    const pw_proxy_events PwApp::S_PROXY_EVENTS = {
        .version     = PW_VERSION_PROXY_EVENTS,
        .destroy     = apOnProxyDestroy,
        .bound       = nullptr,
        .removed     = nullptr,
        .done        = nullptr,
        .error       = nullptr,
        .bound_props = nullptr,
    };

    ApDeviceNodeT* apDrainDirty(std::span<ApDeviceNodeT* const> devices) {
        auto it = std::ranges::find_if(devices, [](const ApDeviceNodeT* d) { return d->dirty && d->profileCount > 0; });
        if (it == devices.end())
            return nullptr;
        (*it)->dirty = 0;
        return *it;
    }

} // namespace

struct AudioProfilesWatcher::PwState {
    std::unique_ptr<PwApp> app;
};

AudioProfilesWatcher* AudioProfilesWatcher::create(QQmlEngine* /*unused*/, QJSEngine* /*unused*/) {
    static AudioProfilesWatcher sInstance;
    return &sInstance;
}

QString AudioProfilesWatcher::formatProfileName(const QString& name) {
    if (name == u"off")
        return QStringLiteral("Off");
    if (name == u"pro-audio")
        return QStringLiteral("Pro Audio");

    const QStringList parts = name.split(QLatin1Char('+'));
    QStringList       out;
    out.reserve(parts.size());

    for (QString part : parts) {
        part = part.trimmed();
        if (part.startsWith(QLatin1String("output:")))
            part.remove(0, 7);
        else if (part.startsWith(QLatin1String("input:")))
            part.remove(0, 6);

        QStringList words = part.split(QLatin1Char('-'));
        for (QString& w : words)
            if (!w.isEmpty())
                w[0] = w[0].toUpper();
        out << words.join(QLatin1Char(' '));
    }
    return out.join(QStringLiteral(" + "));
}

AudioProfilesWatcher::AudioProfilesWatcher(QObject* parent) : QObject(parent), mModel(new AudioProfilesModel(this)), mTimer(new QTimer(this)), mPw(std::make_unique<PwState>()) {
    try {
        mPw->app   = std::make_unique<PwApp>();
        mConnected = true;
        emit connectedChanged();
    } catch (const std::exception& e) { qWarning("AudioProfilesWatcher: failed to connect to PipeWire: %s", e.what()); }

    mTimer->setSingleShot(true);
    connect(mTimer, &QTimer::timeout, this, &AudioProfilesWatcher::poll);
    if (mConnected)
        mTimer->start(K_MIN_POLL_MS);
}

AudioProfilesWatcher::~AudioProfilesWatcher() {
    mTimer->stop();
}

void AudioProfilesWatcher::poll() {
    if (!mPw->app)
        return;

    PwApp* app = mPw->app.get();

    struct DeviceSnapshot {
        quint32             deviceId{};
        QString             deviceName;
        qsizetype           activeIdx{};
        QVariantMap         activeProfile;
        QList<ProfileEntry> profiles;
    };
    QList<DeviceSnapshot> snapshots;

    pw_thread_loop_lock(app->loop());
    while (ApDeviceNodeT* d = apDrainDirty(app->mDevices)) {
        const QString  actName = QString::fromUtf8(d->activeName.data());

        DeviceSnapshot snap;
        snap.deviceId      = d->pwId;
        snap.deviceName    = QString::fromUtf8(d->name.data());
        snap.activeIdx     = d->activeIndex;
        snap.activeProfile = {
            {QStringLiteral("index"), d->activeIndex},
            {QStringLiteral("name"), actName},
            {QStringLiteral("description"), QString::fromUtf8(d->activeDescription.data())},
            {QStringLiteral("available"), QString::fromUtf8(d->activeAvailable.data())},
            {QStringLiteral("readable"), formatProfileName(actName)},
        };

        snap.profiles.reserve(d->profileCount);
        for (const auto& e : std::span(d->profiles.data(), static_cast<size_t>(d->profileCount))) {
            const QString nm = QString::fromUtf8(e.name.data());
            snap.profiles.append(ProfileEntry{
                .index       = e.index,
                .name        = nm,
                .description = QString::fromUtf8(e.description.data()),
                .available   = QString::fromUtf8(e.available.data()),
                .readable    = formatProfileName(nm),
            });
        }
        snapshots.append(std::move(snap));
    }
    pw_thread_loop_unlock(app->loop());

    if (snapshots.isEmpty()) {
        // Nothing dirty — exponential backoff to reduce idle CPU
        mPollIntervalMs = std::min(mPollIntervalMs * 2, K_MAX_POLL_MS);
        mTimer->start(mPollIntervalMs);
        return;
    }

    // Activity detected — reset to fast polling
    mPollIntervalMs = K_MIN_POLL_MS;

    for (const DeviceSnapshot& snap : snapshots) {
        const bool deviceChanged  = (mDeviceId != snap.deviceId || mDeviceName != snap.deviceName);
        const bool profileChanged = (mActiveIndex != snap.activeIdx || mActiveProfile != snap.activeProfile);

        mDeviceId      = snap.deviceId;
        mDeviceName    = snap.deviceName;
        mActiveIndex   = snap.activeIdx;
        mActiveProfile = snap.activeProfile;
        mModel->setProfiles(snap.profiles);

        if (deviceChanged)
            emit deviceInfoChanged();
        if (profileChanged)
            emit activeProfileChanged();
    }

    mTimer->start(mPollIntervalMs);
}
