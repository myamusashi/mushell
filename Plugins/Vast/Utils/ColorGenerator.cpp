#include "ColorGenerator.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qiodevice.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
#include <qobject.h>
#include <qprocess.h>
#include <qstring.h>
#include <quuid.h>

ColorGenerator::ColorGenerator(QObject* parent) : QObject(parent) {}

void ColorGenerator::generate(const QString& imagePath, const QString& mode, const QString& outputPath, const QString& scheme) {
    if (imagePath.isEmpty() || outputPath.isEmpty() || (mode != QStringLiteral("dark") && mode != QStringLiteral("light"))) {
        emit generationFinished(outputPath, mode, false);
        return;
    }

    auto* process = new QProcess(this);
    mJobs.insert(process, SJob{.imagePath = imagePath, .outputPath = outputPath, .mode = mode, .returnColors = false});

    connect(process, &QProcess::finished, this, [this, process](const int EXIT_CODE, const QProcess::ExitStatus EXIT_STATUS) {
        if (!mJobs.contains(process))
            return;

        const auto job = mJobs.take(process);
        if (job.returnColors && EXIT_STATUS == QProcess::NormalExit && EXIT_CODE == 0) {
            QFile file(job.outputPath);
            if (file.open(QIODevice::ReadOnly)) {
                const auto document = QJsonDocument::fromJson(file.readAll());
                const auto colors   = document.object().value(QStringLiteral("colors")).toObject().toVariantMap();
                if (!colors.isEmpty())
                    emit colorsReady(job.imagePath, colors);
            }
            file.remove();
        }

        emit generationFinished(job.outputPath, job.mode, EXIT_STATUS == QProcess::NormalExit && EXIT_CODE == 0);
        process->deleteLater();
    });

    connect(process, &QProcess::errorOccurred, this, [this, process](const QProcess::ProcessError PROCESS_ERROR) {
        if (PROCESS_ERROR != QProcess::FailedToStart)
            return;

        if (!mJobs.contains(process))
            return;

        const auto job = mJobs.take(process);
        if (job.returnColors)
            QFile::remove(job.outputPath);

        emit generationFinished(job.outputPath, job.mode, false);
        process->deleteLater();
    });

    process->start(QStringLiteral("generate-colors-material"),
                   {
                       QStringLiteral("--path"),
                       imagePath,
                       QStringLiteral("--mode"),
                       mode,
                       QStringLiteral("--scheme"),
                       scheme,
                       QStringLiteral("--json-out"),
                       outputPath,
                   });
}

void ColorGenerator::generateColors(const QString& imagePath, const QString& scheme) {
    if (imagePath.isEmpty())
        return;

    const auto outputPath = QDir::tempPath() + QStringLiteral("/vast-colors-%1.json").arg(QUuid::createUuid().toString(QUuid::WithoutBraces));
    auto*      process    = new QProcess(this);
    mJobs.insert(process, SJob{.imagePath = imagePath, .outputPath = outputPath, .mode = QStringLiteral("dark"), .returnColors = true});

    connect(process, &QProcess::finished, this, [this, process](const int EXIT_CODE, const QProcess::ExitStatus EXIT_STATUS) {
        if (!mJobs.contains(process))
            return;

        const auto job = mJobs.take(process);
        if (job.returnColors && EXIT_STATUS == QProcess::NormalExit && EXIT_CODE == 0) {
            QFile file(job.outputPath);
            if (file.open(QIODevice::ReadOnly)) {
                const auto document = QJsonDocument::fromJson(file.readAll());
                const auto colors   = document.object().value(QStringLiteral("colors")).toObject().toVariantMap();
                if (!colors.isEmpty())
                    emit colorsReady(job.imagePath, colors);
            }
        }
        QFile::remove(job.outputPath);
        process->deleteLater();
    });

    connect(process, &QProcess::errorOccurred, this, [this, process](const QProcess::ProcessError PROCESS_ERROR) {
        if (PROCESS_ERROR != QProcess::FailedToStart || !mJobs.contains(process))
            return;

        const auto job = mJobs.take(process);
        QFile::remove(job.outputPath);
        process->deleteLater();
    });

    process->start(QStringLiteral("generate-colors-material"),
                   {
                       QStringLiteral("--path"),
                       imagePath,
                       QStringLiteral("--mode"),
                       QStringLiteral("dark"),
                       QStringLiteral("--scheme"),
                       scheme,
                       QStringLiteral("--json-out"),
                       outputPath,
                   });
}
