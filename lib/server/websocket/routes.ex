defmodule Helix.Server.Websocket.Routes do

  alias Helix.Websocket.Socket, warn: false
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Entity.Action.Database, as: DatabaseAction
  alias Helix.Software.Action.Flow.Cracker, as: CrackerFlow
  alias Helix.Cache.Query.Cache, as: CacheQuery

  # Note that this is somewhat a hack to allow us to break our request-response
  # channel into several parts (one on each domain). So this code will be
  # executed inside the "requests" channel and thus must follow Phoenix
  # Channel's callback interface:
  # https://hexdocs.pm/phoenix/Phoenix.Channel.html#c:handle_in/3

  def server_crack(
    socket,
    %{"gateway" => gateway, "network_id" => network, "target_ip" => target})
  do
    account = socket.assigns.account

    create_hack_db_entry = fn entity, server_id ->
      DatabaseAction.create(entity, network, target, server_id, "vpc")
    end

    start_cracker = fn entity, server_id ->
      CrackerFlow.start_process(
        entity.entity_id,
        gateway,
        network,
        target,
        server_id,
        "vpc")
    end

    with \
      {:ok, server_id} <- CacheQuery.from_nip_get_server(network, target),
      # FIXME
      entity_id = EntityQuery.get_entity_id(account),
      entity = %{} <- EntityQuery.fetch(entity_id),
      {:ok, _} <- create_hack_db_entry.(entity, server_id),
      {:ok, process} <- start_cracker.(entity, server_id)
    do
      {:ok, process}
    end
  end
end
