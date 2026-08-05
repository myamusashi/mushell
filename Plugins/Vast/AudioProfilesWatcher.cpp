#include "AudioProfilesWatcher.hpp"

#include <qdebug.h>
#include <qqmlengine.h>
#include <qstringlist.h>

#include <algorithm>
#include <memory>
#include <mutex>
#include <span>
#include <stdexcept>
#include <string_view>
#include <vector>

extern "C" {
#include <pipewire/pipewire.h>
#include <spa/param/profile.h>
#include <spa/pod/iter.h>
#include <spa/pod/parser.h>
#include <spa/utils/result.h>
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

constexpr int kMaxProfiles = 64;
constexpr int kMaxStr      = 256;

struct ap_profile_entry_t {
    int32_t                   index;
    std::array<char, kMaxStr> name{};
    std::array<char, kMaxStr> description{};
    std::array<char, 32>      available{};
};

struct ap_device_node_t {
    pw_proxy*                                    proxy = nullptr;
    spa_hook                                     device_listener{};
    spa_hook                                     proxy_listener{};

    uint32_t                                     pw_id = 0;
    std::array<char, kMaxStr>                    name{};

    std::array<ap_profile_entry_t, kMaxProfiles> profiles{};
    int                                          profile_count = 0;

    std::array<ap_profile_entry_t, kMaxProfiles> staging{};
    int                                          staging_count = 0;
    int                                          enum_seq      = 0;

    int32_t                                      active_index = -1;
    std::array<char, kMaxStr>                    active_name{};
    std::array<char, kMaxStr>                    active_description{};
    std::array<char, 32>                         active_available{};

    int                                          dirty = 0;
};

static void        ap_registry_event_global(void* data, uint32_t id, uint32_t permissions, const char* type, uint32_t version, const spa_dict* props);
static void        ap_registry_event_global_remove(void* data, uint32_t id);
static void        ap_device_event_info(void* data, const pw_device_info* info);
static void        ap_device_event_param(void* data, int seq, uint32_t id, uint32_t index, uint32_t next, const spa_pod* param);
static void        ap_on_proxy_destroy(void* data);

static const char* ap_safe_lookup(const spa_dict* dict, const char* key) {
    if (!dict)
        return "";
    const char* v = spa_dict_lookup(dict, key);
    return v ? v : "";
}

template <std::size_t N>
static void ap_safe_copy(std::array<char, N>& dst, const char* src) {
    if (!src) {
        dst[0] = '\0';
        return;
    }
    std::snprintf(dst.data(), N, "%s", src);
}

static std::string_view ap_parse_availability(const spa_pod* val) {
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

    PwApp() {
        static std::once_flag s_init;
        std::call_once(s_init, [] {
            int argc = 0;
            pw_init(&argc, nullptr);
        });

        m_loop.reset(pw_thread_loop_new("pw-profiles", nullptr));
        if (!m_loop)
            throw std::runtime_error("pw_thread_loop_new failed");

        m_context.reset(pw_context_new(pw_thread_loop_get_loop(m_loop.get()), nullptr, 0));
        if (!m_context)
            throw std::runtime_error("pw_context_new failed");

        m_core.reset(pw_context_connect(m_context.get(), nullptr, 0));
        if (!m_core)
            throw std::runtime_error("pw_context_connect failed");

        m_registry.reset(pw_core_get_registry(m_core.get(), PW_VERSION_REGISTRY, 0));
        if (!m_registry)
            throw std::runtime_error("pw_core_get_registry failed");

        pw_registry_add_listener(m_registry.get(), &m_registry_listener, &s_registry_events, this);

        if (pw_thread_loop_start(m_loop.get()) < 0)
            throw std::runtime_error("pw_thread_loop_start failed");
    }

    ~PwApp() {
        pw_thread_loop_stop(m_loop.get());
        std::ranges::for_each(m_devices, [](ap_device_node_t* d) { pw_proxy_destroy(d->proxy); });
        m_devices.clear();
        spa_hook_remove(&m_registry_listener);
    }

    [[nodiscard]] pw_thread_loop* loop() const {
        return m_loop.get();
    }
    [[nodiscard]] pw_registry* registry() const {
        return m_registry.get();
    }

    std::vector<ap_device_node_t*>  m_devices;
    spa_hook                        m_registry_listener{};

    static const pw_registry_events s_registry_events;
    static const pw_device_events   s_device_events;
    static const pw_proxy_events    s_proxy_events;

  private:
    UniquePwThreadLoop m_loop;
    UniquePwContext    m_context;
    UniquePwCore       m_core;
    UniquePwRegistry   m_registry;
};

static void ap_device_event_info(void* data, const pw_device_info* info) {
    auto* d = static_cast<ap_device_node_t*>(data);

    if (info->props) {
        const char* n = ap_safe_lookup(info->props, PW_KEY_DEVICE_NAME);
        if (*n)
            ap_safe_copy(d->name, n);
    }

    if (info->change_mask & PW_DEVICE_CHANGE_MASK_PARAMS) {
        d->enum_seq      = pw_device_enum_params(reinterpret_cast<pw_device*>(d->proxy), 0, SPA_PARAM_EnumProfile, 0, UINT32_MAX, nullptr);
        d->staging_count = 0;
        pw_device_enum_params(reinterpret_cast<pw_device*>(d->proxy), 0, SPA_PARAM_Profile, 0, UINT32_MAX, nullptr);
    }
}

static void ap_device_event_param(void* data, int seq, uint32_t id, uint32_t /*index*/, uint32_t /*next*/, const spa_pod* param) {
    auto* d = static_cast<ap_device_node_t*>(data);

    if (id == SPA_PARAM_EnumProfile) {
        if (seq != d->enum_seq)
            return;

        if (!param || !spa_pod_is_object(param)) {
            if (d->staging_count > 0) {
                std::copy_n(d->staging.begin(), static_cast<size_t>(d->staging_count), d->profiles.begin());
                d->profile_count = d->staging_count;
                d->staging_count = 0;
                d->dirty         = 1;
            }
            return;
        }

        if (d->staging_count >= kMaxProfiles)
            return;

        int32_t          pidx  = -1;
        const char*      name  = nullptr;
        const char*      desc  = nullptr;
        std::string_view avail = "unknown";

        spa_pod_prop*    prop;
        SPA_POD_OBJECT_FOREACH(reinterpret_cast<const spa_pod_object*>(param), prop) {
            switch (prop->key) {
                case SPA_PARAM_PROFILE_index: spa_pod_get_int(&prop->value, &pidx); break;
                case SPA_PARAM_PROFILE_name: spa_pod_get_string(&prop->value, &name); break;
                case SPA_PARAM_PROFILE_description: spa_pod_get_string(&prop->value, &desc); break;
                case SPA_PARAM_PROFILE_available: avail = ap_parse_availability(&prop->value); break;
            }
        }

        auto& e = d->staging[d->staging_count++];
        e.index = pidx;
        ap_safe_copy(e.name, name ? name : "");
        ap_safe_copy(e.description, desc ? desc : "");
        ap_safe_copy(e.available, avail.data());

    } else if (id == SPA_PARAM_Profile) {
        if (!param || !spa_pod_is_object(param))
            return;

        if (d->staging_count > 0) {
            std::copy_n(d->staging.begin(), static_cast<size_t>(d->staging_count), d->profiles.begin());
            d->profile_count = d->staging_count;
            d->staging_count = 0;
        }

        int32_t          pidx  = -1;
        const char*      name  = nullptr;
        const char*      desc  = nullptr;
        std::string_view avail = "unknown";

        spa_pod_prop*    prop;
        SPA_POD_OBJECT_FOREACH(reinterpret_cast<const spa_pod_object*>(param), prop) {
            switch (prop->key) {
                case SPA_PARAM_PROFILE_index: spa_pod_get_int(&prop->value, &pidx); break;
                case SPA_PARAM_PROFILE_name: spa_pod_get_string(&prop->value, &name); break;
                case SPA_PARAM_PROFILE_description: spa_pod_get_string(&prop->value, &desc); break;
                case SPA_PARAM_PROFILE_available: avail = ap_parse_availability(&prop->value); break;
            }
        }

        d->active_index = pidx;
        ap_safe_copy(d->active_name, name ? name : "");
        ap_safe_copy(d->active_description, desc ? desc : "");
        ap_safe_copy(d->active_available, avail.data());
        d->dirty = 1;
    }
}

static void ap_on_proxy_destroy(void* data) {
    auto* d = static_cast<ap_device_node_t*>(data);
    spa_hook_remove(&d->device_listener);
    spa_hook_remove(&d->proxy_listener);
    delete d;
}

static void ap_registry_event_global(void* data, uint32_t id, uint32_t /*permissions*/, const char* type, uint32_t /*version*/, const spa_dict* props) {
    auto* app = static_cast<PwApp*>(data);

    if (strcmp(type, PW_TYPE_INTERFACE_Device) != 0)
        return;

    if (!std::string_view(ap_safe_lookup(props, PW_KEY_MEDIA_CLASS)).contains("Audio"))
        return;

    auto* d  = new ap_device_node_t();
    d->pw_id = id;
    ap_safe_copy(d->name, ap_safe_lookup(props, PW_KEY_DEVICE_NAME));

    d->proxy = static_cast<pw_proxy*>(pw_registry_bind(app->registry(), id, PW_TYPE_INTERFACE_Device, PW_VERSION_DEVICE, 0));
    if (!d->proxy) {
        delete d;
        return;
    }

    pw_proxy_add_object_listener(d->proxy, &d->device_listener, &PwApp::s_device_events, d);
    pw_proxy_add_listener(d->proxy, &d->proxy_listener, &PwApp::s_proxy_events, d);
    app->m_devices.push_back(d);
}

static void ap_registry_event_global_remove(void* data, uint32_t id) {
    auto* app = static_cast<PwApp*>(data);

    auto  it = std::ranges::find_if(app->m_devices, [id](const ap_device_node_t* d) { return d->pw_id == id; });

    if (it == app->m_devices.end())
        return;

    ap_device_node_t* d = *it;
    app->m_devices.erase(it);
    pw_proxy_destroy(d->proxy);
}

const pw_registry_events PwApp::s_registry_events = {
    .version       = PW_VERSION_REGISTRY_EVENTS,
    .global        = ap_registry_event_global,
    .global_remove = ap_registry_event_global_remove,
};
const pw_device_events PwApp::s_device_events = {
    .version = PW_VERSION_DEVICE_EVENTS,
    .info    = ap_device_event_info,
    .param   = ap_device_event_param,
};
const pw_proxy_events PwApp::s_proxy_events = {
    .version     = PW_VERSION_PROXY_EVENTS,
    .destroy     = ap_on_proxy_destroy,
    .bound       = nullptr,
    .removed     = nullptr,
    .done        = nullptr,
    .error       = nullptr,
    .bound_props = nullptr,
};

static ap_device_node_t* ap_drain_dirty(std::span<ap_device_node_t* const> devices) {
    auto it = std::ranges::find_if(devices, [](const ap_device_node_t* d) { return d->dirty && d->profile_count > 0; });
    if (it == devices.end())
        return nullptr;
    (*it)->dirty = 0;
    return *it;
}

struct AudioProfilesWatcher::PwState {
    std::unique_ptr<PwApp> app;
};

AudioProfilesWatcher* AudioProfilesWatcher::create(QQmlEngine*, QJSEngine*) {
    static AudioProfilesWatcher s_instance;
    return &s_instance;
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

AudioProfilesWatcher::AudioProfilesWatcher(QObject* parent) : QObject(parent), m_model(new AudioProfilesModel(this)), m_timer(new QTimer(this)), m_pw(std::make_unique<PwState>()) {
    try {
        m_pw->app   = std::make_unique<PwApp>();
        m_connected = true;
        emit connectedChanged();
    } catch (const std::exception& e) { qWarning("AudioProfilesWatcher: failed to connect to PipeWire: %s", e.what()); }

    m_timer->setSingleShot(true);
    connect(m_timer, &QTimer::timeout, this, &AudioProfilesWatcher::poll);
    if (m_connected)
        m_timer->start(kMinPollMs);
}

AudioProfilesWatcher::~AudioProfilesWatcher() {
    m_timer->stop();
}

void AudioProfilesWatcher::poll() {
    if (!m_pw->app)
        return;

    PwApp* app = m_pw->app.get();

    struct DeviceSnapshot {
        quint32             deviceId;
        QString             deviceName;
        qsizetype           activeIdx;
        QVariantMap         activeProfile;
        QList<ProfileEntry> profiles;
    };
    QList<DeviceSnapshot> snapshots;

    pw_thread_loop_lock(app->loop());
    while (ap_device_node_t* d = ap_drain_dirty(app->m_devices)) {
        const QString  actName = QString::fromUtf8(d->active_name.data());

        DeviceSnapshot snap;
        snap.deviceId      = d->pw_id;
        snap.deviceName    = QString::fromUtf8(d->name.data());
        snap.activeIdx     = d->active_index;
        snap.activeProfile = {
            {QStringLiteral("index"), d->active_index},
            {QStringLiteral("name"), actName},
            {QStringLiteral("description"), QString::fromUtf8(d->active_description.data())},
            {QStringLiteral("available"), QString::fromUtf8(d->active_available.data())},
            {QStringLiteral("readable"), formatProfileName(actName)},
        };

        snap.profiles.reserve(d->profile_count);
        for (const auto& e : std::span(d->profiles.data(), static_cast<size_t>(d->profile_count))) {
            const QString nm = QString::fromUtf8(e.name.data());
            snap.profiles.append(ProfileEntry{
                e.index,
                nm,
                QString::fromUtf8(e.description.data()),
                QString::fromUtf8(e.available.data()),
                formatProfileName(nm),
            });
        }
        snapshots.append(std::move(snap));
    }
    pw_thread_loop_unlock(app->loop());

    if (snapshots.isEmpty()) {
        // Nothing dirty — exponential backoff to reduce idle CPU
        m_pollIntervalMs = std::min(m_pollIntervalMs * 2, kMaxPollMs);
        m_timer->start(m_pollIntervalMs);
        return;
    }

    // Activity detected — reset to fast polling
    m_pollIntervalMs = kMinPollMs;

    for (const DeviceSnapshot& snap : snapshots) {
        const bool deviceChanged  = (m_deviceId != snap.deviceId || m_deviceName != snap.deviceName);
        const bool profileChanged = (m_activeIndex != snap.activeIdx || m_activeProfile != snap.activeProfile);

        m_deviceId      = snap.deviceId;
        m_deviceName    = snap.deviceName;
        m_activeIndex   = snap.activeIdx;
        m_activeProfile = snap.activeProfile;
        m_model->setProfiles(snap.profiles);

        if (deviceChanged)
            emit deviceInfoChanged();
        if (profileChanged)
            emit activeProfileChanged();
    }

    m_timer->start(m_pollIntervalMs);
}
