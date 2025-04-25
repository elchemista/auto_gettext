defmodule AutoGettext do
  @moduledoc """
  High-level helper entry points for *AutoGettext*.

      iex> AutoGettext.translate_missing!("priv/gettext")
      :ok
  """

  alias AutoGettext.GeminiTranslator
  alias AutoGettext.PO.File, as: POFile

  @doc """
  Walks every `.po` under `root` and fills missing `msgstr`s by delegating to
  the configured `Translator` module. Returns `:ok`.
  """
  @spec translate_missing!(Path.t()) :: :ok
  def translate_missing!(root \\ "priv/gettext") do
    translator =
      Application.get_env(:auto_gettext, :translator_module, GeminiTranslator)

    Path.join(root, "**/*.po")
    |> Path.wildcard()
    |> Task.async_stream(&POFile.translate!(&1, translator), max_concurrency: 4, ordered: false)
    |> Stream.run()

    :ok
  end
end
