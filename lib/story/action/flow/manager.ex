defmodule Helix.Story.Action.Flow.Manager do

  import HELF.Flow

  alias HELL.IPv4
  alias Helix.Network.Action.Network, as: NetworkAction
  alias Helix.Network.Repo, as: NetworkRepo

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

  defp setup_network_transaction(entity) do
    ip = IPv4.autogenerate()
    trans =
      NetworkRepo.transaction fn ->
        with \
          {:ok, network} <- NetworkAction.create("Campaign", :story),
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
