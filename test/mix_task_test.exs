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

  test "fills missing strings", %{po: po} do
    # deterministic stub used by the Mix task
    defmodule Stub do
      @behaviour AutoGettext.Translator
      def batch_translate(ids, _locale), do: for(id <- ids, do: {id, "Hola"})
    end

    Application.put_env(:auto_gettext, :translator_module, Stub)

    capture_io(fn ->
      Mix.Tasks.AutoGettext.Translate.run([@tmp <> "/priv/gettext"])
    end)

    assert File.read!(po) =~ ~r/msgstr\s+"Hola"/
  end
end
