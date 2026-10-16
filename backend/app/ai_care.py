"""AI generation service for botanical genus and family care guides."""
from __future__ import annotations

import json
import logging
import os
import re
import urllib.request
from typing import Any, Literal

from .config import settings

logger = logging.getLogger("plontukrot.ai_care")

SUPPORTED_LOCALES = frozenset({"en", "ru", "de", "fr"})

LOCALE_LANGUAGE_NAMES = {
    "ru": "русском",
    "en": "English",
    "de": "German",
    "fr": "French",
}

TaxonKind = Literal["genus", "family"]


def normalize_locale(locale: str | None) -> str:
    """Return a supported BCP-47 language code (defaults to Russian)."""
    code = (locale or "ru").strip().lower().split("-")[0]
    return code if code in SUPPORTED_LOCALES else "en"


def system_prompt(locale: str, kind: TaxonKind = "genus") -> str:
    """Build the LLM system prompt for the requested UI locale and taxon kind."""
    language = LOCALE_LANGUAGE_NAMES.get(locale, LOCALE_LANGUAGE_NAMES["en"])
    if kind == "family":
        taxon_label = "plant family"
        name_key = "family"
        name_desc = "family name"
    else:
        taxon_label = "plant genus"
        name_key = "genus"
        name_desc = "genus name"

    return f"""\
You are a professional botanist and indoor plant care expert.
Provide a concise, accurate, and practical care guide for the requested {taxon_label} in {language}.

Reply STRICTLY as JSON without Markdown fences:
{{
  "{name_key}": "{name_desc}",
  "origin": "1-2 sentences about origin and natural habitat",
  "light": "light requirements (1-2 sentences)",
  "watering": "watering schedule and tips (1-2 sentences)",
  "fertilizing": "feeding frequency and fertilizer type during growth (1-2 sentences)",
  "soil": "ideal soil mix and properties (1-2 sentences)",
  "humidity": "humidity and misting needs (1-2 sentences)",
  "toxicity": "brief toxicity info for cats/dogs (or null if safe)",
  "min_temp_c": "minimum survivable temperature in Celsius as a NUMBER (e.g. 10, -5, 4). Use the lowest temperature the plant can survive without damage. For tropical houseplants this is usually 10; for frost-hardy plants like Hedera it is -20. Return a number, not a string."
}}
"""


def _user_prompt(name: str, locale: str, kind: TaxonKind = "genus") -> str:
    language = LOCALE_LANGUAGE_NAMES.get(locale, LOCALE_LANGUAGE_NAMES["en"])
    taxon_label = "Plant family" if kind == "family" else "Plant genus"
    return (
        f"{taxon_label}: {name}. "
        f"Write the botanical overview and care guide in {language} as strict JSON."
    )


def _clean_json_text(text: str) -> str:
    """Strip markdown fences or trailing garbage around JSON."""
    cleaned = text.strip()
    match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", cleaned)
    if match:
        cleaned = match.group(1).strip()
    return cleaned


def _extract_message_content(body: dict[str, Any]) -> str:
    """Return the assistant text from an OpenAI-compatible response.

    OpenRouter (and some gateways) answer HTTP 200 with an
    ``{"error": {...}}`` body when the upstream model is overloaded or
    rate-limited. Treating that as "no choices" hides the real cause and
    makes every retry look identical, so surface the provider error instead.
    """
    err = body.get("error")
    if err:
        if isinstance(err, dict):
            code = err.get("code")
            msg = err.get("message") or str(err)
        else:
            code, msg = None, str(err)
        raise ValueError(f"provider error ({code}): {msg}")
    choices = body.get("choices") or []
    if not choices:
        raise ValueError("No choices returned from LLM API")
    content = choices[0].get("message", {}).get("content") or ""
    if not content.strip():
        raise ValueError("Empty content from LLM API")
    return content


