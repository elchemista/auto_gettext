defmodule AutoGettext.API.Gemini do
  @moduledoc """
  Thin wrapper around Google Gemini *chat* completions that implements
  `AutoGettext.APIService`.

  The API key is read from `Application.get_env(:auto_gettext, :api_key)` and
  falls back to the `GOOGLE_API_KEY` env var for backwards compatibility.
  The function returns **only the assistant’s `content` string**.
  """

  @behaviour AutoGettext.APIService
  require Logger
  @url "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"

  @impl true
  def get(prompt) when is_binary(prompt) do
    key =
      Application.get_env(:auto_gettext, :api_key) ||
        System.get_env("GOOGLE_API_KEY") ||
        raise "Gemini API key not configured - set :api_key or GOOGLE_API_KEY."

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
