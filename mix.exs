defmodule Transport.MixProject do
  use Mix.Project

  def project do
    [
      app: :transport,
      version: "0.1.0",
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application, do: [extra_applications: [:logger]]

  defp deps do
    [
      {:credo, "~> 1.2", only: [:test, :dev], runtime: false},
      {:dialyxir, "~> 0.5.1", only: :dev, runtime: false},
      {:ex_doc, "~> 0.20.2", only: :dev, runtime: false},
      {:excoveralls, "~> 0.11.1", only: :test},
      {:x509, "~> 0.8.0", only: [:dev, :test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

end