def _request_yandex_gpt(
    name: str, locale: str, kind: TaxonKind = "genus"
) -> dict[str, Any]:
    """Call Yandex Cloud Foundation Models API (YandexGPT)."""
    prompt = system_prompt(locale, kind)
    url = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
    folder_id = settings.yandex_folder_id.strip()
    model = settings.yandex_gpt_model.strip() or "yandexgpt-lite"
    model_uri = (
        model if model.startswith("gpt://")
        else f"gpt://{folder_id}/{model}/latest"
    )

    user_text = _user_prompt(name, locale, kind)
    payload = {
        "modelUri": model_uri,
        "completionOptions": {
            "stream": False,
            "temperature": 0.3,
            "maxTokens": "1000",
        },
        "messages": [
            {
                "role": "system",
                "text": f"{prompt}\nThe response must be a valid JSON object with no extra text.",
            },
            {
                "role": "user",
                "text": user_text,
            },
        ],
    }

    headers: dict[str, str] = {
        "Content-Type": "application/json",
        "Authorization": f"Api-Key {settings.yandex_gpt_api_key}",
    }
    if folder_id:
        headers["x-folder-id"] = folder_id

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = json.loads(resp.read().decode("utf-8"))
        alternatives = body.get("result", {}).get("alternatives", [])
        if not alternatives:
            raise ValueError("No alternatives returned from YandexGPT")
        raw_text = alternatives[0].get("message", {}).get("text", "")
        return json.loads(_clean_json_text(raw_text))


def _request_gemini(
    name: str, locale: str, kind: TaxonKind = "genus"
) -> dict[str, Any]:
    """Call Google Gemini API via REST."""
    prompt = system_prompt(locale, kind)
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{settings.gemini_model}:generateContent?key={settings.gemini_api_key}"
    )
    user_text = _user_prompt(name, locale, kind)
    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [{"text": f"{prompt}\n\n{user_text}"}],
            }
        ],
        "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.3,
        },
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = json.loads(resp.read().decode("utf-8"))
        candidates = body.get("candidates", [])
        if not candidates:
            raise ValueError("No candidates returned from Gemini")
        parts = candidates[0].get("content", {}).get("parts", [])
        if not parts:
            raise ValueError("Empty content from Gemini")
        raw_text = parts[0].get("text", "")
        return json.loads(_clean_json_text(raw_text))


def _request_openai_compatible(
    name: str,
    locale: str,
    api_key: str,
    base_url: str,
    model: str,
    kind: TaxonKind = "genus",
) -> dict[str, Any]:
    """Call OpenAI / DeepSeek / OpenRouter compatible REST API."""
    prompt = system_prompt(locale, kind)
    url = f"{base_url.rstrip('/')}/chat/completions"
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": prompt},
            {
                "role": "user",
                "content": _user_prompt(name, locale, kind),
            },
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.3,
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = json.loads(resp.read().decode("utf-8"))
        return json.loads(_clean_json_text(_extract_message_content(body)))


def _openrouter_models() -> list[str]:
    """Ordered OpenRouter model chain: configured model, then free fallbacks.

    The configured free model is often overloaded and answers with an error
    body; when that happens we retry the next candidate instead of failing the
    whole request. ``OPENROUTER_FALLBACK_MODELS`` (comma-separated) prepends
    explicit choices.
    """
    chain: list[str] = []
    explicit = os.environ.get("OPENROUTER_FALLBACK_MODELS", "")
    for raw in explicit.split(","):
        name = raw.strip()
        if name:
            chain.append(name)
    primary = settings.openrouter_model.strip()
    if primary:
        chain.append(primary)
    for fallback in (
        "nvidia/nemotron-3-super-120b-a12b:free",
        "nvidia/nemotron-3-ultra-550b-a55b:free",
        "nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free",
        "google/gemma-4-31b-it:free",
    ):
        chain.append(fallback)
    seen: set[str] = set()
    return [m for m in chain if not (m in seen or seen.add(m))]


def _request_openrouter(
    name: str, locale: str, kind: TaxonKind = "genus"
) -> dict[str, Any]:
    """Call OpenRouter (free-tier models) via its OpenAI-compatible API."""
    last_error: Exception | None = None
    for model in _openrouter_models():
        try:
            return _request_openai_compatible(
                name,
                locale,
                api_key=settings.openrouter_api_key,
                base_url="https://openrouter.ai/api/v1",
                model=model,
                kind=kind,
            )
        except Exception as e:
            last_error = e
            logger.warning("OpenRouter model %s failed for %s: %s", model, name, e)
    raise last_error or RuntimeError("No OpenRouter model available")


