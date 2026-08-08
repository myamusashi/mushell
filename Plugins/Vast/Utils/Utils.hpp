#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

class Utils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

  public:
    explicit Utils(QObject* parent = nullptr);

    [[nodiscard]] Q_INVOKABLE QString read(const QString& path) const;
    [[nodiscard]] Q_INVOKABLE bool    write(const QString& path, const QString& contents) const;
};
