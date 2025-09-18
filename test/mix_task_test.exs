defmodule Mix.Tasks.AutoGettext.TranslateTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureIO

  @tmp "tmp_po"

  setup_all do
    File.mkdir_p!("#{@tmp}/priv/gettext/es/LC_MESSAGES")
    po = "#{@tmp}/priv/gettext/es/LC_MESSAGES/default.po"

    # realistic PO snippet ➜ comment + msgid + empty msgstr
    File.write!(po, """
    #: lib/demo.ex:1
    msgid "Hi"
    msgstr ""
    """)

    on_exit(fn -> File.rm_rf!(@tmp) end)
    {:ok, po: po}
  end

  setup do
    Application.put_env(:auto_gettext, :ignored_locales, [])
    :ok
  end

  test "fills missing strings", %{po: po} do
    # deterministic stub used by the Mix task; now works with raw PO snippets
    defmodule Stub do
      @behaviour AutoGettext.Translator
      def batch_translate(snippets, _locale) do
        Enum.map(snippets, fn snippet ->
          case Regex.run(~r/msgid\s+"([^"]+)"/, snippet) do
            [_, id] -> {id, "Hola"}
            _ -> {snippet, "Hola"}
          end
        end)
      end
    end

    Application.put_env(:auto_gettext, :translator_module, Stub)

    capture_io(fn ->
      Mix.Tasks.AutoGettext.Translate.run([@tmp <> "/priv/gettext"])
    end)

    assert File.read!(po) =~ ~r/msgstr\s+"Hola"/

    Application.delete_env(:auto_gettext, :translator_module)
  end

  test "skips locales configured to be ignored", %{po: _po} do
    File.mkdir_p!("#{@tmp}/priv/gettext/en/LC_MESSAGES")
    en_po = "#{@tmp}/priv/gettext/en/LC_MESSAGES/default.po"

    File.write!(en_po, """
    msgid "Hi"
    msgstr ""
    """)

    defmodule SkipStub do
      @behaviour AutoGettext.Translator
      def batch_translate(_snippets, _locale), do: [{"Hi", "Hello"}]
    end

    Application.put_env(:auto_gettext, :translator_module, SkipStub)
    Application.put_env(:auto_gettext, :ignored_locales, ["en"])

    capture_io(fn ->
      Mix.Tasks.AutoGettext.Translate.run([@tmp <> "/priv/gettext"])
    end)

    assert File.read!(en_po) =~ ~r/msgstr\s+""/
    Application.delete_env(:auto_gettext, :translator_module)
    Application.delete_env(:auto_gettext, :ignored_locales)
  end
end
