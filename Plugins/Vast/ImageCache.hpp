#pragma once

#include <qobject.h>
#include <qthreadpool.h>
#include <qset.h>
#include <qhash.h>
#include <qsize.h>
#include <QtQml/qqml.h>
#include <expected>
#include <shared_mutex>

enum class ImageCacheError {
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
    static ImageCache* create(QQmlEngine*, QJSEngine*);
    static ImageCache* instance();
    ~ImageCache() {
        QThreadPool::globalInstance()->waitForDone();
    }

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
    static ImageCache*        s_instance;

    void                      loadIndex();
    void                      saveIndex();
    QString                   indexPath() const;

    QQmlEngine*               m_engine = nullptr;

    mutable std::shared_mutex m_rwMutex;

    QSet<QString>             m_loading;
    QSet<QString>             m_done;
    QHash<QString, QString>   m_keyToPath;

    void                      store(const QString& path);
    friend class DecodeTask;
};
