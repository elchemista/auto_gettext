defmodule Mix.Tasks.Autogettext.Translate do
  use Mix.Task
  require Logger

  alias AutoGettext.DefaultTranslator

  @shortdoc "Auto-translates missing msgstr in .po files."

  def run(args) do
    path =
      case args do
        [p | _] -> p
        _ -> "priv/gettext"
      end

    Path.join(path, "**/*.po")
    |> Path.wildcard()
    |> Task.async_stream(&translate_file/1, max_concurrency: 4, ordered: false)
    |> Enum.each(fn
      {:ok, message} -> Logger.info(message)
      {:error, reason} -> Logger.error("Failed translating file: #{inspect(reason)}")
    end)
  end

  defp translate_file(file_path) do
    lines =
      File.stream!(file_path)
      |> Stream.with_index(1)
      |> Enum.map(fn {line, index} -> {index, line} end)

    missing_map = find_missing_translations(lines)

    if map_size(missing_map) > 0 do
      locale = extract_locale(file_path)
      msgids = Map.keys(missing_map)
      translations = DefaultTranslator.batch_translate(msgids, locale) |> Map.new()

      updated_lines =
        Enum.map(lines, fn {i, line} ->
          case Enum.find(missing_map, fn {_msgid, idx} -> idx == i end) do
            {msgid, _line_idx} ->
              {i, ~s(msgstr "#{Map.get(translations, msgid, "")}"\n)}

            nil ->
              {i, line}
          end
        end)

      File.write!(file_path, Enum.map(updated_lines, &elem(&1, 1)))

      "#{Path.basename(file_path)} translated — (#{map_size(missing_map)}) new translations [#{String.upcase(locale)}]"
    else
      "#{Path.basename(file_path)} — no missing translations [#{String.upcase(extract_locale(file_path))}]"
    end
  end

  defp find_missing_translations(lines) do
    Enum.reduce(lines, %{}, fn {i, line}, acc ->
      if String.starts_with?(line, "msgstr") and extract_text(line) == "" do
        prev_line_text = extract_text(elem(Enum.at(lines, i - 2), 1))
        Map.put(acc, prev_line_text, i)
      else
        acc
      end
    end)
  end

  defp extract_locale(file_path) do
    case Regex.run(~r{gettext/([^/]+)/}, file_path) do
      [_, loc] -> loc
      _ -> "unknown"
    end
  end

  defp extract_text(line) do
    case Regex.run(~r/^msg(?:id|str)\s+"(.*)"/, line) do
      [_, text] -> text
      _ -> ""
    end
  end
end
