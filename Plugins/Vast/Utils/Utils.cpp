#include "Utils.hpp"

#include <qdebug.h>
#include <qfile.h>
#include <qlogging.h>

Utils::Utils(QObject* parent) : QObject(parent) {}

QString Utils::read(const QString& path) const {
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly)) {
        qWarning() << "[Vast.Utils] Failed to open file for reading:" << path << file.errorString();
        return {};
    }

    return QString::fromUtf8(file.readAll());
}

bool Utils::write(const QString& path, const QString& contents) const {
    QFile file(path);
    if (!file.open(QIODevice::WriteOnly)) {
        qWarning() << "[Vast.Utils] Failed to open file for writing:" << path << file.errorString();
        return false;
    }

    const QByteArray data = contents.toUtf8();
    if (file.write(data) != data.size()) {
        qWarning() << "[Vast.Utils] Failed to write file:" << path << file.errorString();
        return false;
    }

    return true;
}
