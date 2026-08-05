#include "AudioDevicesWatcher.hpp"

#include <qdebug.h>
#include <qqmlengine.h>

#include <algorithm>
#include <cstring>
#include <memory>
#include <mutex>
#include <span>
#include <stdexcept>
#include <string_view>
#include <vector>

extern "C" {
#include <pipewire/pipewire.h>
}

namespace {

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

    constexpr int kMaxStr = 256;

    struct ad_node_t {
        pw_proxy*                 proxy = nullptr;
        spa_hook                  node_listener{};
        spa_hook                  proxy_listener{};

        uint32_t                  pw_id = 0;
        std::array<char, kMaxStr> name{};
        std::array<char, kMaxStr> description{};
        std::array<char, 32>      media_class{};
        std::array<char, 16>      state{};

        int                       dirty = 0;
    };

    void        ad_registry_event_global(void* data, uint32_t id, uint32_t permissions, const char* type, uint32_t version, const spa_dict* props);
    void        ad_registry_event_global_remove(void* data, uint32_t id);
    void        ad_node_event_info(void* data, const pw_node_info* info);
    void        ad_on_proxy_destroy(void* data);

    const char* ad_safe_lookup(const spa_dict* dict, const char* key) {
        if (!dict)
            return "";
        const char* v = spa_dict_lookup(dict, key);
        return v ? v : "";
    }

    template <std::size_t N>
    void ad_safe_copy(std::array<char, N>& dst, const char* src) {
        if (!src) {
            dst[0] = '\0';
            return;
        }
        std::snprintf(dst.data(), N, "%s", src);
    }

    const char* ad_state_to_string(pw_node_state state) {
        switch (state) {
            case PW_NODE_STATE_ERROR: return "error";
            case PW_NODE_STATE_CREATING: return "creating";
            case PW_NODE_STATE_SUSPENDED: return "suspended";
            case PW_NODE_STATE_IDLE: return "idle";
            case PW_NODE_STATE_RUNNING: return "running";
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

            m_loop.reset(pw_thread_loop_new("pw-devices", nullptr));
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
            std::ranges::for_each(m_nodes, [](ad_node_t* n) { pw_proxy_destroy(n->proxy); });
            m_nodes.clear();
            spa_hook_remove(&m_registry_listener);
        }

        [[nodiscard]] pw_thread_loop* loop() const {
            return m_loop.get();
        }
        [[nodiscard]] pw_registry* registry() const {
            return m_registry.get();
        }

        std::vector<ad_node_t*>         m_nodes;
        spa_hook                        m_registry_listener{};
        bool                            m_topologyChanged = true;

        static const pw_registry_events s_registry_events;
        static const pw_node_events     s_node_events;
        static const pw_proxy_events    s_proxy_events;

      private:
        UniquePwThreadLoop m_loop;
        UniquePwContext    m_context;
        UniquePwCore       m_core;
        UniquePwRegistry   m_registry;
    };

    void ad_node_event_info(void* data, const pw_node_info* info) {
        auto* n = static_cast<ad_node_t*>(data);

        if (info->props) {
            const char* name = ad_safe_lookup(info->props, PW_KEY_NODE_NAME);
            if (*name)
                ad_safe_copy(n->name, name);

            const char* desc = ad_safe_lookup(info->props, PW_KEY_NODE_DESCRIPTION);
            if (!*desc)
                desc = ad_safe_lookup(info->props, PW_KEY_NODE_NICK);
            if (*desc)
                ad_safe_copy(n->description, desc);

            const char* mclass = ad_safe_lookup(info->props, PW_KEY_MEDIA_CLASS);
            if (*mclass)
                ad_safe_copy(n->media_class, mclass);
        }

        ad_safe_copy(n->state, ad_state_to_string(info->state));
        n->dirty = 1;
    }

    void ad_on_proxy_destroy(void* data) {
        auto* n = static_cast<ad_node_t*>(data);
        spa_hook_remove(&n->node_listener);
        spa_hook_remove(&n->proxy_listener);
        delete n;
    }

    void ad_registry_event_global(void* data, uint32_t id, uint32_t /*permissions*/, const char* type, uint32_t /*version*/, const spa_dict* props) {
        auto* app = static_cast<PwApp*>(data);

        if (strcmp(type, PW_TYPE_INTERFACE_Node) != 0)
            return;

        const char*            mediaClassStr = ad_safe_lookup(props, PW_KEY_MEDIA_CLASS);
        const std::string_view mediaClass(mediaClassStr);
        if (!mediaClass.starts_with("Audio/Sink") && !mediaClass.starts_with("Audio/Source"))
            return;

        auto* n  = new ad_node_t();
        n->pw_id = id;
        ad_safe_copy(n->media_class, mediaClassStr);
        ad_safe_copy(n->state, "creating");

        const char* name = ad_safe_lookup(props, PW_KEY_NODE_NAME);
        if (*name)
            ad_safe_copy(n->name, name);

        const char* desc = ad_safe_lookup(props, PW_KEY_NODE_DESCRIPTION);
        if (!*desc)
            desc = ad_safe_lookup(props, PW_KEY_NODE_NICK);
        if (*desc)
            ad_safe_copy(n->description, desc);

        n->dirty = 1;

        n->proxy = static_cast<pw_proxy*>(pw_registry_bind(app->registry(), id, PW_TYPE_INTERFACE_Node, PW_VERSION_NODE, 0));
        if (!n->proxy) {
            delete n;
            return;
        }

        pw_proxy_add_object_listener(n->proxy, &n->node_listener, &PwApp::s_node_events, n);
        pw_proxy_add_listener(n->proxy, &n->proxy_listener, &PwApp::s_proxy_events, n);
        app->m_nodes.push_back(n);
        app->m_topologyChanged = true;
    }

