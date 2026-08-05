#pragma once

#include "SearchResult.hpp"

#include <qhash.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qsettings.h>
#include <qstring.h>
#include <qvariantlist.h>
#include <qnumeric.h>

class SearchEngine : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(int historyLimit READ historyLimit WRITE setHistoryLimit NOTIFY historyLimitChanged)
    Q_PROPERTY(double appThreshold READ appThreshold WRITE setAppThreshold NOTIFY appThresholdChanged)
    Q_PROPERTY(double fileThreshold READ fileThreshold WRITE setFileThreshold NOTIFY fileThresholdChanged)

  public:
    static SearchEngine* create(QQmlEngine*, QJSEngine*) {
        auto* inst = new SearchEngine();
        QQmlEngine::setObjectOwnership(inst, QQmlEngine::CppOwnership);
        return inst;
    }

    [[nodiscard]] Q_INVOKABLE QVariantList searchApps(const QVariantList& apps, const QString& query) const;
    [[nodiscard]] Q_INVOKABLE QVariantList searchFiles(const QVariantList& files, const QString& query) const;

    Q_INVOKABLE void                       recordLaunch(const QString& appId);
    [[nodiscard]] Q_INVOKABLE double       recencyScore(const QString& appId) const;
    Q_INVOKABLE void                       clearHistory();

    [[nodiscard]] Q_INVOKABLE QString      highlightedHtml(const QString& text, const QString& query, const QString& color) const;
    [[nodiscard]] Q_INVOKABLE QVariantList highlightRanges(const QString& text, const QString& query) const;
    [[nodiscard]] Q_INVOKABLE double       score(const QString& query, const QString& text) const;

    [[nodiscard]] int                      historyLimit() const {
        return m_historyLimit;
    }
    [[nodiscard]] double appThreshold() const {
        return m_appThreshold;
    }
    [[nodiscard]] double fileThreshold() const {
        return m_fileThreshold;
    }

    void setHistoryLimit(int v) {
        if (m_historyLimit != v) {
            m_historyLimit = v;
            emit historyLimitChanged();
        }
    }
    void setAppThreshold(double v) {
        if (!qFuzzyCompare(m_appThreshold, v)) {
            m_appThreshold = v;
            emit appThresholdChanged();
        }
    }
    void setFileThreshold(double v) {
        if (!qFuzzyCompare(m_fileThreshold, v)) {
            m_fileThreshold = v;
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

    double               scoreApp(QObject* entry, const QStringList& normQueryWords, const QString& normQuery) const;

    QSettings*           m_settings = nullptr;

    QList<SearchResult*> m_fileResults;
    QList<HistoryEntry>  m_history;
    int                  m_historyLimit  = 50;
    double               m_appThreshold  = 0.35;
    double               m_fileThreshold = 0.40;
};
