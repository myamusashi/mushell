#include "DirectoryWalker.hpp"
#include "../FuzzyMatcher.hpp"

#include <qdir.h>
#include <qfileinfo.h>
#include <qnamespace.h>
#include <qobjectdefs.h>
#include <qset.h>
#include <qstring.h>
#include <qstringlist.h>
#include <qthreadpool.h>
#include <qtmetamacros.h>
#include <qcontainerfwd.h>
#include <qvariant.h>
#include <algorithm>

namespace vast {

    namespace {
        constexpr int K_MAX_ENTRIES = 5000;

        struct WalkConfig {
            bool        showHidden;
            QStringList nameFilters;
        };

        bool fileAccepted(const QString& fileName, const WalkConfig& cfg) {
            if (cfg.nameFilters.isEmpty())
                return true;
            return std::ranges::any_of(cfg.nameFilters, [&](const QString& pattern) { return QDir::match(pattern, fileName); });
        }

        void walkDir(const QString& absolutePath, const QString& relativePrefix, int remainingDepth, const WalkConfig& cfg, QSet<QString>& visited, int& budget,
                     QVariantList& out) {
            if (remainingDepth < 0 || budget <= 0)
                return;

            const QDir    dir(absolutePath);
            QDir::Filters filters = QDir::Files | QDir::Dirs | QDir::NoDotAndDotDot | QDir::Readable;
            if (cfg.showHidden)
                filters |= QDir::Hidden;

            const auto infos = dir.entryInfoList(filters, QDir::DirsFirst | QDir::Name);

            for (const QFileInfo& info : infos) {
                if (budget <= 0)
                    return;

                const bool     isDir    = info.isDir();
                const QString& fileName = info.fileName();

                // FolderListModel parity: name filters gate files only.
                if (!isDir && !fileAccepted(fileName, cfg))
                    continue;

                const QString rel = relativePrefix.isEmpty() ? fileName : relativePrefix + QLatin1Char('/') + fileName;

                // The walked list is query-independent and stable across
                // keystrokes, so bake the scoring-ready forms of the path in
                // here once instead of re-encoding per search pass.
                const QString normRel = FuzzyMatcher::normalizeText(rel);

                QVariantMap   entry;
                entry[QStringLiteral("fileName")]         = fileName;
                entry[QStringLiteral("filePath")]         = info.absoluteFilePath();
                entry[QStringLiteral("relativePath")]     = rel;
                entry[QStringLiteral("relativePathNorm")] = normRel;
                entry[QStringLiteral("relativePathUtf8")] = normRel.toUtf8();
                entry[QStringLiteral("fileSize")]         = isDir ? 0 : info.size();
                entry[QStringLiteral("fileModified")]     = info.lastModified();
                entry[QStringLiteral("fileIsDir")]        = isDir;
                out.append(entry);
                --budget;

                if (isDir) {
                    const QString canonical = info.canonicalFilePath();
                    if (!canonical.isEmpty() && !visited.contains(canonical)) {
                        visited.insert(canonical);
                        walkDir(info.absoluteFilePath(), rel, remainingDepth - 1, cfg, visited, budget, out);
                    }
                }
            }
        }
    }

    DirectoryWalker::DirectoryWalker(QObject* parent) : QObject(parent) {}

    void DirectoryWalker::setWalking(bool v) {
        if (mWalking == v)
            return;
        mWalking = v;
        emit walkingChanged();
    }

    void DirectoryWalker::requestWalk() {
        if (mRoots.isEmpty())
            return;

        const int generation = mGeneration.fetchAndAddRelaxed(1) + 1;
        setWalking(true);

        const WalkConfig  cfg{.showHidden = mShowHidden, .nameFilters = mNameFilters};
        const int         maxDepth = mMaxDepth;
        const QStringList roots    = mRoots;

        QThreadPool::globalInstance()->start([this, generation, cfg, maxDepth, roots]() {
            QVariantList  entries;
            int           budget = K_MAX_ENTRIES;
            QSet<QString> visited;

            for (const QString& root : roots) {
                const QDir dir(root);
                if (!dir.exists())
                    continue;

                const QString canonical = dir.canonicalPath();
                if (visited.contains(canonical))
                    continue;
                visited.insert(canonical);

                walkDir(dir.absolutePath(), QString(), maxDepth, cfg, visited, budget, entries);
                if (budget <= 0)
                    break;
            }

            QMetaObject::invokeMethod(
                this,
                [this, generation, entries]() {
                    if (mGeneration.loadRelaxed() != generation)
                        return;
                    setWalking(false);
                    emit walkFinished(entries);
                },
                Qt::QueuedConnection);
        });
    }
}