def _generate_care_guide(
    name: str,
    locale: str = "ru",
    kind: TaxonKind = "genus",
) -> dict[str, Any]:
    """Generate botanical care guide using the configured LLM provider."""
    trimmed = name.strip()
    if not trimmed:
        label = "Family" if kind == "family" else "Genus"
        raise ValueError(f"{label} name must not be empty")

    normalized_locale = normalize_locale(locale)
    name_key = "family" if kind == "family" else "genus"

    # 1. Try OpenRouter (free-tier) if configured — preferred over paid DeepSeek.
    if settings.openrouter_api_key:
        try:
            data = _request_openrouter(trimmed, normalized_locale, kind)
            data[name_key] = trimmed
            return data
        except Exception as e:
            logger.warning("OpenRouter generation failed for %s: %s", trimmed, e)

    # 2. Try YandexGPT if configured
    if settings.yandex_gpt_api_key and settings.yandex_folder_id:
        try:
            data = _request_yandex_gpt(trimmed, normalized_locale, kind)
            data[name_key] = trimmed
            return data
        except Exception as e:
            logger.warning("YandexGPT generation failed for %s: %s", trimmed, e)

    # 3. Try Gemini if configured
    if settings.gemini_api_key:
        try:
            data = _request_gemini(trimmed, normalized_locale, kind)
            data[name_key] = trimmed
            return data
        except Exception as e:
            logger.warning("Gemini generation failed for %s: %s", trimmed, e)

    # 4. Try DeepSeek if configured
    if settings.deepseek_api_key:
        try:
            data = _request_openai_compatible(
                trimmed,
                normalized_locale,
                api_key=settings.deepseek_api_key,
                base_url="https://api.deepseek.com",
                model="deepseek-chat",
                kind=kind,
            )
            data[name_key] = trimmed
            return data
        except Exception as e:
            logger.warning("DeepSeek generation failed for %s: %s", trimmed, e)

    # 5. Try OpenAI if configured
    if settings.openai_api_key:
        try:
            data = _request_openai_compatible(
                trimmed,
                normalized_locale,
                api_key=settings.openai_api_key,
                base_url=settings.openai_base_url,
                model=settings.openai_model,
                kind=kind,
            )
            data[name_key] = trimmed
            return data
        except Exception as e:
            logger.warning("OpenAI generation failed for %s: %s", trimmed, e)

    # 6. No provider answered — do NOT fabricate data. Raise so the endpoint
    #    returns an error and nothing is cached. The user explicitly does not
    #    want a mock/fallback that invents care info.
    raise RuntimeError(
        f"No AI provider returned a care guide for {trimmed} ({normalized_locale}). "
        "Check that an AI API key is configured and funded."
    )


def generate_care_guide(genus: str, locale: str = "ru") -> dict[str, Any]:
    """Generate botanical care guide for a plant genus."""
    return _generate_care_guide(genus, locale, kind="genus")


def generate_family_care_guide(family: str, locale: str = "ru") -> dict[str, Any]:
    """Generate botanical care guide for a plant family."""
    return _generate_care_guide(family, locale, kind="family")


