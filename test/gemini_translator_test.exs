defmodule AutoGettext.GeminiTranslatorTest do
  @moduledoc false
  use ExUnit.Case, async: true

  defmodule DummyAPI do
    @moduledoc false
    @behaviour AutoGettext.APIService

    def get(_prompt), do: "msgid \"Ping\"\nmsgstr \"Pong\""
  end

  setup do
    Application.put_env(:auto_gettext, :api_service, DummyAPI)
    :ok
  end

  test "returns translations list" do
    assert [{"Ping", "Pong"}] = AutoGettext.GeminiTranslator.batch_translate(["Ping"], "es")
  end

  test "applies optional prompt context" do
    Process.put(:test_pid, self())

    defmodule CaptureAPI do
      @moduledoc false
      @behaviour AutoGettext.APIService

      def get(prompt) do
        send(Process.get(:test_pid), {:prompt, prompt})
        "msgid \"Ping\"\nmsgstr \"Pong\""
      end
    end

    Application.put_env(:auto_gettext, :api_service, CaptureAPI)
    Application.put_env(:auto_gettext, :prompt_context, "Project: {{locale}}")

    AutoGettext.GeminiTranslator.batch_translate(["Ping"], "fr")

    assert_receive {:prompt, prompt}
    assert prompt =~ "Project: fr"

    Application.delete_env(:auto_gettext, :prompt_context)
  end
end
