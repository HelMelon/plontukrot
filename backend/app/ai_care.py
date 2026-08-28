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
  "toxicity": "brief toxicity info for cats/dogs (or null if safe)"
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


def _mock_care_guide(genus: str, locale: str) -> dict[str, Any]:
    """Fallback draft when no AI API keys are configured."""
    if locale == "en":
        return {
            "genus": genus,
            "origin": f"Plants of the genus {genus} are native mainly to tropical and subtropical regions.",
            "light": "Bright indirect light without harsh midday sun.",
            "watering": "Moderate watering once the top 2–3 cm of soil has dried out.",
            "fertilizing": "Feed with balanced fertilizer every 2–3 weeks during active growth.",
            "soil": "Loose, airy, well-draining substrate with a slightly acidic to neutral pH.",
            "humidity": "Moderate to high humidity (50–70%).",
            "toxicity": None,
        }
    if locale == "de":
        return {
            "genus": genus,
            "origin": f"Pflanzen der Gattung {genus} stammen überwiegend aus tropischen und subtropischen Regionen.",
            "light": "Helles, indirektes Licht ohne direkte Mittagssonne.",
            "watering": "Mäßig gießen, wenn die obersten 2–3 cm des Substrats getrocknet sind.",
            "fertilizing": "Alle 2–3 Wochen während der Wachstumsphase mit Volldünger düngen.",
            "soil": "Lockere, luftige und gut drainierende Erde mit schwach saurer bis neutraler Reaktion.",
            "humidity": "Mäßige bis hohe Luftfeuchtigkeit (50–70 %).",
            "toxicity": None,
        }
    if locale == "fr":
        return {
            "genus": genus,
            "origin": f"Les plantes du genre {genus} sont originaires surtout de régions tropicales et subtropicales.",
            "light": "Lumière vive indirecte, sans soleil direct en milieu de journée.",
            "watering": "Arrosage modéré lorsque les 2–3 cm supérieurs du substrat sont secs.",
            "fertilizing": "Engrais complet toutes les 2–3 semaines pendant la croissance active.",
            "soil": "Substrat léger, aéré et bien drainant, légèrement acide à neutre.",
            "humidity": "Humidité modérée à élevée (50–70 %).",
            "toxicity": None,
        }
    return {
        "genus": genus,
        "origin": f"Растения рода {genus} произрастают преимущественно в тропических и субтропических регионах.",
        "light": "Яркий рассеянный свет без прямых полуденных солнечных лучей.",
        "watering": "Умеренный полив после просыхания верхнего слоя субстрата на 2–3 см.",
        "fertilizing": "Подкормка комплексным удобрением раз в 2–3 недели в период активного роста.",
        "soil": "Рыхлый, воздухо- и влагопроницаемый субстрат со слабокислой или нейтральной реакцией.",
        "humidity": "Умеренная или повышенная влажность воздуха (50–70%).",
        "toxicity": None,
    }


def generate_care_guide(genus: str, locale: str = "ru") -> dict[str, Any]:
    """Generate botanical care guide using the configured LLM provider."""
    trimmed = genus.strip()
    if not trimmed:
        raise ValueError("Genus name must not be empty")

    normalized_locale = normalize_locale(locale)

    # 1. Try YandexGPT if configured
    if settings.yandex_gpt_api_key and settings.yandex_folder_id:
        try:
            data = _request_yandex_gpt(trimmed, normalized_locale)
            data["genus"] = trimmed
            return data
        except Exception as e:
            logger.warning("YandexGPT generation failed for %s: %s", trimmed, e)

    # 2. Try Gemini if configured
    if settings.gemini_api_key:
        try:
            data = _request_gemini(trimmed, normalized_locale)
            data["genus"] = trimmed
            return data
        except Exception as e:
            logger.warning("Gemini generation failed for %s: %s", trimmed, e)

    # 3. Try DeepSeek if configured
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

    # 4. Try OpenAI if configured
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

    # 5. Fallback mock
    logger.info(
        "No AI API keys configured; using botanical fallback for %s (%s)",
        trimmed,
        normalized_locale,
    )
    return _mock_care_guide(trimmed, normalized_locale)
