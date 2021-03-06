defmodule TetraCore.Mixfile do
  use Mix.Project

  def project do
    [app: :tetra_core,
     version: "0.0.1",
     elixir: "~> 1.2",
     escript: [main_module: CLI],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :exirc], mod: {TetraCore, []}]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:exirc, git: "git://github.com/dylan-cooper/exirc.git"},
      {:bunt, "~> 0.1.0"}
    ]
  end
end