    void ad_registry_event_global_remove(void* data, uint32_t id) {
        auto* app = static_cast<PwApp*>(data);

        auto  it = std::ranges::find_if(app->m_nodes, [id](const ad_node_t* n) { return n->pw_id == id; });
        if (it == app->m_nodes.end())
            return;

        ad_node_t* n = *it;
        app->m_nodes.erase(it);
        app->m_topologyChanged = true;
        pw_proxy_destroy(n->proxy);
    }

    const pw_registry_events PwApp::s_registry_events = {
        .version       = PW_VERSION_REGISTRY_EVENTS,
        .global        = ad_registry_event_global,
        .global_remove = ad_registry_event_global_remove,
    };
    const pw_node_events PwApp::s_node_events = {
        .version = PW_VERSION_NODE_EVENTS,
        .info    = ad_node_event_info,
        .param   = nullptr,
    };
    const pw_proxy_events PwApp::s_proxy_events = {
        .version     = PW_VERSION_PROXY_EVENTS,
        .destroy     = ad_on_proxy_destroy,
        .bound       = nullptr,
        .removed     = nullptr,
        .done        = nullptr,
        .error       = nullptr,
        .bound_props = nullptr,
    };

    // Returns true if anything changed since the last poll (node added/removed/updated),
    // and clears all dirty flags as a side effect.
    bool ad_consume_dirty(PwApp& app) {
        bool any              = app.m_topologyChanged;
        app.m_topologyChanged = false;
        for (ad_node_t* n : app.m_nodes) {
            if (n->dirty) {
                any      = true;
                n->dirty = 0;
            }
        }
        return any;
    }

} // namespace

struct AudioDevicesWatcher::PwState {
    std::unique_ptr<PwApp> app;
};

AudioDevicesWatcher* AudioDevicesWatcher::create(QQmlEngine*, QJSEngine*) {
    static AudioDevicesWatcher s_instance;
    return &s_instance;
}

AudioDevicesWatcher::AudioDevicesWatcher(QObject* parent) : QObject(parent), m_model(new AudioDevicesModel(this)), m_timer(new QTimer(this)), m_pw(std::make_unique<PwState>()) {
    try {
        m_pw->app   = std::make_unique<PwApp>();
        m_connected = true;
        emit connectedChanged();
    } catch (const std::exception& e) { qWarning("AudioDevicesWatcher: failed to connect to PipeWire: %s", e.what()); }

    m_timer->setSingleShot(true);
    connect(m_timer, &QTimer::timeout, this, &AudioDevicesWatcher::poll);
    if (m_connected)
        m_timer->start(kMinPollMs);
}

AudioDevicesWatcher::~AudioDevicesWatcher() {
    m_timer->stop();
}

void AudioDevicesWatcher::poll() {
    if (!m_pw->app)
        return;

    PwApp*             app = m_pw->app.get();

    QList<DeviceEntry> snapshot;
    bool               changed;

    pw_thread_loop_lock(app->loop());
    changed = ad_consume_dirty(*app);
    if (changed) {
        snapshot.reserve(static_cast<qsizetype>(app->m_nodes.size()) * 2);
        for (const ad_node_t* n : app->m_nodes) {
            const QString          name  = QString::fromUtf8(n->name.data());
            const QString          desc  = QString::fromUtf8(n->description.data());
            const QString          state = QString::fromUtf8(n->state.data());
            const std::string_view mediaClass(n->media_class.data());

            if (mediaClass.starts_with("Audio/Sink")) {
                snapshot.append(DeviceEntry{n->pw_id, name, desc, QStringLiteral("sink"), state, false, {}});
                // PipeWire doesn't expose monitor sources as separate graph nodes —
                // pactl/pipewire-pulse synthesizes them per sink, so we do the same here.
                snapshot.append(DeviceEntry{
                    n->pw_id,
                    name + QStringLiteral(".monitor"),
                    QStringLiteral("Monitor of ") + desc,
                    QStringLiteral("source"),
                    state,
                    true,
                    name,
                });
            } else if (mediaClass.starts_with("Audio/Source")) {
                snapshot.append(DeviceEntry{n->pw_id, name, desc, QStringLiteral("source"), state, false, {}});
            }
        }
    }
    pw_thread_loop_unlock(app->loop());

    if (!changed) {
        // Nothing dirty — exponential backoff to reduce idle CPU
        m_pollIntervalMs = std::min(m_pollIntervalMs * 2, kMaxPollMs);
        m_timer->start(m_pollIntervalMs);
        return;
    }

    // Activity detected — reset to fast polling
    m_pollIntervalMs = kMinPollMs;
    m_model->setDevices(snapshot);
    emit devicesChanged();

    m_timer->start(m_pollIntervalMs);
}