def _botanical_prefill_examples(locale: str) -> str:
    """Few-shot examples, in the output language, for the trickiest cases."""
    if locale == "ru":
        return """\
Examples (input → JSON):
- "кротон петра" → {"genus": "Кодиеум", "species": "variegatum", "cultivar": "петра", "plant_family": "Молочайные", "trading_name": "кротон петра", "is_hybrid": false, "variegation": "none"}
- "декабрист" → {"genus": "Шлюмбергера", "species": null, "cultivar": null, "plant_family": "Кактусовые", "trading_name": "декабрист", "is_hybrid": false, "variegation": "none"}
- "щучий хвост" → {"genus": "Сансевиерия", "species": "trifasciata", "cultivar": null, "plant_family": "Спаржевые", "trading_name": "щучий хвост", "is_hybrid": false, "variegation": "none"}
- "денежное дерево" → {"genus": "Толстянка", "species": "ovata", "cultivar": null, "plant_family": "Толстянковые", "trading_name": "денежное дерево", "is_hybrid": false, "variegation": "none"}
- "восковой плющ" → {"genus": "Хойя", "species": "carnosa", "cultivar": null, "plant_family": "Кутровые", "trading_name": "восковой плющ", "is_hybrid": false, "variegation": "none"}
- "фиалка" → {"genus": "Сенполия", "species": null, "cultivar": null, "plant_family": "Геснериевые", "trading_name": "фиалка", "is_hybrid": false, "variegation": "none"}
- "монстера" → {"genus": "Монстера", "species": null, "cultivar": null, "plant_family": "Ароидные", "trading_name": "монстера", "is_hybrid": false, "variegation": "none"}
- "молочай беложилковый" → {"genus": "Молочай", "species": "leuconeura", "cultivar": null, "plant_family": "Молочайные", "trading_name": null, "is_hybrid": false, "variegation": "none"}
"""
    return """\
Examples (input → JSON):
- "Croton Petra" → {"genus": "Codiaeum", "species": "variegatum", "cultivar": "Petra", "plant_family": "Euphorbiaceae", "trading_name": "Croton Petra", "is_hybrid": false, "variegation": "none"}
- "Christmas cactus" → {"genus": "Schlumbergera", "species": null, "cultivar": null, "plant_family": "Cactaceae", "trading_name": "Christmas cactus", "is_hybrid": false, "variegation": "none"}
- "wax plant" → {"genus": "Hoya", "species": "carnosa", "cultivar": null, "plant_family": "Apocynaceae", "trading_name": "wax plant", "is_hybrid": false, "variegation": "none"}
- "African violet" → {"genus": "Saintpaulia", "species": null, "cultivar": null, "plant_family": "Gesneriaceae", "trading_name": "African violet", "is_hybrid": false, "variegation": "none"}
- "money tree" → {"genus": "Crassula", "species": "ovata", "cultivar": null, "plant_family": "Crassulaceae", "trading_name": "money tree", "is_hybrid": false, "variegation": "none"}
"""


