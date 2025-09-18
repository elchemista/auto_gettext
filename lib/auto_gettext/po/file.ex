defmodule AutoGettext.PO.File do
  @moduledoc """
  Reads a `.po` file, extracts each untranslated snippet,
  sends them as-is to the translator, and patches only those msgstrs.
  """

  require Logger

  @spec translate!(Path.t(), module()) :: :ok
  def translate!(file, translator) do
    lines = File.stream!(file) |> Enum.to_list()
    {missing_ids, idx_map} = collect_missing(lines)

    if missing_ids == [] do
      Logger.info("#{Path.basename(file)} — nothing to translate.")
      :ok
    else
      # build raw PO-snippets for any missing translation
      snippets =
        missing_ids
        |> Enum.map(fn id -> ~s(msgid "#{id}"\nmsgstr "") end)

      locale = locale(file)

      case translator.batch_translate(snippets, locale) do
        :no_translations ->
          Logger.info("#{Path.basename(file)} — nothing to translate (AI produced no matches).")

        pairs ->
          patched =
            patch_lines(lines, idx_map, Map.new(pairs))
            |> IO.iodata_to_binary()

          File.write!(file, patched)
          Logger.info("#{Path.basename(file)} translated (#{length(pairs)}) [#{locale}]")
      end
    end
  end

  # find all blank msgstr lines and map their line numbers to the preceding msgid
  defp collect_missing(lines) do
    Enum.with_index(lines, 1)
    |> Enum.reduce({[], %{}}, fn {line, n}, {ids, map} ->
      if Regex.match?(~r/^msgstr\s+""/, String.trim_trailing(line)) do
        case find_prev_msgid(lines, n - 1) do
          nil -> {ids, map}
          id -> {[id | ids], Map.put(map, n, id)}
        end
      else
        {ids, map}
      end
    end)
  end

  defp find_prev_msgid(_lines, idx) when idx < 1, do: nil

  defp find_prev_msgid(lines, idx) do
    case Enum.at(lines, idx - 1) do
      nil ->
        nil

      line ->
        if Regex.match?(~r/^msgid\s+"/, line) do
          extract(line)
        else
          find_prev_msgid(lines, idx - 1)
        end
    end
  end

  defp patch_lines(lines, idx_map, translations) do
    Enum.with_index(lines, 1)
    |> Enum.map(fn {line, n} ->
      case Map.fetch(idx_map, n) do
        {:ok, id} -> maybe_replace(line, Map.get(translations, id, ""))
        :error -> line
      end
    end)
  end

  defp extract(line) do
    Regex.run(~r/^msgid\s+"(.*)"/, line, capture: :all_but_first)
    |> List.first()
  end

  defp maybe_replace(_line, ""), do: "msgstr \"\"\n"
  defp maybe_replace(_line, tr), do: ~s(msgstr "#{tr}"\n)

  @doc """
  Derives the locale directory from a `.po` file path.
  """
  @spec locale(Path.t()) :: String.t()
  def locale(path) do
    case Regex.run(~r{priv/[^/]+/([^/]+)/}, path) do
      [_, loc] -> loc
      _ -> "unknown"
    end
  end
end
