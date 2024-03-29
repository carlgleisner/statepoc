defmodule Statepoc.MixProject do
  use Mix.Project

  def project do
    [
      app: :statepoc,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Statepoc.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ash, "~> 2.18"},
      {:ash_state_machine, "~> 0.2.2"}
    ]
  end
end
