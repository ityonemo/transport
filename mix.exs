defmodule Transport.MixProject do
  use Mix.Project

  def project do
    [
      app: :transport,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      package: package(),
      description: "an abstraction api and helpers for TCP and TLS",
      # DOCS
      source_url: "https://github.com/ityonemo/transport/",
      docs: docs()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:credo, "~> 1.2", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 0.5.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test},
      {:x509, "~> 0.8.0", only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package, do: [
    name: "transport",
    licenses: ["MIT"],
    files: ~w(lib mix.exs README* LICENSE* VERSIONS*),
    links: %{"GitHub" => "https://github.com/ityonemo/transport"}
  ]

  defp docs, do: [
    main: "Transport",
    groups_for_functions: [
      "Server Functions": &(&1[:section] == :server),
      "Client Functions": &(&1[:section] == :client),
    ]
  ]

end
