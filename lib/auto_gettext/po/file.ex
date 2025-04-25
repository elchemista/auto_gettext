defmodule AutoGettext.PO.File do
  @moduledoc """
  Reads a `.po` file, finds blank `msgstr ""`, asks a translator for the
  missing strings, then writes the patched file back.
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
      locale = locale_from_path(file)

      case translator.batch_translate(missing_ids, locale) do
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

  defp collect_missing(lines) do
    Enum.with_index(lines, 1)
    |> Enum.reduce({[], %{}}, fn {line, n}, {ids, map} ->
      if blank_msgstr?(line) do
        case find_prev_msgid(lines, n - 2) do
          nil -> {ids, map}
          id -> {[id | ids], Map.put(map, n, id)}
        end
      else
        {ids, map}
      end
    end)
  end

  # Look upward for the nearest msgid line
  defp find_prev_msgid(_lines, idx) when idx < 0, do: nil

  defp find_prev_msgid(lines, idx) do
    case Enum.at(lines, idx) do
      nil ->
        nil

      line ->
        if msgid_line?(line) do
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

  defp blank_msgstr?(line),
    do: Regex.match?(~r/^msgstr\s+""\s*$/, String.trim_trailing(line))

  defp msgid_line?(line),
    do: Regex.match?(~r/^msgid\s+"/, line)

  defp locale_from_path(path) do
    case Regex.run(~r{priv/[^/]+/([^/]+)/}, path) do
      [_, loc] -> loc
      _ -> "unknown"
    end
  end

  defp extract(line) do
    Regex.run(~r/^msg(?:id|str)\s+"(.*)"/, line, capture: :all_but_first)
    |> List.first()
    |> case do
      nil -> ""
      str -> str
    end
  end

  defp maybe_replace(line, ""), do: line
  defp maybe_replace(_line, tr), do: ~s(msgstr "#{tr}"\n)
end
