#pragma once

#include <qobject.h>
#include <qthread.h>

#include <functional>

namespace vast {

    /// Jobs run strictly serialized on that single thread, so heavy work
    /// (image decode, palette building, fuzzy scoring, sysfs/ddc writes,
    /// Wayland dispatch) stays off the UI thread while the process as a whole
    /// never spawns more than this one worker. Objects that need an event
    /// loop off the main thread (e.g. WaylandDataControl's socket notifier and
    /// reconnect timers) are moved onto it with moveToThread(instance().thread()).
    ///
    /// Results must hop back with QMetaObject::invokeMethod(contextObject, ...,
    /// Qt::QueuedConnection): if the context object dies before delivery the
    /// queued call is discarded instead of touching freed memory. Job bodies
    /// should therefore only touch captured locals or state owned by objects
    /// that outlive them (shared_ptr members), never raw `this` members of a
    /// possibly-shorter-lived object.
    class JobExecutor final : public QObject {
        Q_OBJECT

      public:
        static JobExecutor& instance();

        /// Queues job onto the worker thread. Never blocks the calling thread.
        void post(std::function<void()> job);

        /// Thread affinity for objects that live on the worker thread.
        [[nodiscard]] QThread* thread() noexcept;

        JobExecutor(const JobExecutor&)            = delete;
        JobExecutor& operator=(const JobExecutor&) = delete;
        JobExecutor(JobExecutor&&)                 = delete;
        JobExecutor& operator=(JobExecutor&&)      = delete;

      private:
        JobExecutor();
        ~JobExecutor() override;

        QObject mWorker; // invocation target; lives on mThread
        QThread mThread; // event-loop worker
    };

} // namespace vast
