import Config

config :auto_gettext,
  # Which module actually calls the LLM.
  api_module: AutoGettext.API.Gemini,
  # Which translator Mix task should use by default.
  translator_module: AutoGettext.GeminiTranslator,
  # Prompt template (override per-proj if you like).
  prompt_template: """
  You are an i18n assistant. For each untranslated string output a
  Gettext PO snippet in {{locale}} **exactly** like:

  msgid "Original"
  msgstr "Translation"

  Do not wrap the answer in markdown or JSON, do not add comments.
  """,
  # Gemini model (only for the bundled implementation).
  gemini_model: "gemini-2.0-flash"
