defmodule AutoGettext.MixProject do
  use Mix.Project

  def project do
    [
      app: :auto_gettext,
      name: "AutoGettext",
      version: "0.1.0",
      elixir: "~> 1.16",
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      description: description(),
      package: package(),
      docs: [
        master: "readme",
        extras: [
          "README.md",
          "LICENSE"
        ]
      ],
      source_url: "https://github.com/elchemista/auto_gettext",
      homepage_url: "https://github.com/elchemista/auto_gettext"
    ]
  end

  defp description() do
    "Automatic gettext translations for Elixir projects using LLMs Services (OpenAI, Google, etc.)"
  end

  defp package() do
    [
      name: "auto_gettext",
      maintainers: ["Yuriy Zhar"],
      files: ~w(mix.exs README.md lib test LICENSE .formatter.exs),
      licenses: ["Apache-2.0"],
      links: %{
        "GitHub" => "https://github.com/elchemista/auto_gettext"
      }
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
      {:httpoison, "~> 2.0"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.18", only: :test},
      {:bypass, "~> 2.1", only: :test}
    ]
  end
end