def _botanical_prefill_prompt(locale: str) -> str:
    """Build the LLM system prompt for botanical field extraction."""
    language = LOCALE_LANGUAGE_NAMES.get(locale, LOCALE_LANGUAGE_NAMES["en"])
    # Only Russian has an established set of Russian genus names in common use
    # (Монстера, Фикус). English/garden practice uses the Latin genus directly
    # ("Fig" would be wrong — it must stay "Ficus"), so localize genus for ru only.
    if locale == "ru":
        genus_desc = (
            'the TRUE botanical genus in Russian — the localized name gardeners '
            "actually use (e.g. Монстера, Алоказия, Фикус, Замиокулькас, Филодендрон). "
            "NOT the Latin botanical name."
        )
        genus_rule = (
            '- "genus" MUST be the Russian localized genus name (e.g. Монстера, Фикус), '
            "NOT the Latin name — it is shown directly to the user in the app."
        )
    else:
        genus_desc = (
            "the standard Latin genus name in Title Case (e.g. Monstera, Ficus, "
            "Philodendron, Platycerium) — the botanical name, which is what "
            "gardeners use in this language."
        )
        genus_rule = '- "genus" MUST be the standard Latin botanical genus name.'

    examples = _botanical_prefill_examples(locale)

    return f"""\
You are a professional botanist. The user will give a free-text plant name or phrase (e.g. a species, cultivar, or trading name). The phrase may be in {language}, may be partial, and may contain only one of the botanical fields.
Extract the botanical fields and return STRICT JSON without Markdown fences:
{{
  "genus": "{genus_desc} If the phrase only contains a species epithet (e.g. 'bifurcatum'), infer the most likely genus. If truly unknown, return null.",
  "species": "specific epithet in lowercase Latin. If the phrase only contains a genus (e.g. 'Monstera'), return null for species unless a species is clearly stated.",
  "cultivar": "cultivar or variety name exactly as written in the phrase (including quotes if present), or null",
  "plant_family": "botanical family name in {language}, or null if unknown",
  "trading_name": "the original commercial/market name exactly as given by the user, or null",
  "is_hybrid": true if the phrase explicitly describes a hybrid (contains ×, hybrid, or two parent species), otherwise false,
  "variegation": "one of: none, aurea, alba, pink, splash, mint, multicolor, tricolor, unknown. Use the most specific variegation term mentioned in the phrase."
}}

Rules:
- Return only the JSON object. No extra text.
- The input may be a single word, a partial name, a folk/common name, or a trading name in {language}.
{genus_rule}
- "species" keeps the standard Latin botanical form.
- plant_family MUST be in {language}.
- variegation MUST be one of the allowed English values listed above.
- If the phrase is ambiguous or unrecognizable, fill the fields you can confidently determine and leave others null. Never fabricate a genus if you have no idea what the plant is.
- For variegation, map common synonyms to the allowed values (e.g. aurea/golden/yellow → aurea; alba/white → alba; pink/rose → pink; splash/speckled → splash; mint/light green → mint).
- "is_hybrid" should be true only when the phrase itself says it is a hybrid.

CRITICAL — do NOT take the words literally. Many houseplants are sold under TRADE or
FOLK names that disagree with their true genus. Identify the plant that is actually
sold under that name and return its REAL botanical genus, never a genus that merely
matches the word:
- «кротон» / "Croton" as a houseplant is Codiaeum variegatum ("Кодиеум"), genus Кодиеум — NOT genus Croton.
- «декабрист», «рождественник», "Christmas cactus", "Thanksgiving cactus" are Schlumbergera (Шлюмбергера) — NOT a true cactus genus.
- «тещин язык», «щучий хвост», "snake plant" are Dracaena/Sansevieria — NOT an animal.
- «денежное дерево» / "money tree" as a houseplant is Crassula ovata (Толстянка); "money tree" (Pachira) only if the phrase says so.
- «восковой плющ» / "wax plant" is Hoya (Хойя) — NOT Hedera (Плющ).
- «фиалка» / "violet" as a potted houseplant is Saintpaulia (Сенполия / узамбарская фиалка) — NOT true Viola, unless the phrase clearly means a garden viola.
- «герань» as a houseplant usually means Pelargonium; «пеларгония» is also Pelargonium.
- «паучник» / "spider plant" is Chlorophytum comosum — "паучник" is NOT a genus name.
- «кислица» is Oxalis.
- «монстера», "swiss cheese plant" are Monstera.
When the trade name is the only thing given, put it in "trading_name".

{examples}"""


def _request_botanical_prefill_openai_compatible(
    phrase: str,
    locale: str,
    api_key: str,
    base_url: str,
    model: str,
) -> dict[str, Any]:
    """Call an OpenAI-compatible LLM to extract botanical fields."""
    url = f"{base_url.rstrip('/')}/chat/completions"
    prompt = _botanical_prefill_prompt(locale)
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": prompt},
            {"role": "user", "content": f"Plant phrase: {phrase}"},
        ],
        "response_format": {"type": "json_object"},
        "temperature": 0.0,
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": f"Bearer {api_key}",
        },
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = json.loads(resp.read().decode("utf-8"))
        return json.loads(_clean_json_text(_extract_message_content(body)))


def _looks_script_mashed(text: str, expect_cyrillic: bool) -> bool:
    """True if a field mixes scripts when it should not.

    Free models sometimes emit «Апocinовые» (Cyrillic + Latin) for a field that
    must be purely Cyrillic. Such values are worse than a partial answer, so the
    selection step penalizes them.
    """
    has_cyr = any("\u0400" <= ch <= "\u04ff" for ch in text)
    has_lat = any(ch.isascii() and ch.isalpha() for ch in text)
    if expect_cyrillic:
        return has_lat  # Cyrillic field containing Latin letters
    return has_cyr  # Latin field containing Cyrillic letters


