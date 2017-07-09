defmodule Helix.Server.Action.Flow.Server do

  alias Helix.Hardware.Action.Flow.Hardware, as: HardwareFlow
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Server.Action.Server, as: ServerAction

  import HELF.Flow

  def setup_server(entity) do
    flowing do
      with \
        {:ok, server} <- ServerAction.create(:desktop),
        on_fail(fn -> ServerAction.delete(server) end),

        {:ok, motherboard_id} <- HardwareFlow.setup_bundle(entity),

        {:ok, server} <- ServerAction.attach(server, motherboard_id),
        on_fail(fn -> ServerAction.detach(server) end),

        server_id = server.server_id,
        {:ok, _} <- EntityAction.link_server(entity, server_id),
        on_fail(fn -> EntityAction.unlink_server(server_id) end)
      do
        {:ok, server}
      end
    end
  end

end
