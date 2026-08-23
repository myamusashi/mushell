#pragma once

#include <qatomic.h>
#include <qcontainerfwd.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtmetamacros.h>

namespace vast {

    class DirectoryWalker : public QObject {
        Q_OBJECT
        QML_ELEMENT

        Q_PROPERTY(QStringList roots READ roots WRITE setRoots NOTIFY rootsChanged)
        Q_PROPERTY(int maxDepth READ maxDepth WRITE setMaxDepth NOTIFY maxDepthChanged)
        Q_PROPERTY(bool showHidden READ showHidden WRITE setShowHidden NOTIFY showHiddenChanged)
        Q_PROPERTY(QStringList nameFilters READ nameFilters WRITE setNameFilters NOTIFY nameFiltersChanged)
        Q_PROPERTY(bool walking READ walking NOTIFY walkingChanged)

      public:
        explicit DirectoryWalker(QObject* parent = nullptr);

        [[nodiscard]] const QStringList& roots() const {
            return mRoots;
        }
        [[nodiscard]] int maxDepth() const {
            return mMaxDepth;
        }
        [[nodiscard]] bool showHidden() const {
            return mShowHidden;
        }
        [[nodiscard]] const QStringList& nameFilters() const {
            return mNameFilters;
        }
        [[nodiscard]] bool walking() const {
            return mWalking;
        }

        void setRoots(QStringList v) {
            if (mRoots == v)
                return;
            mRoots = std::move(v);
            emit rootsChanged();
        }
        void setMaxDepth(int v) {
            if (mMaxDepth == v)
                return;
            mMaxDepth = v;
            emit maxDepthChanged();
        }
        void setShowHidden(bool v) {
            if (mShowHidden == v)
                return;
            mShowHidden = v;
            emit showHiddenChanged();
        }
        void setNameFilters(QStringList v) {
            if (mNameFilters == v)
                return;
            mNameFilters = std::move(v);
            emit nameFiltersChanged();
        }

        // Walks all roots asynchronously; delivers exactly one walkFinished
        // per request unless superseded by a newer one.
        Q_INVOKABLE void requestWalk();

      signals:
        void walkFinished(QVariantList entries);

        void rootsChanged();
        void maxDepthChanged();
        void showHiddenChanged();
        void nameFiltersChanged();
        void walkingChanged();

      private:
        void        setWalking(bool v);

        QStringList mRoots;
        QStringList mNameFilters;
        int         mMaxDepth   = 3;
        bool        mShowHidden = false;
        bool        mWalking    = false;
        QAtomicInt  mGeneration{0};
    };
}
