#pragma once

#include <qcontainerfwd.h>
#include <qstring.h>

#include <map>
#include <optional>
#include <shared_mutex>

namespace vast {

    /// Thread-safe store of named brightness profiles.
    class BrightnessProfileStore final {
      public:
        void                                     save(const QString& name, const QVariantMap& targets);
        void                                     remove(const QString& name);
        [[nodiscard]] std::optional<QVariantMap> find(const QString& name) const;
        [[nodiscard]] QStringList                names() const;

      private:
        using ProfileMap = std::map<QString, QVariantMap>;

        ProfileMap                mProfiles;
        mutable std::shared_mutex mMutex;
    };
}
