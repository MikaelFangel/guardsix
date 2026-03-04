defmodule LogpointApi.MixProject do
  use Mix.Project

  @version "2.0.0"
  @source_url "https://github.com/MikaelFangel/logpoint_api"

  def project do
    [
      app: :logpoint_api,
      version: @version,
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      source_url: @source_url,
      homepage_url: @source_url
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:req, "~> 0.5.15"},
      {:jason, "~> 1.4"},
      {:joken, "~> 2.6"},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.2", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    """
    A stateless Elixir wrapper for the Logpoint SIEM API.
    Covers searching, incidents, alert rules, user-defined lists, and repos
    with builder patterns for rules and notifications.
    """
  end

  defp package do
    [
      name: "logpoint_api",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Documentation" => "https://hexdocs.pm/logpoint_api"
      },
      maintainers: ["Mikael Fangel"]
    ]
  end

  defp docs do
    [
      main: "LogpointApi",
      source_url: @source_url,
      source_ref: "v#{@version}",
      extras: ["README.md", "CONTRIBUTING.md", "guides/howtos/polling-search-results.md", "guides/upgrading/v2.md"],
      groups_for_extras: [
        "How-To": ~r/guides\/howtos\/.*/,
        Upgrading: ~r/guides\/upgrading\/.*/
      ]
    ]
  end
end
