#include "TranslationManager.hpp"

#include <qdebug.h>

TranslationManager::TranslationManager(QObject* parent) : QObject(parent), m_currentLanguage("en_US"), m_availableLanguages({"en_US", "id_ID"}) {}

QString TranslationManager::currentLanguage() const {
    return m_currentLanguage;
}

void TranslationManager::setCurrentLanguage(const QString& language) {
    if (m_currentLanguage == language)
        return;

    if (!loadTranslation(language))
        qWarning() << "Language switch failed, staying on:" << m_currentLanguage;
}

bool TranslationManager::loadTranslation(const QString& language, const QString& translationPath) {
    const QString filePath = translationPath + "/" + language + ".qm";

    qDebug() << "Loading translation:" << filePath;

    QGuiApplication::removeTranslator(&m_translator);

    if (!m_translator.load(filePath)) {
        qWarning() << "Failed to load translation:" << filePath;
        QGuiApplication::installTranslator(&m_translator);
        return false;
    }

    QGuiApplication::installTranslator(&m_translator);
    m_currentLanguage = language;
    emit  languageChanged();

    auto* engine = qmlEngine(this);
    if (engine)
        engine->retranslate();

    qDebug() << "Translation loaded successfully:" << language;
    return true;
}

QStringList TranslationManager::availableLanguages() const {
    return m_availableLanguages;
}
