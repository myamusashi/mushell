#pragma once

#include <qhash.h>
#include <qlist.h>
#include <qstring.h>

#include <shared_mutex>

class ImageCacheIndex {
  public:
    ImageCacheIndex();

    [[nodiscard]] QString        lookup(const QString& cacheKey) const;
    void                         insert(const QString& cacheKey, const QString& fileUrl);
    QString                      remove(const QString& cacheKey);
    [[nodiscard]] QList<QString> allPaths() const;

    [[nodiscard]] static QString toFileUrl(const QString& path);
    [[nodiscard]] static QString fromFileUrl(const QString& url);
    [[nodiscard]] static QString directory();

  private:
    void                         load();
    void                         save() const;
    [[nodiscard]] static QString path();

    mutable std::shared_mutex    mRwMutex;
    QHash<QString, QString>      mKeyToPath;
};
