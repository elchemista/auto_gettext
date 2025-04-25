defmodule Mix.Tasks.Autogettext.Translate do
  use Mix.Task
  require Logger

  @shortdoc "Auto-translates missing msgstr in .po files."

  @impl true
  def run(args) do
    {:ok, _} = Application.ensure_all_started(:httpoison)
    Mix.shell().info("AutoGettext – scanning for untranslated strings…")

    path =
      case args do
        [p | _] -> p
        _ -> "priv/gettext"
      end

    translator_mod =
      Application.get_env(:auto_gettext, :translator_module, AutoGettext.DefaultTranslator)

    Path.join(path, "**/*.po")
    |> Path.wildcard()
    |> Task.async_stream(&translate_file(&1, translator_mod), max_concurrency: 4, ordered: false)
    |> Enum.each(fn
      {:ok, msg} -> Logger.info(msg)
      {:exit, reason} -> Logger.error("Worker crashed: #{inspect(reason)}")
      {:error, reason} -> Logger.error("Failed: #{inspect(reason)}")
    end)
  end

  # -------------------------------------------------------------

  defp translate_file(file_path, translator) do
    lines =
      File.stream!(file_path)
      |> Stream.with_index(1)
      |> Enum.map(fn {line, idx} -> {idx, line} end)

    missing = find_missing(lines)

    if missing == %{} do
      "#{Path.basename(file_path)} — nothing to translate."
    else
      locale = locale_from_path(file_path)
      msgids = Map.keys(missing)
      translations = translator.batch_translate(msgids, locale)

      if translations == :no_translations do
        "#{Path.basename(file_path)} — nothing to translate (AI produced no matches)."
      else
        trans_map = Map.new(translations)

        new_lines =
          Enum.map(lines, fn {n, line} ->
            case Enum.find(missing, fn {_id, idx} -> idx == n end) do
              {id, ^n} ->
                case Map.get(trans_map, id) do
                  # NEW – leave untouched
                  nil -> {n, line}
                  tr -> {n, ~s(msgstr "#{tr}"\n)}
                end

              _ ->
                {n, line}
            end
          end)

        File.write!(file_path, Enum.map_join(new_lines, "", &elem(&1, 1)))
        "#{Path.basename(file_path)} translated (#{map_size(trans_map)}) [#{locale}]"
      end
    end
  end

  defp find_missing(lines) do
    Enum.reduce(lines, %{}, fn {idx, line}, acc ->
      # empty msgstr?
      if String.starts_with?(line, "msgstr") && extract_text(line) == "" do
        {_, prev_line} = Enum.at(lines, idx - 2)
        msgid = extract_text(prev_line)
        Map.put(acc, msgid, idx)
      else
        acc
      end
    end)
  end

  defp locale_from_path(path) do
    case Regex.run(~r{priv/[^/]+/([^/]+)/}, path) do
      [_, locale] -> locale
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
