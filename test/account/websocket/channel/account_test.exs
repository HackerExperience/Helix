defmodule Helix.Account.Websocket.Channel.AccountTest do

  use Helix.Test.IntegrationCase

  alias Helix.Websocket.Socket
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Hardware.Action.Motherboard, as: MotherboardAction
  alias Helix.Server.Model.ServerType
  alias Helix.Server.Action.Server, as: ServerAction
  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Account.Websocket.Channel.Account, as: Channel

  alias Helix.Cache.Helper, as: CacheHelper
  alias Helix.Entity.Factory, as: EntityFactory
  alias Helix.Hardware.Factory, as: HardwareFactory
  alias Helix.Server.Factory, as: ServerFactory
  alias Helix.Account.Factory

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  setup do
    account = Factory.insert(:account)
    {:ok, token} = SessionAction.generate_token(account)
    {:ok, socket} = connect(Socket, %{token: token})
    {:ok, _, socket} = join(socket, "account:" <> account.account_id)

    {:ok, account: account, socket: socket}
  end

  defp create_server_for_entity(entity) do

    # FIXME PLEASE
    server = ServerFactory.insert(:server)
    EntityAction.link_server(entity, server.server_id)

    # I BEG YOU, SAVE ME FROM THIS EXCRUCIATING PAIN
    motherboard = HardwareFactory.insert(:motherboard)
    Enum.each(motherboard.slots, fn slot ->
      component = HardwareFactory.insert(slot.link_component_type)
      component = component.component

      MotherboardAction.link(slot, component)
    end)
    {:ok, server} = ServerAction.attach(server, motherboard.motherboard_id)

    CacheHelper.sync_test()

    server
  end

  test "an user can't join another user's notification channel", context do
    another_account = Factory.insert(:account)
    id = another_account.account_id
    assert {:error, _} = join(context.socket, "account:" <> id)
  end

  describe "server.index" do
    test "returns all servers owned by the account", context do
      entity = EntityFactory.insert(
        :entity,
        entity_id: context.account.account_id)

      server_ids = Enum.map(1..5, fn _ ->
        server = create_server_for_entity(entity)

        server.server_id
      end)

      ref = push context.socket, "server.index", %{}

      assert_reply ref, :ok, response

      received_server_ids =
        response.data.servers
        |> Enum.map(&(&1.server_id))
        |> MapSet.new()

      # TODO: improve those format checks
      assert MapSet.equal?(MapSet.new(server_ids), received_server_ids)
      assert Enum.all?(response.data.servers, fn server ->
        match?(
          %{
            server_id: _,
            server_type: _,
            password: _,
            hardware: _,
            ips: _
          },
          server)
      end)
      assert Enum.all?(response.data.servers, &(is_binary(&1.server_id)))
      assert Enum.all?(response.data.servers, fn server ->
        server.server_type in ServerType.possible_types()
      end)
      assert Enum.all?(response.data.servers, &(is_binary(&1.password)))
      assert Enum.all?(response.data.servers, fn
        %{hardware: nil} ->
          true
        %{hardware: hardware = %{}} ->
          match?(
            %{
              resources: %{
                cpu: _,
                ram: _,
                net: %{}
              },
              components: %{}
            },
            hardware)
      end)
    end
  end

  describe "notification/2" do
    test "pushes message to all clients", context do
      notification = %{warning: "all your base are belong to us!"}
      Channel.notify(context.account.account_id, notification)

      assert_push "notification", %{warning: "all your base are belong to us!"}
    end
  end
end
