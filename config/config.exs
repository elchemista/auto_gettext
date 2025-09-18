import Config

config :auto_gettext,
  # Which module actually calls the LLM.
  api_service: AutoGettext.API.Gemini,
  # API key used by the default Gemini implementation (falls back to GOOGLE_API_KEY env).
  api_key: System.get_env("GOOGLE_API_KEY"),
  # OpenAI chat completions configuration.
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  openai_model: "gpt-4o-mini",
  openai_url: "https://api.openai.com/v1/chat/completions",
  openai_temperature: 0.0,
  # Which translator Mix task should use by default.
  translator_module: AutoGettext.GeminiTranslator,
  # Locales that should not be touched (directories under priv/gettext/*).
  ignored_locales: [],
  # Prompt template (override per-proj if you like).
  prompt_template: """
  You are an i18n assistant. For each untranslated string output a
  Gettext PO snippet in {{locale}} **exactly** like:

  msgid "Original"
  msgstr "Translation"

  Do not wrap the answer in markdown or JSON, do not add comments.
  """,
  # Additional project-specific context appended after the template.
  prompt_context: nil,
  # Gemini model (only for the bundled implementation).
  gemini_model: "gemini-2.0-flash"
