defmodule Helix.Server.Websocket.Routes do

  alias Helix.Websocket.Socket, warn: false
  alias Helix.Entity.Service.API.Entity
  alias Helix.Entity.Service.API.HackDatabase
  alias Helix.Hardware.Service.API.NetworkConnection
  alias Helix.Software.Service.Flow.Cracker

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
      HackDatabase.create(entity, network, target, server_id, "vpc")
    end

    start_cracker = fn entity, server_id ->
      Cracker.start_process(
        entity.entity_id,
        gateway,
        network,
        target,
        server_id,
        "vpc")
    end

    with \
      server = %{} <- NetworkConnection.get_server_by_ip(network, target),
      # FIXME
      entity = %{} <- account |> Entity.get_entity_id() |> Entity.fetch(),
      server_id = server.server_id,
      {:ok, _} <- create_hack_db_entry.(entity, server_id),
      {:ok, process} <- start_cracker.(entity, server_id)
    do
      {:ok, process}
    end
  end
end
