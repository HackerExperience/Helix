defmodule Helix.Server.Websocket.Channel.ServerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Websocket.Socket
  # alias Helix.Server.Websocket.Channel.Server, as: Channel

  alias Helix.Server.Factory, as: ServerFactory
  alias Helix.Network.Factory, as: NetworkFactory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  # TODO: Move this to a case
  setup do
    alias Helix.Account.Factory
    alias Helix.Account.Service.API.Session

    account = Factory.insert(:account)
    token = Session.generate_token(account)
    {:ok, socket} = connect(Socket, %{token: token})

    {:ok, account: account, socket: socket}
  end

  # TODO: Move this to a factory
  def create_server_for_account(account) do
    alias Helix.Entity.Factory, as: EntityFactory

    # FIXME PLEASE
    entity = EntityFactory.insert(:entity, entity_id: account.account_id)

    create_server_for_entity(entity)
  end

  def create_destination_server do
    alias Helix.Entity.Factory, as: EntityFactory

    entity = EntityFactory.insert(:entity)

    create_server_for_entity(entity)
  end

  defp create_server_for_entity(entity) do
    alias Helix.Server.Factory, as: ServerFactory
    alias Helix.Entity.Service.API.Entity, as: EntityAPI

    # FIXME PLEASE
    server = ServerFactory.insert(:server)
    EntityAPI.link_server(entity, server.server_id)

    server
  end

  test "can connect to owned server", context do
    server = create_server_for_account(context.account)
    assert {:ok, _, _} = join(context.socket, "server:" <> server.server_id)
  end

  test "can not connect to a non owned server without connection", context do
    server = create_destination_server()

    assert {:error, _} = join(context.socket, "server:" <> server.server_id)
  end

  test \
    "can connect to a destination if a suitable connection exists",
    context
  do
    gateway = create_server_for_account(context.account)
    gateway = gateway.server_id
    destination = create_destination_server()
    destination = destination.server_id

    topic = "server:" <> destination
    join_msg = %{"gateway_id" => gateway}

    # Fails because there is no connection between the two servers
    assert {:error, _} = join(context.socket, topic, join_msg)

    # TODO: Make this an integration factory function
    tunnel = NetworkFactory.insert(
      :tunnel,
      gateway_id: gateway,
      destination_id: destination)
    NetworkFactory.insert(:connection,
      tunnel: tunnel,
      connection_type: "ssh")

    # With a valid SSH connection, a join is possible
    assert {:ok, _, _} = join(context.socket, topic, join_msg)
  end
end
