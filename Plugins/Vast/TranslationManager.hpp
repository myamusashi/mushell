#pragma once

#include <qguiapplication.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qtranslator.h>

class TranslationManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentLanguage READ currentLanguage WRITE setCurrentLanguage NOTIFY languageChanged)
    QML_ELEMENT
    QML_SINGLETON

  public:
    static constexpr auto DefaultTranslationPath = ":/translations";

    explicit TranslationManager(QObject* parent = nullptr);

    [[nodiscard]] QString                 currentLanguage() const;
    void                                  setCurrentLanguage(const QString& language);

    [[nodiscard]] Q_INVOKABLE bool        loadTranslation(const QString& language, const QString& translationPath = DefaultTranslationPath);
    [[nodiscard]] Q_INVOKABLE QStringList availableLanguages() const;

  signals:
    void languageChanged();

  private:
    QTranslator       m_translator;
    QString           m_currentLanguage;
    const QStringList m_availableLanguages;
};
