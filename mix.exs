defmodule Firebrick.Mixfile do
  use Mix.Project

  def project do
    [ app: :firebrick,
      version: "0.0.1",
      dynamos: [Firebrick.Dynamo],
      compilers: [:elixir, :dynamo, :app, :erlang],
      env: [ prod: [compile_path: "ebin"]],
      compile_path: "tmp/#{Mix.env}/firebrick/ebin",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [ applications: [:cowboy, :dynamo, :bcrypt, :qdate, :ibrowse],
      mod: { Firebrick, [] } ]
  end

  defp deps do
    [
     { :cowboy, github: "extend/cowboy" },
     { :dynamo, "0.1.0-dev", github: "elixir-lang/dynamo" },
     { :jsex,    github: "talentdeficit/jsex" },
     { :bcrypt, github: "irccloud/erlang-bcrypt" },
     { :gen_smtp, github: "Vagabond/gen_smtp" },
     { :realm, github: "HashNuke/realm" },
     { :riak_pool,  github: "HashNuke/riak_pool" },
     { :qdate, github: "choptastic/qdate" },
     { :ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.0.2" },
     { :eiconv, github: "zotonic/eiconv" }
    ]
  end
end
