#include "ImageCacheIndex.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qfileinfo.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qiodevice.h>
#include <qlist.h>
#include <qstring.h>

#include <mutex>
#include <shared_mutex>

namespace {
    const auto K_FILE_URL_PREFIX = QStringLiteral("file://");
}

ImageCacheIndex::ImageCacheIndex() {
    load();
}

QString ImageCacheIndex::directory() {
    return QStringLiteral("/tmp/vast-shell/notif-images");
}

QString ImageCacheIndex::path() {
    return QStringLiteral("%1/.index.json").arg(directory());
}

QString ImageCacheIndex::toFileUrl(const QString& path) {
    return K_FILE_URL_PREFIX + path;
}

QString ImageCacheIndex::fromFileUrl(const QString& url) {
    return url.startsWith(K_FILE_URL_PREFIX) ? url.mid(K_FILE_URL_PREFIX.size()) : url;
}

QString ImageCacheIndex::lookup(const QString& cacheKey) const {
    std::shared_lock const lock(mRwMutex);
    return mKeyToPath.value(cacheKey);
}

void ImageCacheIndex::insert(const QString& cacheKey, const QString& fileUrl) {
    {
        std::unique_lock const lock(mRwMutex);
        mKeyToPath.insert(cacheKey, fileUrl);
    }
    save();
}

QString ImageCacheIndex::remove(const QString& cacheKey) {
    QString removed;
    {
        std::unique_lock const lock(mRwMutex);
        removed = mKeyToPath.take(cacheKey);
    }
    save();
    return removed;
}

QList<QString> ImageCacheIndex::allPaths() const {
    std::shared_lock const lock(mRwMutex);
    return mKeyToPath.values();
}

void ImageCacheIndex::load() {
    QFile file(path());
    if (!file.open(QIODevice::ReadOnly))
        return;

    const auto document = QJsonDocument::fromJson(file.readAll());
    if (!document.isObject())
        return;

    std::unique_lock const lock(mRwMutex);
    const auto             object = document.object();
    for (auto it = object.begin(); it != object.end(); ++it) {
        const QString filePath = it.value().toString();
        if (QFile::exists(filePath))
            mKeyToPath.insert(it.key(), filePath);
    }
}

void ImageCacheIndex::save() const {
    QJsonObject object;
    {
        std::shared_lock const lock(mRwMutex);
        for (auto it = mKeyToPath.constBegin(); it != mKeyToPath.constEnd(); ++it)
            object.insert(it.key(), it.value());
    }

    QFile file(path());
    QDir{}.mkpath(directory());
    if (file.open(QIODevice::WriteOnly))
        file.write(QJsonDocument(object).toJson(QJsonDocument::Compact));
}
