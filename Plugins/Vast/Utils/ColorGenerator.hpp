#pragma once

#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qvariant.h>

class QProcess;

class ColorGenerator : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

  public:
    explicit ColorGenerator(QObject* parent = nullptr);

    Q_INVOKABLE void generate(const QString& imagePath, const QString& mode, const QString& outputPath, const QString& scheme);
    Q_INVOKABLE void generateColors(const QString& imagePath, const QString& scheme);

  signals:
    void generationFinished(const QString& outputPath, const QString& mode, bool success);
    void colorsReady(const QString& imagePath, const QVariantMap& colors);

  private:
    struct SJob {
        QString imagePath;
        QString outputPath;
        QString mode;
        bool    returnColors = false;
    };

    QHash<QProcess*, SJob> mJobs;
};
