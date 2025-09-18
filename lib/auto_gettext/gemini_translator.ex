defmodule AutoGettext.GeminiTranslator do
  @moduledoc """
  Translator that sends raw PO snippets to Gemini and expects only PO snippets back.
  """

  @behaviour AutoGettext.Translator
  alias AutoGettext.PO.Parser

  @default_prompt """
  You are an i18n assistant. Translate each PO snippet into **{{locale}}**.
  Respond _only_ with PO‐formatted snippets—no markdown fences or extra text:

  msgid "Original"
  msgstr "Translation"
  """

  @impl true
  def batch_translate([], _loc), do: []

  def batch_translate(snippets, locale) do
    api = Application.get_env(:auto_gettext, :api_service, AutoGettext.API.Gemini)

    base_prompt =
      Application.get_env(:auto_gettext, :prompt_template, @default_prompt)
      |> String.replace("{{locale}}", locale)

    context =
      Application.get_env(:auto_gettext, :prompt_context)
      |> to_prompt_context(locale)

    prompt =
      [base_prompt, context, Enum.join(snippets, "\n\n")]
      |> Enum.reject(&(&1 in [nil, ""]))
      |> Enum.join("\n\n")

    with raw when is_binary(raw) <- api.get(prompt),
         cleaned = sanitize(raw),
         {:ok, pairs} <- Parser.parse(cleaned) do
      pairs
    else
      _ -> :no_translations
    end
  end

  defp to_prompt_context(nil, _locale), do: nil

  defp to_prompt_context(context, locale) do
    context
    |> to_string()
    |> String.trim()
    |> case do
      "" -> nil
      txt -> String.replace(txt, "{{locale}}", locale)
    end
  end

  defp sanitize(txt) do
    txt
    |> String.trim()
    # drop any ```…``` code fences (keep their contents)
    |> String.replace(~r/```[^\n]*\n([\s\S]*?)```/ms, "\\1")
    # drop any leading "> " on each line
    |> String.replace(~r/^[>\s]+/m, "")
    |> String.trim()
  end
end
