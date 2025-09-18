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
  prompt_context: "Our product is a developer tool",
```

`api_key` is required by the bundled Gemini adapter. If you prefer to keep the
credential outside of the config you can leave it as `nil` and rely on the
`GOOGLE_API_KEY` environment variable instead.

To switch the translator to ChatGPT simply point `:api_service` to the new
adapter:

```elixir
config :auto_gettext,
  api_service: AutoGettext.API.OpenAI,
  openai_api_key: System.get_env("OPENAI_API_KEY"),
  openai_model: "gpt-4o-mini",
  openai_temperature: 0.0
```

## Translators & Custom Services

AutoGettext separates the responsibilities of **translator** and **API service**:

- A translator (module implementing `AutoGettext.Translator`) prepares prompts
  and parses the response. The bundled translator is `AutoGettext.GeminiTranslator`.
- An API service (module implementing `AutoGettext.APIService`) performs the HTTP
  call to an LLM provider. Bundled options are `AutoGettext.API.Gemini` and
  `AutoGettext.API.OpenAI`.

When the Mix task runs it loads the configured `:translator_module`, which in
turn calls the configured `:api_service`. If you want to plug in your own
service:

```elixir
defmodule MyApp.APIService do
  @behaviour AutoGettext.APIService

  @impl true
  def get(prompt) do
    # call your provider of choice and return the raw text reply
  end
end

config :auto_gettext,
  api_service: MyApp.APIService
```

To change the translator completely implement the behaviour and set
`:translator_module` in config:

```elixir
defmodule MyApp.FancyTranslator do
  @behaviour AutoGettext.Translator

  @impl true
  def batch_translate(snippets, locale) do
    # Build your own prompt, call an API service, parse the response, and return
    # a list of {msgid, msgstr} tuples. Return :no_translations when appropriate.
  end
end

config :auto_gettext,
  translator_module: MyApp.FancyTranslator
```
