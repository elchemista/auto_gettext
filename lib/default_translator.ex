defmodule AutoGettext.DefaultTranslator do
  @behaviour AutoGettext.Translator
  require Logger

  @default_prompt_po """
  You are an i18n assistant. Translate every msgid into **{{locale}}**.
  Respond with plain Gettext snippets – no markdown:

  msgid "Original"
  msgstr "Translation"
  """

  @impl true
  def batch_translate([], _), do: []

  def batch_translate(msgids, locale) do
    api_mod = Application.get_env(:auto_gettext, :api_module, AutoGettext.API.Gemini)

    prompt_template =
      Application.get_env(:auto_gettext, :prompt_template_po, @default_prompt_po)

    prompt =
      prompt_template
      |> String.replace("{{locale}}", locale)
      |> Kernel.<>("\n\n")
      |> Kernel.<>(Enum.map_join(msgids, "\n\n", &~s(msgid "#{&1}"\nmsgstr "")))

    with raw when is_binary(raw) <- api_mod.get(prompt),
         cleaned = sanitize(raw),
         {:ok, pairs} <- parse_po(cleaned) do
      pairs
    else
      {:error, :no_matches} ->
        :no_translations

      {:error, reason} ->
        Logger.error("PO-parse failed: #{inspect(reason)}")
        :no_translations

      other ->
        Logger.error("AI translator unexpected: #{inspect(other)}")
        :no_translations
    end
  end

  defp sanitize(resp) do
    resp
    |> String.trim()
    |> String.replace(~r/^```(?:po|text)?\s*|\s*```$/m, "")
    |> String.trim()
  end

  @po_pair ~r/msgid\s+"(?<id>(?:\\.|[^"])*)"\s*msgstr\s+"(?<tr>(?:\\.|[^"])*)"/

  defp parse_po(text) do
    captures =
      Regex.scan(@po_pair, text, capture: :all_but_first, trim: true)
      |> Enum.map(fn [id, tr] ->
        {unescape(id), unescape(tr)}
      end)

    if captures == [], do: {:error, :no_matches}, else: {:ok, captures}
  end

  defp unescape(str) do
    str
    |> String.replace(~S(\"), ~s("))
    |> String.replace(~S(\\n), "\n")
  end
end
