#include "ImageCache.hpp"

#include <qhashfunctions.h>
#include <mutex>
#include <qimagereader.h>
#include <QMutexLocker>
#include <qobject.h>
#include <qnamespace.h>
#include <qlogging.h>
#include <qjsengine.h>
#include <qqmlengine.h>
#include <qjsondocument.h>
#include <qrunnable.h>
#include <qthreadpool.h>
#include <qdir.h>
#include <qfile.h>
#include <qquickimageprovider.h>
#include <expected>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <shared_mutex>
#include <utility>

using namespace Qt::StringLiterals;

class DecodeTask : public QObject, public QRunnable {
    Q_OBJECT

  public:
    DecodeTask(ImageCache* cache, QString path, QSize targetSize) : mCache(cache), mPath(std::move(path)), mTargetSize(targetSize) {
        setAutoDelete(true);
    }

    void run() override {
        QImageReader reader(mPath);
        reader.setAutoTransform(true);
        if (mTargetSize.isValid())
            reader.setScaledSize(reader.size().scaled(mTargetSize, Qt::KeepAspectRatioByExpanding));

        if (reader.read().isNull())
            qWarning() << "[ImageCache] Failed to preload:" << mPath;

        mCache->store(mPath);
        emit mCache->imageReady(mPath);
    }

  private:
    ImageCache* mCache;
    QString     mPath;
    QSize       mTargetSize;
};

#include "ImageCache.moc"

ImageCache* ImageCache::sInstance = nullptr;

ImageCache::ImageCache(QObject* parent) : QObject(parent) {
    sInstance = this;
    loadIndex();
}

ImageCache* ImageCache::create(QQmlEngine* engine, QJSEngine* /*unused*/) {
    if (!sInstance)
        new ImageCache();
    sInstance->mEngine = engine;
    return sInstance;
}

ImageCache* ImageCache::instance() {
    return sInstance;
}

QString ImageCache::copyAndPreload(const QString& path, QSize targetSize) {
    QImage const img(path);
    if (img.isNull()) {
        qWarning() << "[ImageCache] copyAndPreload: could not read" << path;
        return {};
    }

    const QString stablePath = u"/tmp/vast-shell/art-cache/%1.png"_s.arg(QString::number(qHash(path), 16));
    QDir{}.mkpath(u"/tmp/vast-shell/art-cache"_s);

    if (!img.save(stablePath))
        return {};

    preload(stablePath, targetSize);
    return u"file://"_s + stablePath;
}

void ImageCache::preload(const QString& path, QSize targetSize) {
    {
        std::unique_lock const lock(mRwMutex);
        if (mDone.contains(path) || mLoading.contains(path))
            return;
        mLoading.insert(path);
    }
    QThreadPool::globalInstance()->start(new DecodeTask(this, path, targetSize));
}

std::expected<QString, ImageCacheError> ImageCache::saveProviderImage(const QString& qsUrl, const QString& cacheKey) {
    {
        std::shared_lock const lock(mRwMutex);
        if (mKeyToPath.contains(cacheKey))
            return mKeyToPath.value(cacheKey);
    }

    if (!mEngine)
        return std::unexpected(ImageCacheError::NoEngine);
    if (!qsUrl.startsWith(u"image://"_s))
        return std::unexpected(ImageCacheError::InvalidUrl);

    // Parse "image://qsimage/7/1"
    //   host  = "qsimage"
    //   id    = "7/1"
    const qsizetype hostStart  = 8;
    const qsizetype slashAfter = qsUrl.indexOf(u'/', hostStart);
    if (slashAfter < 0)
        return {};

    const QString providerName = qsUrl.mid(hostStart, slashAfter - hostStart);
    const QString imageId      = qsUrl.mid(slashAfter + 1);

    auto*         base     = mEngine->imageProvider(providerName);
    auto*         provider = dynamic_cast<QQuickImageProvider*>(base);
    if (!provider)
        return std::unexpected(ImageCacheError::NoProvider);
    if (provider->imageType() != QQmlImageProviderBase::Image)
        return std::unexpected(ImageCacheError::ProviderTypeMismatch);

    QSize        size;
    const QImage img = provider->requestImage(imageId, &size, {});
    if (img.isNull())
        return std::unexpected(ImageCacheError::NullImage);

    const QString dir  = u"/tmp/vast-shell/notif-images"_s;
    const QString path = u"%1/%2.png"_s.arg(dir, cacheKey);
    QDir{}.mkpath(dir);

    if (!img.save(path))
        return std::unexpected(ImageCacheError::SaveFailed);

    QString fileUrl = u"file://"_s + path;
    {
        std::unique_lock lock(mRwMutex);
        mKeyToPath.insert(cacheKey, fileUrl);
        lock.unlock();
        saveIndex();
    }
    return fileUrl;
}

void ImageCache::evict(const QString& path) {
    std::unique_lock const lock(mRwMutex);
    mDone.remove(path);
    mLoading.remove(path);
}

void ImageCache::store(const QString& path) {
    std::unique_lock const lock(mRwMutex);
    mLoading.remove(path);
    mDone.insert(path);

    constexpr qsizetype kMaxCacheEntries = 200;
    if (mDone.size() > kMaxCacheEntries) {
        auto            it       = mDone.begin();
        const qsizetype toRemove = mDone.size() - kMaxCacheEntries;
        for (int i = 0; i < toRemove && it != mDone.end(); ++i)
            it = mDone.erase(it);
    }
}

QString ImageCache::cachedPath(const QString& cacheKey) const {
    std::shared_lock const lock(mRwMutex);
    return mKeyToPath.value(cacheKey);
}

void ImageCache::evictKey(const QString& cacheKey) {
    std::unique_lock const lock(mRwMutex);
    const QString          path = mKeyToPath.take(cacheKey);
    if (!path.isEmpty())
        QFile::remove(path.mid(7));
}

QString ImageCache::indexPath() {
    return u"/tmp/vast-shell/notif-images/.index.json"_s;
}

void ImageCache::loadIndex() {
    QFile f(indexPath());
    if (!f.open(QIODevice::ReadOnly))
        return;

    const auto doc = QJsonDocument::fromJson(f.readAll());
    if (!doc.isObject())
        return;

    std::unique_lock const lock(mRwMutex);
    const auto             obj = doc.object();
    for (auto it = obj.begin(); it != obj.end(); ++it) {
        const QString filePath = it.value().toString();
        if (QFile::exists(filePath)) {
            mKeyToPath.insert(it.key(), filePath);
            mDone.insert(filePath);
        }
    }
}

void ImageCache::saveIndex() {
    std::shared_lock lock(mRwMutex);
    QJsonObject      obj;
    for (auto it = mKeyToPath.constBegin(); it != mKeyToPath.constEnd(); ++it) {
        obj.insert(it.key(), it.value());
    }
    lock.unlock();

    QFile f(indexPath());
    QDir().mkpath(QFileInfo(f).absolutePath());
    if (f.open(QIODevice::WriteOnly))
        f.write(QJsonDocument(obj).toJson(QJsonDocument::Compact));
}
