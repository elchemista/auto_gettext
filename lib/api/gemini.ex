defmodule AutoGettext.API.Gemini do
  @moduledoc """
  Thin wrapper around Google Gemini *chat* completions that implements
  `AutoGettext.API`.

  It expects `GOOGLE_API_KEY` in the environment (same var the official SDK
  uses) and returns **only the assistant’s `content` string**.
  """

  @behaviour AutoGettext.API
  require Logger
  @url "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"

  @impl true
  def get(prompt) when is_binary(prompt) do
    key =
      System.get_env("GOOGLE_API_KEY") ||
        raise "GOOGLE_API_KEY not set – cannot contact Gemini."

    body =
      %{
        model: Application.get_env(:auto_gettext, :gemini_model, "gemini-2.0-flash"),
        stream: false,
        messages: [%{role: "user", content: prompt}]
      }
      |> Jason.encode!()

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{key}"}
    ]

    case HTTPoison.post(@url, body, headers, timeout: 120_000, recv_timeout: 120_000) do
      {:ok, %{status_code: 200, body: json}} ->
        case Jason.decode(json) do
          {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
            content

          other ->
            Logger.error("Gemini unexpected response: #{inspect(other)}")
            raise "Gemini gave an unexpected response – check logs."
        end

      {:ok, %{status_code: code, body: body}} ->
        Logger.error("Gemini error (#{code}): #{body}")
        raise "Gemini returned HTTP #{code}."

      {:error, err} ->
        Logger.error("Gemini HTTP error: #{inspect(err)}")
        raise "Could not reach Gemini API."
    end
  end
end
