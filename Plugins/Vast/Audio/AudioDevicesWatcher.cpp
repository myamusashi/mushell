#include "AudioDevicesWatcher.hpp"
#include "AudioDevicesModel.hpp"

#include <mutex>
#include <qdebug.h>
#include <qjsengine.h>
#include <qobject.h>
#include <qlogging.h>
#include <qlist.h>
#include <qhashfunctions.h>
#include <qqmlengine.h>
#include <qtimer.h>
#include <qtmetamacros.h>
#include <qtypes.h>

#include <cstdint>
#include <array>
#include <cstdio>
#include <exception>
#include <algorithm>
#include <cstring>
#include <memory>
#include <spa/utils/dict.h>
#include <spa/utils/hook.h>
#include <span>
#include <stdexcept>
#include <string>
#include <string_view>
#include <vector>

extern "C" {
#include <pipewire/pipewire.h>
#include <pipewire/extensions/metadata.h>
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
    struct PwMetadataDeleter {
        void operator()(pw_metadata* p) const {
            pw_proxy_destroy(reinterpret_cast<pw_proxy*>(p));
        }
    };

    using UniquePwThreadLoop = std::unique_ptr<pw_thread_loop, PwThreadLoopDeleter>;
    using UniquePwContext    = std::unique_ptr<pw_context, PwContextDeleter>;
    using UniquePwCore       = std::unique_ptr<pw_core, PwCoreDeleter>;
    using UniquePwRegistry   = std::unique_ptr<pw_registry, PwRegistryDeleter>;
    using UniquePwMetadata   = std::unique_ptr<pw_metadata, PwMetadataDeleter>;

    constexpr int K_MAX_STR = 256;

    struct AdNodeT {
        pw_proxy*                   proxy = nullptr;
        spa_hook                    nodeListener{};
        spa_hook                    proxyListener{};

        uint32_t                    pwId = 0;
        std::array<char, K_MAX_STR> name{};
        std::array<char, K_MAX_STR> description{};
        std::array<char, 32>        mediaClass{};
        std::array<char, 16>        state{};

        int                         dirty = 0;
    };

    void        adRegistryEventGlobal(void* data, uint32_t id, uint32_t permissions, const char* type, uint32_t version, const spa_dict* props);
    void        adRegistryEventGlobalRemove(void* data, uint32_t id);
    void        adNodeEventInfo(void* data, const pw_node_info* info);
    void        adOnProxyDestroy(void* data);

    const char* adSafeLookup(const spa_dict* dict, const char* key) {
        if (!dict)
            return "";
        const char* v = spa_dict_lookup(dict, key);
        return v ? v : "";
    }

    template <std::size_t N>
    void adSafeCopy(std::array<char, N>& dst, const char* src) {
        if (!src) {
            dst[0] = '\0';
            return;
        }
        std::snprintf(dst.data(), N, "%s", src);
    }

    const char* adStateToString(pw_node_state state) {
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
        PwApp(PwApp&&)                 = delete;
        PwApp& operator=(PwApp&&)      = delete;

        PwApp() {
            static std::once_flag sInit;
            std::call_once(sInit, [] {
                int argc = 0;
                pw_init(&argc, nullptr);
            });

            mLoop.reset(pw_thread_loop_new("pw-devices", nullptr));
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
            std::ranges::for_each(mNodes, [](AdNodeT* n) { pw_proxy_destroy(n->proxy); });
            mNodes.clear();
            spa_hook_remove(&mRegistryListener);
        }

        [[nodiscard]] pw_thread_loop* loop() const {
            return mLoop.get();
        }
        [[nodiscard]] pw_registry* registry() const {
            return mRegistry.get();
        }
        [[nodiscard]] pw_metadata* metadata() const {
            return mMetadata.get();
        }

        // Takes ownership of a freshly-bound "default" metadata proxy from
        // adRegistryEventGlobal. No-op if we already have one (registry can
        // in principle announce it again on reconnect handling elsewhere).
        void bindMetadata(pw_metadata* proxy) {
            mMetadata.reset(proxy);
        }

        void setDefaultSink(std::string_view nodeName) {
            setDefaultNode("default.configured.audio.sink", nodeName);
        }

        void setDefaultSource(std::string_view nodeName) {
            setDefaultNode("default.configured.audio.source", nodeName);
        }

        std::vector<AdNodeT*>           mNodes;
        spa_hook                        mRegistryListener{};
        bool                            mTopologyChanged = true;

        static const pw_registry_events S_REGISTRY_EVENTS;
        static const pw_node_events     S_NODE_EVENTS;
        static const pw_proxy_events    S_PROXY_EVENTS;

      private:
        void setDefaultNode(const char* key, std::string_view nodeName) {
            if (!mMetadata)
                return;

            // PipeWire/wireplumber metadata value: JSON object with the node's
            // node.name string (NOT the numeric node id used elsewhere).
            std::string value = R"({"name":")";
            value.append(nodeName);
            value += "\"}";

            pw_metadata_set_property(mMetadata.get(), PW_ID_CORE, key, "Spa:String:JSON", value.c_str());
        }

        UniquePwThreadLoop mLoop;
        UniquePwContext    mContext;
        UniquePwCore       mCore;
        UniquePwRegistry   mRegistry;
        UniquePwMetadata   mMetadata;
    };

    void adNodeEventInfo(void* data, const pw_node_info* info) {
        auto* n = static_cast<AdNodeT*>(data);

        if (info->props) {
            const char* name = adSafeLookup(info->props, PW_KEY_NODE_NAME);
            if (*name)
                adSafeCopy(n->name, name);

            const char* desc = adSafeLookup(info->props, PW_KEY_NODE_DESCRIPTION);
            if (!*desc)
                desc = adSafeLookup(info->props, PW_KEY_NODE_NICK);
            if (*desc)
                adSafeCopy(n->description, desc);

            const char* mclass = adSafeLookup(info->props, PW_KEY_MEDIA_CLASS);
            if (*mclass)
                adSafeCopy(n->mediaClass, mclass);
        }

        adSafeCopy(n->state, adStateToString(info->state));
        n->dirty = 1;
    }

    void adOnProxyDestroy(void* data) {
        auto* n = static_cast<AdNodeT*>(data);
        spa_hook_remove(&n->nodeListener);
        spa_hook_remove(&n->proxyListener);
        delete n;
    }

    void adRegistryEventGlobal(void* data, uint32_t id, uint32_t /*permissions*/, const char* type, uint32_t /*version*/, const spa_dict* props) {
        auto* app = static_cast<PwApp*>(data);

        if (strcmp(type, PW_TYPE_INTERFACE_Metadata) == 0) {
            if (app->metadata())
                return; // already bound

            const char* name = adSafeLookup(props, PW_KEY_METADATA_NAME);
            if (strcmp(name, "default") != 0)
                return;

            auto* proxy = static_cast<pw_metadata*>(pw_registry_bind(app->registry(), id, PW_TYPE_INTERFACE_Metadata, PW_VERSION_METADATA, 0));
            if (proxy)
                app->bindMetadata(proxy);
            return;
        }

        if (strcmp(type, PW_TYPE_INTERFACE_Node) != 0)
            return;

        const char*            mediaClassStr = adSafeLookup(props, PW_KEY_MEDIA_CLASS);
        const std::string_view mediaClass(mediaClassStr);
        if (!mediaClass.starts_with("Audio/Sink") && !mediaClass.starts_with("Audio/Source"))
            return;

        auto* n = new AdNodeT();
        n->pwId = id;
        adSafeCopy(n->mediaClass, mediaClassStr);
        adSafeCopy(n->state, "creating");

        const char* name = adSafeLookup(props, PW_KEY_NODE_NAME);
        if (*name)
            adSafeCopy(n->name, name);

        const char* desc = adSafeLookup(props, PW_KEY_NODE_DESCRIPTION);
        if (!*desc)
            desc = adSafeLookup(props, PW_KEY_NODE_NICK);
        if (*desc)
            adSafeCopy(n->description, desc);

        n->dirty = 1;

        n->proxy = static_cast<pw_proxy*>(pw_registry_bind(app->registry(), id, PW_TYPE_INTERFACE_Node, PW_VERSION_NODE, 0));
        if (!n->proxy) {
            delete n;
            return;
        }

        pw_proxy_add_object_listener(n->proxy, &n->nodeListener, &PwApp::S_NODE_EVENTS, n);
        pw_proxy_add_listener(n->proxy, &n->proxyListener, &PwApp::S_PROXY_EVENTS, n);
        app->mNodes.push_back(n);
        app->mTopologyChanged = true;
    }

    void adRegistryEventGlobalRemove(void* data, uint32_t id) {
        auto* app = static_cast<PwApp*>(data);

        auto  it = std::ranges::find_if(app->mNodes, [id](const AdNodeT* n) { return n->pwId == id; });
        if (it == app->mNodes.end())
            return;

        AdNodeT* n = *it;
        app->mNodes.erase(it);
        app->mTopologyChanged = true;
        pw_proxy_destroy(n->proxy);
    }

    const pw_registry_events PwApp::S_REGISTRY_EVENTS = {
        .version       = PW_VERSION_REGISTRY_EVENTS,
        .global        = adRegistryEventGlobal,
        .global_remove = adRegistryEventGlobalRemove,
    };
    const pw_node_events PwApp::S_NODE_EVENTS = {
        .version = PW_VERSION_NODE_EVENTS,
        .info    = adNodeEventInfo,
        .param   = nullptr,
    };
    const pw_proxy_events PwApp::S_PROXY_EVENTS = {
        .version     = PW_VERSION_PROXY_EVENTS,
        .destroy     = adOnProxyDestroy,
        .bound       = nullptr,
        .removed     = nullptr,
        .done        = nullptr,
        .error       = nullptr,
        .bound_props = nullptr,
    };

    // Returns true if anything changed since the last poll (node added/removed/updated),
    // and clears all dirty flags as a side effect.
    bool adConsumeDirty(PwApp& app) {
        bool any             = app.mTopologyChanged;
        app.mTopologyChanged = false;
        for (AdNodeT* n : app.mNodes) {
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

AudioDevicesWatcher* AudioDevicesWatcher::create(QQmlEngine* /*unused*/, QJSEngine* /*unused*/) {
    static AudioDevicesWatcher sInstance;
    return &sInstance;
}

AudioDevicesWatcher::AudioDevicesWatcher(QObject* parent) : QObject(parent), mModel(new AudioDevicesModel(this)), mTimer(new QTimer(this)), mPw(std::make_unique<PwState>()) {
    try {
        mPw->app   = std::make_unique<PwApp>();
        mConnected = true;
        emit connectedChanged();
    } catch (const std::exception& e) { qWarning("AudioDevicesWatcher: failed to connect to PipeWire: %s", e.what()); }

    mTimer->setSingleShot(true);
    connect(mTimer, &QTimer::timeout, this, &AudioDevicesWatcher::poll);
    if (mConnected)
        mTimer->start(K_MIN_POLL_MS);
}

AudioDevicesWatcher::~AudioDevicesWatcher() {
    mTimer->stop();
}

void AudioDevicesWatcher::poll() {
    if (!mPw->app)
        return;

    PwApp*             app = mPw->app.get();

    QList<DeviceEntry> snapshot;
    bool               changed = false;

    pw_thread_loop_lock(app->loop());
    changed = adConsumeDirty(*app);
    if (changed) {
        snapshot.reserve(static_cast<qsizetype>(app->mNodes.size()) * 2);
        for (const AdNodeT* n : app->mNodes) {
            const QString          name  = QString::fromUtf8(n->name.data());
            const QString          desc  = QString::fromUtf8(n->description.data());
            const QString          state = QString::fromUtf8(n->state.data());
            const std::string_view mediaClass(n->mediaClass.data());

            if (mediaClass.starts_with("Audio/Sink")) {
                snapshot.append(
                    DeviceEntry{.id = n->pwId, .name = name, .description = desc, .mediaClass = QStringLiteral("sink"), .state = state, .isMonitor = false, .monitorOf = {}});
                // PipeWire doesn't expose monitor sources as separate graph nodes —
                // pactl/pipewire-pulse synthesizes them per sink, so we do the same here.
                snapshot.append(DeviceEntry{
                    .id          = n->pwId,
                    .name        = name + QStringLiteral(".monitor"),
                    .description = QStringLiteral("Monitor of ") + desc,
                    .mediaClass  = QStringLiteral("source"),
                    .state       = state,
                    .isMonitor   = true,
                    .monitorOf   = name,
                });
            } else if (mediaClass.starts_with("Audio/Source")) {
                snapshot.append(
                    DeviceEntry{.id = n->pwId, .name = name, .description = desc, .mediaClass = QStringLiteral("source"), .state = state, .isMonitor = false, .monitorOf = {}});
            }
        }
    }
    pw_thread_loop_unlock(app->loop());

    if (!changed) {
        mPollIntervalMs = std::min(mPollIntervalMs * 2, K_MAX_POLL_MS);
        mTimer->start(mPollIntervalMs);
        return;
    }

    mPollIntervalMs = K_MIN_POLL_MS;
    mModel->setDevices(snapshot);
    emit devicesChanged();

    mTimer->start(mPollIntervalMs);
}

void AudioDevicesWatcher::setDefaultSink(const QString& nodeName) {
    if (!mPw->app)
        return;

    PwApp* app = mPw->app.get();
    pw_thread_loop_lock(app->loop());
    app->setDefaultSink(nodeName.toStdString());
    pw_thread_loop_unlock(app->loop());
}

void AudioDevicesWatcher::setDefaultSource(const QString& nodeName) {
    if (!mPw->app)
        return;

    PwApp* app = mPw->app.get();
    pw_thread_loop_lock(app->loop());
    app->setDefaultSource(nodeName.toStdString());
    pw_thread_loop_unlock(app->loop());
}
