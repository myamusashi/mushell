#pragma once

#include <qobject.h>
#include <qqmlintegration.h>

class Utils : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

  public:
    [[nodiscard]] static Q_INVOKABLE QString read(const QString& path);
    [[nodiscard]] static Q_INVOKABLE bool    write(const QString& path, const QString& contents);
};
