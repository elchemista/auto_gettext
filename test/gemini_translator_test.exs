defmodule AutoGettext.GeminiTranslatorTest do
  use ExUnit.Case, async: true

  defmodule DummyAPI do
    @behaviour AutoGettext.API
    def get(_prompt), do: "msgid \"Ping\"\nmsgstr \"Pong\""
  end

  setup do
    Application.put_env(:auto_gettext, :api_module, DummyAPI)
    :ok
  end

  test "returns translations list" do
    assert [{"Ping", "Pong"}] = AutoGettext.GeminiTranslator.batch_translate(["Ping"], "es")
  end
end
