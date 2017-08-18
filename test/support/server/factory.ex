defmodule Helix.Test.Server.Factory do

  use ExMachina.Ecto, repo: Helix.Server.Repo

  alias Helix.Server.Model.Server
  alias Helix.Server.Model.ServerType

  def random_server_type,
    do: Enum.random(ServerType.possible_types())

  def server_factory do
    %Server{
      password: "letmein",
      server_type: random_server_type()
    }
  end
end
