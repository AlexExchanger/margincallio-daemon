defmodule Daemon.Mixfile do
  use Mix.Project

  def project do
    [app: :daemon,
     version: "0.0.1",
     elixir: "~> 1.0",
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [
      mod: { Daemon, [] }, 
      applications: [:exlager, :jazz,:postgrex, :ecto,:cowboy, :gproc]
    ]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type `mix help deps` for more examples and options
  defp deps do
    [
      {:jazz, github: "meh/jazz"},
      {:postgrex, ">= 0.0.0"},
      {:ecto, "~> 0.10.1"},
      {:bullet, github: "extend/bullet"},
      {:gproc, github: "uwiger/gproc"},
      {:exprintf, github: "parroty/exprintf"},
      {:exlager, github: "khia/exlager"},
    ]
  end
end
