# ADR-003: Localization architecture

Status: Accepted  
Date: 2026-08-03  

## Context

Plöntukrot needs multiple UI languages.

## Decision

Use Flutter's built-in localization:
- flutter_localizations
- intl
- gen_l10n
- ARB

Supported languages:
- English
- Russian
- German
- French

User-generated content is never localized.

## Consequences

Pros:
- no third-party localization package
- easy to add languages
- UGC remains language-independent

Cons:
- ARB files need to be maintained
- translations require manual review

## References

- [Localization](../architecture/localization.md)