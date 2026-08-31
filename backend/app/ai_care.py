"""AI generation service for botanical genus care guides."""
from __future__ import annotations

import json
import logging
import re
import urllib.error
import urllib.request
from typing import Any

from .config import settings

logger = logging.getLogger("plontukrot.ai_care")

SUPPORTED_LOCALES = frozenset({"en", "ru", "de", "fr"})

LOCALE_LANGUAGE_NAMES = {
    "ru": "русском",
    "en": "English",
    "de": "German",
    "fr": "French",
}


def normalize_locale(locale: str | None) -> str:
    """Return a supported BCP-47 language code (defaults to Russian)."""
    code = (locale or "ru").strip().lower().split("-")[0]
    return code if code in SUPPORTED_LOCALES else "en"


def system_prompt(locale: str) -> str:
    """Build the LLM system prompt for the requested UI locale."""
    language = LOCALE_LANGUAGE_NAMES.get(locale, LOCALE_LANGUAGE_NAMES["en"])
    return f"""\
You are a professional botanist and indoor plant care expert.
Provide a concise, accurate, and practical care guide for the requested plant genus in {language}.

Reply STRICTLY as JSON without Markdown fences:
{{
  "genus": "genus name",
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


def _user_prompt(genus: str, locale: str) -> str:
    language = LOCALE_LANGUAGE_NAMES.get(locale, LOCALE_LANGUAGE_NAMES["en"])
    return (
        f"Plant genus: {genus}. "
        f"Write the botanical overview and care guide in {language} as strict JSON."
    )


def _clean_json_text(text: str) -> str:
    """Strip markdown fences or trailing garbage around JSON."""
    cleaned = text.strip()
    match = re.search(r"```(?:json)?\s*([\s\S]*?)\s*```", cleaned)
    if match:
        cleaned = match.group(1).strip()
    return cleaned


def _request_yandex_gpt(genus: str, locale: str) -> dict[str, Any]:
    """Call Yandex Cloud Foundation Models API (YandexGPT)."""
    prompt = system_prompt(locale)
    url = "https://llm.api.cloud.yandex.net/foundationModels/v1/completion"
    folder_id = settings.yandex_folder_id.strip()
    model = settings.yandex_gpt_model.strip() or "yandexgpt-lite"
    model_uri = (
        model if model.startswith("gpt://")
        else f"gpt://{folder_id}/{model}/latest"
    )

    user_text = _user_prompt(genus, locale)
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


def _request_gemini(genus: str, locale: str) -> dict[str, Any]:
    """Call Google Gemini API via REST."""
    prompt = system_prompt(locale)
    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{settings.gemini_model}:generateContent?key={settings.gemini_api_key}"
    )
    user_text = _user_prompt(genus, locale)
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
    genus: str,
    locale: str,
    api_key: str,
    base_url: str,
    model: str,
) -> dict[str, Any]:
    """Call OpenAI / DeepSeek / OpenRouter compatible REST API."""
    prompt = system_prompt(locale)
    url = f"{base_url.rstrip('/')}/chat/completions"
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": prompt},
            {
                "role": "user",
                "content": _user_prompt(genus, locale),
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
        choices = body.get("choices", [])
        if not choices:
            raise ValueError("No choices returned from LLM API")
        content = choices[0].get("message", {}).get("content", "")
        return json.loads(_clean_json_text(content))


def _request_openrouter(genus: str, locale: str) -> dict[str, Any]:
    """Call OpenRouter (free-tier models) via its OpenAI-compatible API."""
    return _request_openai_compatible(
        genus,
        locale,
        api_key=settings.openrouter_api_key,
        base_url="https://openrouter.ai/api/v1",
        model=settings.openrouter_model,
    )


def generate_care_guide(genus: str, locale: str = "ru") -> dict[str, Any]:
    """Generate botanical care guide using the configured LLM provider."""
    trimmed = genus.strip()
    if not trimmed:
        raise ValueError("Genus name must not be empty")

    normalized_locale = normalize_locale(locale)

    # 1. Try OpenRouter (free-tier) if configured — preferred over paid DeepSeek.
    if settings.openrouter_api_key:
        try:
            data = _request_openrouter(trimmed, normalized_locale)
            data["genus"] = trimmed
            return data
        except Exception as e:
            logger.warning("OpenRouter generation failed for %s: %s", trimmed, e)

    # 2. Try YandexGPT if configured
    if settings.yandex_gpt_api_key and settings.yandex_folder_id:
        try:
            data = _request_yandex_gpt(trimmed, normalized_locale)
            data["genus"] = trimmed
            return data
        except Exception as e:
            logger.warning("YandexGPT generation failed for %s: %s", trimmed, e)

    # 3. Try Gemini if configured
    if settings.gemini_api_key:
        try:
            data = _request_gemini(trimmed, normalized_locale)
            data["genus"] = trimmed
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
            )
            data["genus"] = trimmed
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
            )
            data["genus"] = trimmed
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
