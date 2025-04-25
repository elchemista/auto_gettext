defmodule AutoGettext.MixProject do
  use Mix.Project

  def project do
    [
      app: :auto_gettext,
      version: "0.1.0",
      elixir: "~> 1.16",
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  def application do
    [
      extra_applications: [:logger, :ssl, :httpoison, :hackney]
    ]
  end

  defp deps do
    [
      {:gettext, "~> 0.24"},
      {:jason, "~> 1.4"},
      {:httpoison, "~> 2.2"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test}
    ]
  end
end
