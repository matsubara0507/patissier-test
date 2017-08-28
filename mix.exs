defmodule PastryChefTest.Mixfile do
  use Mix.Project

  def project do
    [
      app: :pastry_chef_test,
      version: "0.0.1",
      elixir: "~> 1.4",
      elixirc_paths: elixirc_paths(Mix.env),
      compilers: [:phoenix, :gettext] ++ Mix.compilers,
      start_permanent: Mix.env == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PastryChefTest, []},
      extra_applications: [:logger, :tentacat, :ex_aws, :hackney, :poison, :sftp_ex, :sshex, :ok, :sweet_xml]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.3.0-rc"},
      {:phoenix_pubsub, "~> 1.0"},
      {:phoenix_html, "~> 2.10"},
      {:phoenix_live_reload, "~> 1.0", only: :dev},
      {:gettext, "~> 0.11"},
      {:cowboy, "~> 1.0"},
      {:tentacat, "~> 0.5"},
      {:ex_aws, "~> 1.0"},
      {:poison, "~> 2.0"},
      {:hackney, "~> 1.6"},
      {:sftp_ex, "~> 0.2.1"},
      {:sshex, "~> 2.2.1"},
      {:ok, "~> 1.8"},
      {:sweet_xml, "~> 0.6.5"}
    ]
  end

  defp aliases do
    [
      "test": ["test"]
    ]
  end
end
