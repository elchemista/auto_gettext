defmodule AutoGettext.GeminiTranslator do
  @moduledoc """
  Translator that sends raw PO snippets to Gemini and expects only PO snippets back.
  """

  @behaviour AutoGettext.Translator
  alias AutoGettext.{PO.Parser, API}

  @default_prompt """
  You are an i18n assistant. Translate each PO snippet into **{{locale}}**.
  Respond _only_ with PO‐formatted snippets—no markdown fences or extra text:

  msgid "Original"
  msgstr "Translation"
  """

  @impl true
  def batch_translate([], _loc), do: []

  def batch_translate(snippets, locale) do
    api = Application.get_env(:auto_gettext, :api_module, API.Gemini)

    prompt =
      Application.get_env(:auto_gettext, :prompt_template_po, @default_prompt)
      |> String.replace("{{locale}}", locale)
      |> Kernel.<>("\n\n")
      |> Kernel.<>(Enum.join(snippets, "\n\n"))

    with raw when is_binary(raw) <- api.get(prompt),
         cleaned = sanitize(raw),
         {:ok, pairs} <- Parser.parse(cleaned) do
      pairs
    else
      _ -> :no_translations
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
