# AutoGettext

Batteries-included Mix task that scans your `priv/gettext/**/*.po`, detects
empty `msgstr ""`, asks an LLM for translations, and writes the results back.

```bash
# translate everything using the default Gemini adapter
$ mix auto_gettext.translate
# or point it somewhere else
$ mix auto_gettext.translate custom/path
```

## Installation

Add `auto_gettext` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
   {:auto_gettext, "~> 0.1.0",
       github: "elchemista/auto_gettext", branch: "master", only: :dev, runtime: false},
  ]
end
```

## Configuration

**Required**: `GOOGLE_API_KEY` env var.

```elixir
config :auto_gettext,
  api_module: AutoGettext.API.Gemini,
  translator_module: AutoGettext.GeminiTranslator,
  gemini_model: "gemini-2.0-flash",
  prompt_template_po: "...override prompt…"
```
