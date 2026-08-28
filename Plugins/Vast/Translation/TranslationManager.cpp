#include "TranslationManager.hpp"

#include <qdebug.h>
#include <qobject.h>
#include <qlogging.h>
#include <qguiapplication.h>
#include <qtmetamacros.h>
#include <qqml.h>
#include <qqmlengine.h>

TranslationManager::TranslationManager(QObject* parent) :
    QObject(parent), mTranslator(std::make_unique<QTranslator>()), mCurrentLanguage("en_US"), M_AVAILABLE_LANGUAGES({"en_US", "id_ID"}) {}

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

    auto candidate = std::make_unique<QTranslator>();
    if (!candidate->load(filePath)) {
        qWarning() << "Failed to load translation:" << filePath << "— keeping" << mCurrentLanguage;
        return false;
    }

    QGuiApplication::removeTranslator(mTranslator.get());
    mTranslator = std::move(candidate);
    QGuiApplication::installTranslator(mTranslator.get());

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
