defmodule AutoGettext.API.OpenAI do
  @moduledoc """
  Implementation of `AutoGettext.APIService` that targets OpenAI Chat Completions
  (aka ChatGPT) API.

  The module reads configuration from the `:auto_gettext` application environment:

    * `:openai_api_key` (or `OPENAI_API_KEY` env var fallback)
    * `:openai_model` (defaults to `"gpt-4o-mini"`)
    * `:openai_url` (defaults to the public Chat Completions endpoint)
    * `:openai_temperature` (defaults to `0.0` for deterministic output)
  """

  @behaviour AutoGettext.APIService

  require Logger

  @default_url "https://api.openai.com/v1/chat/completions"

  @impl true
  def get(prompt) when is_binary(prompt) do
    key =
      Application.get_env(:auto_gettext, :openai_api_key) ||
        System.get_env("OPENAI_API_KEY") ||
        raise "OpenAI API key not configured - set :openai_api_key or OPENAI_API_KEY."

    url = Application.get_env(:auto_gettext, :openai_url, @default_url)
    model = Application.get_env(:auto_gettext, :openai_model, "gpt-4o-mini")
    temperature = Application.get_env(:auto_gettext, :openai_temperature, 0.0)

    body =
      %{
        model: model,
        temperature: temperature,
        messages: [%{role: "user", content: prompt}]
      }
      |> Jason.encode!()

    headers = [
      {"Content-Type", "application/json"},
      {"Authorization", "Bearer #{key}"}
    ]

    case HTTPoison.post(url, body, headers, timeout: 120_000, recv_timeout: 120_000) do
      {:ok, %{status_code: 200, body: json}} ->
        case Jason.decode(json) do
          {:ok, %{"choices" => [%{"message" => %{"content" => content}} | _]}} ->
            content

          other ->
            Logger.error("OpenAI unexpected response: #{inspect(other)}")
            raise "OpenAI gave an unexpected response – check logs."
        end

      {:ok, %{status_code: code, body: body}} ->
        Logger.error("OpenAI error (#{code}): #{body}")
        raise "OpenAI returned HTTP #{code}."

      {:error, err} ->
        Logger.error("OpenAI HTTP error: #{inspect(err)}")
        raise "Could not reach OpenAI API."
    end
  end
end
