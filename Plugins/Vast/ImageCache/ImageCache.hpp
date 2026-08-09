#pragma once

#include <qlogging.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qthreadpool.h>
#include <qset.h>
#include <qhash.h>
#include <qsize.h>
#include <QtQml/qqml.h>
#include <expected>
#include <cstdint>
#include <qtmetamacros.h>
#include <shared_mutex>

enum class ImageCacheError : std::uint8_t {
    NoEngine,
    InvalidUrl,
    NoProvider,
    ProviderTypeMismatch,
    NullImage,
    SaveFailed,
};

class QQmlEngine;

/// QML singleton created through create(). The QML engine owns the returned
/// instance for its lifetime; the parentless allocation in create() is intentional.
class ImageCache : public QObject {
    Q_OBJECT
    QML_SINGLETON
    QML_NAMED_ELEMENT(ImageCache)

  public:
    static ImageCache* create(QQmlEngine* /*engine*/, QJSEngine* /*unused*/);
    static ImageCache* instance();
    ~ImageCache() override {
        QThreadPool::globalInstance()->waitForDone();
    }
    ImageCache(const ImageCache&)               = delete;
    ImageCache& operator=(const ImageCache&)    = delete;
    ImageCache(ImageCache&&)                    = delete;
    ImageCache&         operator=(ImageCache&&) = delete;

    Q_INVOKABLE QString copyAndPreload(const QString& path, QSize targetSize = {});
    Q_INVOKABLE void    preload(const QString& path, QSize targetSize = {});
    Q_INVOKABLE void    evict(const QString& path);

    Q_INVOKABLE QString saveProviderImageQml(const QString& url, const QString& key) {
        auto result = saveProviderImage(url, key);
        if (!result) {
            qWarning() << "[ImageCache] saveProviderImage failed:" << static_cast<int>(result.error());
            return {};
        }
        return *result;
    }
    [[nodiscard]] std::expected<QString, ImageCacheError> saveProviderImage(const QString& qsUrl, const QString& cacheKey);
    [[nodiscard]] Q_INVOKABLE QString                     cachedPath(const QString& cacheKey) const;

    Q_INVOKABLE void                                      evictKey(const QString& cacheKey);

  signals:
    void imageReady(const QString& path);

  private:
    explicit ImageCache(QObject* parent = nullptr);
    static ImageCache*        sInstance;

    void                      loadIndex();
    void                      saveIndex();
    static QString            indexPath();
    [[nodiscard]] static QString artCacheDir();
    [[nodiscard]] static QString notifImagesDir();
    [[nodiscard]] static QString toFileUrl(const QString& path);
    [[nodiscard]] static QString fromFileUrl(const QString& url);

    QQmlEngine*               mEngine = nullptr;

    mutable std::shared_mutex mRwMutex;

    QSet<QString>             mLoading;
    QSet<QString>             mDone;
    QHash<QString, QString>   mKeyToPath;

    void                      store(const QString& path);
    friend class DecodeTask;
};
