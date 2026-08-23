#pragma once

#include "../FuzzyMatcher.hpp"
#include "LaunchHistoryStore.hpp"
#include "FileSearchModel.hpp"

#include <qatomic.h>
#include <qcontainerfwd.h>
#include <qjsengine.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qset.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qnumeric.h>

namespace vast {

    class SearchEngine : public QObject {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON

        Q_PROPERTY(int historyLimit READ historyLimit WRITE setHistoryLimit NOTIFY historyLimitChanged)

        // Score floors on fzy's raw scale, expressed per query character: a
        // candidate must average at least this much per query char to be
        // listed (fzy scores grow with needle length, so absolute cutoffs
        // would be meaningless).
        Q_PROPERTY(double appThreshold READ appThreshold WRITE setAppThreshold NOTIFY appThresholdChanged)
        Q_PROPERTY(double fileThreshold READ fileThreshold WRITE setFileThreshold NOTIFY fileThresholdChanged)

        // Ranked results of the last searchFilesAsync call; identity never
        // changes, only its rows reset. C++-owned via parentage.
        Q_PROPERTY(QAbstractListModel* fileResults READ fileResults CONSTANT)

      public:
        static SearchEngine* create(QQmlEngine* /*unused*/, QJSEngine* /*unused*/) {
            auto* inst = new SearchEngine();
            QQmlEngine::setObjectOwnership(inst, QQmlEngine::CppOwnership);
            return inst;
        }

        [[nodiscard]] Q_INVOKABLE QVariantList   searchApps(const QVariantList& apps, const QString& query) const;
        Q_INVOKABLE void                         searchFilesAsync(const QVariantList& files, const QString& query);

        Q_INVOKABLE void                         recordLaunch(const QString& appId);
        [[nodiscard]] Q_INVOKABLE double         recencyScore(const QString& appId) const;
        Q_INVOKABLE void                         clearHistory();
        Q_INVOKABLE void                         clearFileResults();

        [[nodiscard]] static Q_INVOKABLE QString highlightedHtml(const QString& text, const QString& query, const QString& color);
        [[nodiscard]] static Q_INVOKABLE double  score(const QString& query, const QString& text);

        [[nodiscard]] int                        historyLimit() const {
            return mHistory->historyLimit();
        }
        [[nodiscard]] double appThreshold() const {
            return mAppThreshold;
        }
        [[nodiscard]] double fileThreshold() const {
            return mFileThreshold;
        }
        [[nodiscard]] QAbstractListModel* fileResults() const {
            return mFileResults;
        }

        void setHistoryLimit(int v) {
            mHistory->setHistoryLimit(v);
        }
        void setAppThreshold(double v) {
            if (!qFuzzyCompare(mAppThreshold, v)) {
                mAppThreshold = v;
                emit appThresholdChanged();
            }
        }
        void setFileThreshold(double v) {
            if (!qFuzzyCompare(mFileThreshold, v)) {
                mFileThreshold = v;
                emit fileThresholdChanged();
            }
        }

      signals:
        void fileSearchStarted();

        void historyLimitChanged();
        void appThresholdChanged();
        void fileThresholdChanged();

      private:
        explicit SearchEngine(QObject* parent = nullptr);

        LaunchHistoryStore* mHistory       = nullptr;
        double              mAppThreshold  = 0.45;
        double              mFileThreshold = 0.50;

        FileSearchModel*    mFileResults = nullptr;

        // Guards against stale async file-search deliveries; bumped on every
        // searchFilesAsync request.
        QAtomicInt mFileSearchGeneration{0};

        // Per-app normalization/encoding cache, keyed by desktop entry id.
        // App names/generic names/comments never change between keystrokes,
        // so their normalizeText walk and UTF-8 encoding are done once and
        // reused; the raw strings are kept so any app update invalidates
        // exactly its own entry. Main-thread only (searchApps is a
        // QML-invoked call).
        struct CachedField {
            QString                  raw;
            FuzzyMatcher::CachedText text{};
        };
        struct CachedApp {
            CachedField name{};
            CachedField genericName{};
            CachedField comment{};
        };
        mutable QHash<QString, CachedApp> mAppCache;

        [[nodiscard]] CachedApp           cachedAppFields(const QObject* entry) const;
        static void                       pruneAppCache(QHash<QString, CachedApp>& cache, const QSet<QString>& activeIds);
    };
}
