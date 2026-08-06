#pragma once

#include "SearchResult.hpp"

#include <qcontainerfwd.h>
#include <qjsengine.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qsettings.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qnumeric.h>

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
        return mHistoryLimit;
    }
    [[nodiscard]] double appThreshold() const {
        return mAppThreshold;
    }
    [[nodiscard]] double fileThreshold() const {
        return mFileThreshold;
    }

    void setHistoryLimit(int v) {
        if (mHistoryLimit != v) {
            mHistoryLimit = v;
            emit historyLimitChanged();
        }
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

    void loadHistory();
    void saveHistory();

    struct HistoryEntry {
        QString id;
        qint64  timestamp = 0;
        int     count     = 0;
    };

    static double        scoreApp(QObject* entry, const QStringList& normQueryWords, const QString& normQuery);

    QSettings*           mSettings = nullptr;

    QList<SearchResult*> mFileResults;
    QList<HistoryEntry>  mHistory;
    int                  mHistoryLimit  = 50;
    double               mAppThreshold  = 0.35;
    double               mFileThreshold = 0.40;
};
