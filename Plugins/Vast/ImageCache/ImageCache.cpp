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
#include <qassert.h>
#include <qquickimageprovider.h>
#include <expected>
#include <qtmetamacros.h>
#include <qtypes.h>
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
    Q_ASSERT_X(sInstance == nullptr, "ImageCache::ImageCache", "ImageCache constructed more than once");
    sInstance = this;
    for (const auto& path : mIndex.allPaths())
        mDone.insert(path);
}

ImageCache* ImageCache::create(QQmlEngine* engine, QJSEngine* /*unused*/) {
    if (!sInstance) {
        // Intentionally parentless: QML singleton ownership manages this
        // instance after it is returned from the factory.
        new ImageCache();
    }
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

    const QString stablePath = u"%1/%2.png"_s.arg(artCacheDir(), QString::number(qHash(path), 16));
    QDir{}.mkpath(artCacheDir());

    if (!img.save(stablePath))
        return {};

    preload(stablePath, targetSize);
    return ImageCacheIndex::toFileUrl(stablePath);
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
        QString existing = mIndex.lookup(cacheKey);
        if (!existing.isEmpty())
            return existing;
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

    const QString dir  = ImageCacheIndex::directory();
    const QString path = u"%1/%2.png"_s.arg(dir, cacheKey);
    QDir{}.mkpath(dir);

    if (!img.save(path))
        return std::unexpected(ImageCacheError::SaveFailed);

    QString fileUrl = ImageCacheIndex::toFileUrl(path);
    mIndex.insert(cacheKey, fileUrl);
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
    return mIndex.lookup(cacheKey);
}

void ImageCache::evictKey(const QString& cacheKey) {
    const QString url = mIndex.remove(cacheKey);
    if (url.isEmpty())
        return;

    const QString path = ImageCacheIndex::fromFileUrl(url);
    if (!QFile::remove(path))
        qWarning() << "[ImageCache] evictKey: failed to remove" << path << "for key" << cacheKey;
}

QString ImageCache::artCacheDir() {
    return u"/tmp/vast-shell/art-cache"_s;
}
