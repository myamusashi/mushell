# Translations

[Back to README](../README.md)

Vast-shell uses Qt's built-in translation system. Translation files live in `translations/`:

- `.ts` — source file (XML, human-editable)
- `.qm` — compiled binary used at runtime (do not edit directly)

| Locale | Language |
|---|---|
| `id_ID` | Indonesian |

> [!NOTE]
> `lupdate` and `lrelease` are provided by `qt6-tools` (Arch), `qt6-tools-dev-tools` (Debian/Ubuntu), or `qt6.qttools` (NixOS).

## Qt Linguist

The recommended way to translate vast-shell is with **Qt Linguist**, a GUI editor that ships with `qt6-tools`. It shows every string in context, tracks translation progress, and warns about missing or outdated entries.

<img src="https://github.com/user-attachments/assets/c5569311-99a3-4f99-9709-464ceda68495" width="720"/>

<table>
  <tr>
    <td>✅ Visual side-by-side editing</td>
    <td>✅ Progress tracker per file</td>
  </tr>
  <tr>
    <td>✅ Marks unfinished and obsolete strings</td>
    <td>✅ Built-in phrase book and search</td>
  </tr>
</table>

```bash
linguist translations/your_locale.ts
```

## Adding a New Language

```bash
# 1. Generate the .ts file
lupdate $(find . -name "*.qml" -not -path "./build/*") -ts translations/your_locale.ts

# 2. Translate in Qt Linguist (or edit the XML by hand)
linguist translations/your_locale.ts

# 3. Compile to .qm
lrelease translations/your_locale.ts
```

Replace `your_locale` with a standard locale code, e.g. `fr_FR`, `ja_JP`, `de_DE`.

## Updating an Existing Translation

```bash
# Sync new strings without overwriting existing translations
lupdate $(find . -name "*.qml" -not -path "./build/*") -ts translations/your_locale.ts

# Open in Linguist, finish unfinished entries, then recompile
lrelease translations/your_locale.ts
```

**NixOS:** Translations are compiled automatically during the build phase — no manual steps needed.

**Arch Linux:** `archInstall.sh` compiles translations automatically. To recompile manually:

```bash
/usr/lib/qt6/bin/lrelease translations/*.ts
```
