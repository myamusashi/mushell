#pragma once

#include <qcontainerfwd.h>
#include <qobject.h>
#include <qtmetamacros.h>
#include <qqmlintegration.h>
#include <qtranslator.h>

#include <memory>

class TranslationManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString currentLanguage READ currentLanguage WRITE setCurrentLanguage NOTIFY languageChanged)
    QML_ELEMENT
    QML_SINGLETON

  public:
    static constexpr auto DEFAULT_TRANSLATION_PATH = ":/translations";

    explicit TranslationManager(QObject* parent = nullptr);

    [[nodiscard]] QString                 currentLanguage() const;
    void                                  setCurrentLanguage(const QString& language);

    [[nodiscard]] Q_INVOKABLE bool        loadTranslation(const QString& language, const QString& translationPath = DEFAULT_TRANSLATION_PATH);
    [[nodiscard]] Q_INVOKABLE QStringList availableLanguages() const;

  signals:
    void languageChanged();

  private:
    std::unique_ptr<QTranslator> mTranslator;
    QString                      mCurrentLanguage;
    const QStringList            M_AVAILABLE_LANGUAGES;
};
