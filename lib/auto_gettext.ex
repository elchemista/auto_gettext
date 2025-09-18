defmodule AutoGettext do
  @moduledoc """
  High-level helper entry points for *AutoGettext*.

      iex> AutoGettext.translate_missing!("priv/gettext")
      :ok
  """

  require Logger

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

    ignored_locales =
      :auto_gettext
      |> Application.get_env(:ignored_locales, [])
      |> Enum.map(&to_string/1)
      |> MapSet.new()

    Path.join(root, "**/*.po")
    |> Path.wildcard()
    |> Enum.reject(fn file ->
      locale = POFile.locale(file)
      locale != "unknown" and MapSet.member?(ignored_locales, locale)
    end)
    |> Task.async_stream(
      fn file ->
        try do
          POFile.translate!(file, translator)
          :ok
        rescue
          e in [HTTPoison.Error] ->
            Logger.error("#{file} - #{inspect(e)}")
            :error
        end
      end,
      max_concurrency: 4,
      ordered: false,
      timeout: 500_000,
      on_timeout: :kill_task
    )
    |> Stream.run()

    :ok
  end
end
