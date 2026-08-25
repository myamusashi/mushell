#include "JobExecutor.hpp"

#include <qobjectdefs.h>

namespace vast {

    JobExecutor& JobExecutor::instance() {
        static JobExecutor executor;
        return executor;
    }

    JobExecutor::JobExecutor() {
        mWorker.moveToThread(&mThread);
        mThread.start();
    }

    JobExecutor::~JobExecutor() {
        mThread.quit();
        mThread.wait();
    }

    void JobExecutor::post(std::function<void()> job) {
        QMetaObject::invokeMethod(&mWorker, std::move(job), Qt::QueuedConnection);
    }

    QThread* JobExecutor::thread() noexcept {
        return &mThread;
    }

} // namespace vast
