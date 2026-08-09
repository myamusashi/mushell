#pragma once

#include <qobject.h>
#include <qstring.h>
#include <qlist.h>
#include <qtmetamacros.h>
#include <qtypes.h>

class QSettings;

namespace vast {

class LaunchHistoryStore : public QObject {
    Q_OBJECT

    Q_PROPERTY(int historyLimit READ historyLimit WRITE setHistoryLimit NOTIFY historyLimitChanged)

  public:
    explicit LaunchHistoryStore(QObject* parent = nullptr);

    void                 recordLaunch(const QString& appId);
    [[nodiscard]] double recencyScore(const QString& appId) const;
    void                 clearHistory();

    [[nodiscard]] int historyLimit() const noexcept {
        return mHistoryLimit;
    }
    void setHistoryLimit(int value);

  signals:
    void historyLimitChanged();

  private:
    void loadHistory();
    void saveHistory();

    struct HistoryEntry {
        QString id;
        qint64  timestamp{0};
        int     count{0};
    };

    QSettings*          mSettings{nullptr};
    QList<HistoryEntry> mHistory;
    int                 mHistoryLimit{50};
};
}
