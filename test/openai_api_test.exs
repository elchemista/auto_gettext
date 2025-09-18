defmodule AutoGettext.API.OpenAITest do
  @moduledoc false
  use ExUnit.Case, async: true

  alias Plug.Conn

  setup do
    bypass = Bypass.open()

    Application.put_env(
      :auto_gettext,
      :openai_url,
      "http://localhost:#{bypass.port}/v1/chat/completions"
    )

    Application.put_env(:auto_gettext, :openai_api_key, "secret")

    on_exit(fn ->
      Application.delete_env(:auto_gettext, :openai_url)
      Application.delete_env(:auto_gettext, :openai_api_key)
    end)

    {:ok, bypass: bypass}
  end

  test "returns assistant message content", %{bypass: bypass} do
    Bypass.expect(bypass, fn conn ->
      assert "/v1/chat/completions" == conn.request_path
      assert "POST" == conn.method

      {:ok, body, conn} = Conn.read_body(conn)
      payload = Jason.decode!(body)

      assert payload["model"] == "gpt-4o-mini"
      assert [%{"role" => "user", "content" => "Hello"}] = payload["messages"]

      response = %{
        id: "chatcmpl-123",
        choices: [
          %{
            "message" => %{"content" => "msgid \"Ping\"\nmsgstr \"Pong\""}
          }
        ]
      }

      Conn.resp(conn, 200, Jason.encode!(response))
    end)

    assert AutoGettext.API.OpenAI.get("Hello") == "msgid \"Ping\"\nmsgstr \"Pong\""
  end

  test "raises when OpenAI replies with an error", %{bypass: bypass} do
    Bypass.expect_once(bypass, fn conn ->
      Conn.resp(conn, 500, ~s({"error":"boom"}))
    end)

    assert_raise RuntimeError, ~r/OpenAI returned HTTP 500/, fn ->
      AutoGettext.API.OpenAI.get("Hi")
    end
  end
end
