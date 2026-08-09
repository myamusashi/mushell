#include "BrightnessProfileStore.hpp"

#include <mutex>
#include <optional>
#include <qcontainerfwd.h>
#include <qlist.h> // NOLINT(misc-include-cleaner): QStringList alias must be complete, symbol only used via qcontainerfwd.h
#include <qmap.h> // NOLINT(misc-include-cleaner): QVariantMap alias must be complete, symbol only used via qcontainerfwd.h
#include <qvariant.h>
#include <ranges>
#include <shared_mutex>

namespace vast {

    void BrightnessProfileStore::save(const QString& name, const QVariantMap& targets) {
        std::unique_lock const lock(mMutex);
        mProfiles.insert_or_assign(name, targets);
    }

    void BrightnessProfileStore::remove(const QString& name) {
        std::unique_lock const lock(mMutex);
        mProfiles.erase(name);
    }

    std::optional<QVariantMap> BrightnessProfileStore::find(const QString& name) const {
        std::shared_lock const lock(mMutex);
        const auto              it = mProfiles.find(name);
        if (it == mProfiles.end())
            return std::nullopt;
        return it->second;
    }

    QStringList BrightnessProfileStore::names() const {
        std::shared_lock const lock(mMutex);
        const auto              keys = mProfiles | std::views::keys;
        return QStringList(std::ranges::begin(keys), std::ranges::end(keys));
    }
}
