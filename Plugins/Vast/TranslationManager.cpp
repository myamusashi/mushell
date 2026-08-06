#include "TranslationManager.hpp"

#include <qdebug.h>
#include <qobject.h>
#include <qlogging.h>
#include <qguiapplication.h>
#include <qtmetamacros.h>
#include <qqml.h>
#include <qqmlengine.h>

TranslationManager::TranslationManager(QObject* parent) : QObject(parent), mCurrentLanguage("en_US"), M_AVAILABLE_LANGUAGES({"en_US", "id_ID"}) {}

QString TranslationManager::currentLanguage() const {
    return mCurrentLanguage;
}

void TranslationManager::setCurrentLanguage(const QString& language) {
    if (mCurrentLanguage == language)
        return;

    if (!loadTranslation(language))
        qWarning() << "Language switch failed, staying on:" << mCurrentLanguage;
}

bool TranslationManager::loadTranslation(const QString& language, const QString& translationPath) {
    const QString filePath = translationPath + "/" + language + ".qm";

    qDebug() << "Loading translation:" << filePath;

    QGuiApplication::removeTranslator(&mTranslator);

    if (!mTranslator.load(filePath)) {
        qWarning() << "Failed to load translation:" << filePath;
        QGuiApplication::installTranslator(&mTranslator);
        return false;
    }

    QGuiApplication::installTranslator(&mTranslator);
    mCurrentLanguage = language;
    emit  languageChanged();

    auto* engine = qmlEngine(this);
    if (engine)
        engine->retranslate();

    qDebug() << "Translation loaded successfully:" << language;
    return true;
}

QStringList TranslationManager::availableLanguages() const {
    return M_AVAILABLE_LANGUAGES;
}
