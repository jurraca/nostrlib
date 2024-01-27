defmodule NostrBasics.MixProject do
  use Mix.Project

  @version "0.1.0"
  @repo_url "https://git.sr.ht/~jurraca/nostrlib"

  def project do
    [
      app: :nostrlib,
      name: "Nostrlib",
      version: @version,
      description: "Nostr library for Elixir.",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),

      # Docs
      name: "Nostrlib",
      source_url: @repo_url,
      homepage_url: @repo_url,
      package: package(),
      docs: docs()
    ]
  end

  def package do
    [
      licenses: ["MIT"],
      links: %{
        "Sourcehut" => "https://git.sr.ht/~jurraca/nostrlib",
        "GitHub" => "https://github.com/jurraca/nostrlib"
      }
    ]
  end

  defp docs do
    [
      main: "Nostrlib",
      extras: [ "README.md" ],
      assets: "/guides/assets",
      source_ref: @version,
      source_url: @repo_url
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.29.1", only: [:docs], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:jason, "~> 1.4"},
      {:bitcoinex, "~> 0.1.7"},
      {:bech32, "~> 1.0"}
    ]
  end
end
