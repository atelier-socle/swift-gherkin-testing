# Internationalization

Write Gherkin features in 70+ languages.

## Overview

Gherkin Testing supports all languages from the official Cucumber `gherkin-languages.json` registry. Use the `# language:` directive at the top of a `.feature` file to set the language.

### Language Directive

```gherkin
# language: fr
@auth
Fonctionnalité: Authentification
  Les utilisateurs peuvent se connecter.

  Scénario: Connexion réussie
    Soit l'application est lancée
    Quand l'utilisateur entre "alice" et "secret123"
    Alors il devrait voir le tableau de bord
```

The directive must appear on the first non-empty line. Without it, English (`en`) is assumed.

### Keyword Mapping

Each language maps Gherkin keywords to localized equivalents:

| English | French (`fr`) | Japanese (`ja`) | German (`de`) |
|---------|--------------|-----------------|---------------|
| `Feature:` | `Fonctionnalité:` | `機能:` | `Funktionalität:` |
| `Scenario:` | `Scénario:` | `シナリオ:` | `Szenario:` |
| `Given` | `Soit` | `前提` | `Angenommen` |
| `When` | `Quand` | `もし` | `Wenn` |
| `Then` | `Alors` | `ならば` | `Dann` |
| `And` | `Et` | `かつ` | `Und` |
| `But` | `Mais` | `しかし` | `Aber` |

### Step Definitions Are Language-Independent

Step expressions match against the step text **after** the keyword is stripped. The same step definitions work regardless of feature language:

```swift
// This definition matches both:
// English: "Given the app is launched"
// French:  "Soit l'application est lancée"  (if step text matches)
@Given("the app is launched")
func appLaunched() async throws { }
```

> Note: The step text itself must match — only the keyword prefix (`Given`, `Soit`, etc.) is localized.

### Language Detection API

``LanguageDetector`` provides programmatic language detection:

```swift
let code = LanguageDetector.detectLanguageCode(from: "# language: fr\n...")
// code == "fr"

let language = LanguageDetector.detectLanguage(from: "# language: ja\n...")
// language.name == "Japanese"
```

``LanguageRegistry`` provides keyword lookup by language code:

```swift
let french = LanguageRegistry.language(for: "fr")
// french?.given == ["Soit ", "Sachant que ", "Sachant qu'", ...]

let codes = LanguageRegistry.supportedLanguageCodes
// 70+ language codes
```

Keyword lookup is O(1) via dictionary.

## See Also

- <doc:WritingFeatureFiles>
- <doc:GettingStarted>
