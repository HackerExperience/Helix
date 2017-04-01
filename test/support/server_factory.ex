defmodule Helix.Server.Factory do

  use ExMachina.Ecto, repo: Helix.Server.Repo

  alias HELL.TestHelper.Random
  alias Helix.Server.Model.Server
  alias Helix.Server.Model.ServerType

  def random_server_type,
    do: Enum.random(ServerType.possible_types())

  def server_factory do
    %Server{
      server_type: random_server_type(),
      poi_id: Random.pk()
    }
  end
end
