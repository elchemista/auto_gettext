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

```elixir
config :auto_gettext,
  api_service: AutoGettext.API.Gemini,
  api_key: System.get_env("GOOGLE_API_KEY"),
  translator_module: AutoGettext.GeminiTranslator,
  gemini_model: "gemini-2.0-flash",
  ignored_locales: ["en"],
  prompt_template: "...override prompt…",
  prompt_context: "Our product is a developer tool"
```

`api_key` is required by the bundled Gemini adapter. If you prefer to keep the
credential outside of the config you can leave it as `nil` and rely on the
`GOOGLE_API_KEY` environment variable instead.