def _botanical_prefill_via_openrouter(phrase: str, locale: str) -> dict[str, Any]:
    """Extract botanical fields via OpenRouter, robust to noisy free models.

    Free models are weak at taxonomy and can hallucinate (e.g. «Бифоркатум» →
    Монстера). Majority voting is unsafe here because the weak models make
    correlated mistakes, so instead we walk the chain and return the first
    response that looks both complete and script-clean; otherwise keep the best
    partial across models. The common case returns after the first model
    (~3-5 s) instead of waiting for the slowest.
    """
    expect_cyrillic = locale == "ru"

    def _score(data: dict[str, Any]) -> int:
        score = sum(
            1
            for key in (
                "genus",
                "species",
                "cultivar",
                "plant_family",
                "trading_name",
                "variegation",
            )
            if data.get(key)
        )
        for key in ("genus", "plant_family"):
            value = data.get(key)
            if value and _looks_script_mashed(str(value), expect_cyrillic):
                score -= 3
        return score

    last_error: Exception | None = None
    best: dict[str, Any] | None = None
    best_score = -1
    for model in _openrouter_models():
        try:
            data = _request_botanical_prefill_openai_compatible(
                phrase,
                locale,
                api_key=settings.openrouter_api_key,
                base_url="https://openrouter.ai/api/v1",
                model=model,
            )
        except Exception as e:
            last_error = e
            logger.warning(
                "OpenRouter prefill model %s failed for %s: %s", model, phrase, e
            )
            continue
        score = _score(data)
        # A genus plus real detail, from a script-clean answer, is good enough.
        if data.get("genus") and score >= 3:
            return data
        if score > best_score:
            best, best_score = data, score
    if best is not None:
        return best
    raise last_error or RuntimeError("No OpenRouter model available")


def _request_botanical_prefill_gemini(phrase: str, locale: str) -> dict[str, Any]:
    """Call Google Gemini API to extract botanical fields."""
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{settings.gemini_model}:generateContent?key={settings.gemini_api_key}"
    )
    payload = {
        "contents": [
            {
                "role": "user",
                "parts": [
                    {"text": f"{_botanical_prefill_prompt(locale)}\n\nPlant phrase: {phrase}"}
                ],
            }
        ],
        "generationConfig": {
            "response_mime_type": "application/json",
            "temperature": 0.2,
        },
    }

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers={"Content-Type": "application/json"},
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = json.loads(resp.read().decode("utf-8"))
        candidates = body.get("candidates", [])
        if not candidates:
            raise ValueError("No candidates returned from Gemini")
        parts = candidates[0].get("content", {}).get("parts", [])
        if not parts:
            raise ValueError("Empty content from Gemini")
        raw_text = parts[0].get("text", "")
        return json.loads(_clean_json_text(raw_text))


def _request_botanical_prefill_yandex_gpt(phrase: str, locale: str) -> dict[str, Any]:
    """Call Yandex Cloud Foundation Models API to extract botanical fields."""
    url = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
    folder_id = settings.yandex_folder_id.strip()
    model = settings.yandex_gpt_model.strip() or "yandexgpt-lite"
    model_uri = (
        model if model.startswith("gpt://")
        else f"gpt://{folder_id}/{model}/latest"
    )

    payload = {
        "modelUri": model_uri,
        "completionOptions": {
            "stream": False,
            "temperature": 0.2,
            "maxTokens": "800",
        },
        "messages": [
            {
                "role": "system",
                "text": f"{_botanical_prefill_prompt(locale)}\nThe response must be a valid JSON object with no extra text.",
            },
            {
                "role": "user",
                "text": f"Plant phrase: {phrase}",
            },
        ],
    }

    headers: dict[str, str] = {
        "Content-Type": "application/json",
        "Authorization": f"Api-Key {settings.yandex_gpt_api_key}",
    }
    if folder_id:
        headers["x-folder-id"] = folder_id

    req = urllib.request.Request(
        url,
        data=json.dumps(payload).encode("utf-8"),
        headers=headers,
        method="POST",
    )
    with urllib.request.urlopen(req, timeout=15) as resp:
        body = json.loads(resp.read().decode("utf-8"))
        alternatives = body.get("result", {}).get("alternatives", [])
        if not alternatives:
            raise ValueError("No alternatives returned from YandexGPT")
        raw_text = alternatives[0].get("message", {}).get("text", "")
        return json.loads(_clean_json_text(raw_text))


