defmodule AutoGettext.GeminiTranslator do
  @moduledoc """
  Default Translator that calls an LLM and expects PO-formatted snippets back.
  """

  @behaviour AutoGettext.Translator
  alias AutoGettext.{PO.Parser, API}

  @default_prompt """
  You are an i18n assistant. Translate each msgid into **{{locale}}**.
  Respond with plain snippets - no markdown fences:

  msgid "Original"
  msgstr "Translation"
  """

  @impl true
  def batch_translate([], _loc), do: []

  def batch_translate(msgids, locale) do
    api = Application.get_env(:auto_gettext, :api_module, API.Gemini)

    prompt =
      Application.get_env(:auto_gettext, :prompt_template_po, @default_prompt)
      |> String.replace("{{locale}}", locale)
      |> Kernel.<>("\n\n")
      |> Kernel.<>(Enum.map_join(msgids, "\n\n", &~s(msgid "#{&1}"\nmsgstr "")))

    with raw when is_binary(raw) <- api.get(prompt),
         cleaned = sanitize(raw),
         {:ok, pairs} <- Parser.parse(cleaned) do
      pairs
    else
      _ -> :no_translations
    end
  end

  defp sanitize(text) do
    text
    |> String.trim()
    |> String.replace(~r/^```(?:po|text)?\s*|\s*```$/m, "")
    |> String.trim()
  end
end
