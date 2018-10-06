defmodule TasKafka.MixProject do
  use Mix.Project

  @version "0.0.2"

  def project do
    [
      app: :taskafka,
      version: @version,
      elixir: "~> 1.6",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [] ++ Mix.compilers(),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test],
      description:
        "TasKafka is a background processing application written in Elixir and uses Kafka as a messaging backend.",
      package: package(),
      name: "TasKafka",
      docs: docs()
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [
      extra_applications: [:logger],
      mod: {TasKafka.Application, []}
    ]
  end

  defp deps do
    [
      {:jason, "~> 1.1"},
      {:kafka_ex, "~> 0.8"},
      {:mongodb, "== 0.4.6"},
      {:poolboy, "~> 1.5"},
      {:vex, "~> 0.8.0"},
      {:ex_doc, ">= 0.0.0", only: :dev},
      {:credo, "~> 0.10.0", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: "taskafka",
      contributors: ["Edenlab LLC"],
      maintainers: ["Edenlab LLC"],
      source_ref: "v#{@version}",
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/edenlabllc/taskafka"},
      files: ~w(mix.exs .formatter.exs lib LICENSE.md README.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#\{@version\}",
      source_url: "https://github.com/edenlabllc/taskafka",
      extras: ["README.md"]
    ]
  end
end