def _normalize_botanical_prefill(data: dict[str, Any], phrase: str) -> dict[str, Any]:
    """Sanitize and normalize AI-extracted botanical fields."""
    def _str_or_none(value: Any) -> str | None:
        if value is None:
            return None
        text = str(value).strip()
        if text.lower() in ("null", "none", "unknown", "", "n/a"):
            return None
        return text

    genus = _str_or_none(data.get("genus"))
    species = _str_or_none(data.get("species"))
    cultivar = _str_or_none(data.get("cultivar"))
    plant_family = _str_or_none(data.get("plant_family"))
    trading_name = _str_or_none(data.get("trading_name"))
    is_hybrid = bool(data.get("is_hybrid", False))
    variegation = _str_or_none(data.get("variegation"))

    # Genus and family are shown in the app as proper names; the model is
    # inconsistent about casing ("фикус" vs "Фикус"), so normalize for display.
    if genus:
        genus = genus[:1].upper() + genus[1:]
    if plant_family:
        plant_family = plant_family[:1].upper() + plant_family[1:]

    # If the user phrase is a cultivar like "Pink Princess" with no genus,
    # keep trading_name as the phrase so the UI can search again later.
    if trading_name is None and phrase.strip():
        trading_name = phrase.strip()

    return {
        "genus": genus,
        "species": species,
        "cultivar": cultivar,
        "plant_family": plant_family,
        "trading_name": trading_name,
        "is_hybrid": is_hybrid,
        "variegation": variegation,
    }


def generate_botanical_prefill(phrase: str, locale: str = "ru") -> dict[str, Any]:
    """Extract botanical fields from a free-text plant phrase using AI.

    The provider chain mirrors the care-guide generation so deployments that
    already work for genus/family care keep working for prefill.
    """
    trimmed = phrase.strip()
    if not trimmed:
        raise ValueError("Plant phrase must not be empty")

    normalized_locale = normalize_locale(locale)

    # 1. Try OpenRouter (free-tier) if configured.
    if settings.openrouter_api_key:
        try:
            data = _botanical_prefill_via_openrouter(trimmed, normalized_locale)
            return _normalize_botanical_prefill(data, trimmed)
        except Exception as e:
            logger.warning("OpenRouter prefill failed for %s: %s", trimmed, e)

    # 2. Try YandexGPT if configured.
    if settings.yandex_gpt_api_key and settings.yandex_folder_id:
        try:
            data = _request_botanical_prefill_yandex_gpt(trimmed, normalized_locale)
            return _normalize_botanical_prefill(data, trimmed)
        except Exception as e:
            logger.warning("YandexGPT prefill failed for %s: %s", trimmed, e)

    # 3. Try Gemini if configured.
    if settings.gemini_api_key:
        try:
            data = _request_botanical_prefill_gemini(trimmed, normalized_locale)
            return _normalize_botanical_prefill(data, trimmed)
        except Exception as e:
            logger.warning("Gemini prefill failed for %s: %s", trimmed, e)

    # 4. Try DeepSeek if configured.
    if settings.deepseek_api_key:
        try:
            data = _request_botanical_prefill_openai_compatible(
                trimmed,
                normalized_locale,
                api_key=settings.deepseek_api_key,
                base_url="https://api.deepseek.com",
                model="deepseek-chat",
            )
            return _normalize_botanical_prefill(data, trimmed)
        except Exception as e:
            logger.warning("DeepSeek prefill failed for %s: %s", trimmed, e)

    # 5. Try OpenAI if configured.
    if settings.openai_api_key:
        try:
            data = _request_botanical_prefill_openai_compatible(
                trimmed,
                normalized_locale,
                api_key=settings.openai_api_key,
                base_url=settings.openai_base_url,
                model=settings.openai_model,
            )
            return _normalize_botanical_prefill(data, trimmed)
        except Exception as e:
            logger.warning("OpenAI prefill failed for %s: %s", trimmed, e)

    raise RuntimeError(
        f"No AI provider returned a botanical prefill for {trimmed} ({normalized_locale}). "
        "Check that an AI API key is configured and funded."
    )
