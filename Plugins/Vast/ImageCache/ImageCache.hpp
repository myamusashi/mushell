#pragma once

#include "ImageCacheIndex.hpp"

#include <qlogging.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qset.h>
#include <qsize.h>
#include <QtQml/qqml.h>
#include <expected>
#include <cstdint>
#include <qtmetamacros.h>

enum class ImageCacheError : uint8_t {
    NoEngine,
    InvalidUrl,
    NoProvider,
    ProviderTypeMismatch,
    NullImage,
    SaveFailed,
};

class QQmlEngine;

class ImageCache : public QObject {
    Q_OBJECT
    QML_SINGLETON
    QML_NAMED_ELEMENT(ImageCache)

  public:
    static ImageCache* create(QQmlEngine* /*engine*/, QJSEngine* /*unused*/);
    static ImageCache* instance();
    ~ImageCache() override                      = default;
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
    static ImageCache*           sInstance;

    [[nodiscard]] static QString artCacheDir();

    QQmlEngine*                  mEngine = nullptr;

    // Main-thread-only state: mutated in QML-invoked entry points and in
    // completions queued back onto the creating thread; decode jobs on the
    // shared executor touch captured locals only.
    QSet<QString>   mLoading;
    QSet<QString>   mDone;
    ImageCacheIndex mIndex;

    void            store(const QString& path);
};
