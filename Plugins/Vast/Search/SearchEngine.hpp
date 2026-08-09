#pragma once

#include "SearchResult.hpp"
#include "LaunchHistoryStore.hpp"

#include <qcontainerfwd.h>
#include <qjsengine.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
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
        Q_PROPERTY(double appThreshold READ appThreshold WRITE setAppThreshold NOTIFY appThresholdChanged)
        Q_PROPERTY(double fileThreshold READ fileThreshold WRITE setFileThreshold NOTIFY fileThresholdChanged)

      public:
        static SearchEngine* create(QQmlEngine* /*unused*/, QJSEngine* /*unused*/) {
            auto* inst = new SearchEngine();
            QQmlEngine::setObjectOwnership(inst, QQmlEngine::CppOwnership);
            return inst;
        }

        [[nodiscard]] Q_INVOKABLE QVariantList        searchApps(const QVariantList& apps, const QString& query) const;
        [[nodiscard]] Q_INVOKABLE QVariantList        searchFiles(const QVariantList& files, const QString& query) const;

        Q_INVOKABLE void                              recordLaunch(const QString& appId);
        [[nodiscard]] Q_INVOKABLE double              recencyScore(const QString& appId) const;
        Q_INVOKABLE void                              clearHistory();

        [[nodiscard]] static Q_INVOKABLE QString      highlightedHtml(const QString& text, const QString& query, const QString& color);
        [[nodiscard]] static Q_INVOKABLE QVariantList highlightRanges(const QString& text, const QString& query);
        [[nodiscard]] static Q_INVOKABLE double       score(const QString& query, const QString& text);

        [[nodiscard]] int                             historyLimit() const {
            return mHistory->historyLimit();
        }
        [[nodiscard]] double appThreshold() const {
            return mAppThreshold;
        }
        [[nodiscard]] double fileThreshold() const {
            return mFileThreshold;
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
        void filesReady(QVariantList results);
        void fileSearchStarted();

        void historyLimitChanged();
        void appThresholdChanged();
        void fileThresholdChanged();

      private:
        explicit SearchEngine(QObject* parent = nullptr);

        LaunchHistoryStore* mHistory       = nullptr;
        double              mAppThreshold  = 0.35;
        double              mFileThreshold = 0.40;
    };
}
