defmodule Helix.Story.Action.Flow.Manager do

  import HELF.Flow

  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo, as: NetworkRepo
  alias Helix.Server.Model.Server
  alias Helix.Story.Action.Manager, as: ManagerAction
  alias Helix.Story.Model.Story

  @network_name "Campaign"

  @spec setup_story_network(Entity.t) ::
    {:ok, Network.t, Network.Connection.t}
    | {:error, :internal}
  @doc """
  Creates a Network and a Network.Connection for the Entity storyline.
  """
  def setup_story_network(entity) do
    flowing do
      with \
        {:ok, network, nc} <- setup_network_transaction(entity),
        on_fail(fn -> NetworkAction.delete(network) end)
      do
        {:ok, network, nc}
      end
    end
  end

  @spec setup_manager(Entity.t, Server.t, Network.t) ::
    {:ok, Story.Manager.t}
  @doc """
  Persists the storyline information for that entity (Server, Network)
  """
  def setup_manager(entity, server, network) do
    flowing do
      with \
        {:ok, manager} <- ManagerAction.setup(entity, server, network),
        on_fail(fn -> ManagerAction.remove(manager) end)
      do
        {:ok, manager}
      end
    end
  end

  @spec setup_network_transaction(Entity.t) ::
    {:ok, Network.t, Network.Connection.t}
    | {:error, :internal}
  defp setup_network_transaction(entity) do
    ip = IPv4.autogenerate()
    trans =
      NetworkRepo.transaction fn ->
        with \
          {:ok, network} <- NetworkAction.create(@network_name, :story),
          {:ok, nc} <- NetworkAction.Connection.create(network, ip, entity)
        do
          {network, nc}
        else
          _ ->
            NetworkRepo.rollback(:internal)
        end
      end

    with {:ok, {network, nc}} <- trans do
      {:ok, network, nc}
    end
  end
end
