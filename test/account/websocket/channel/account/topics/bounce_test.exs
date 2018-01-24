defmodule Helix.Account.Websocket.Channel.Account.Topics.BounceTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros

  alias Helix.Entity.Query.Entity, as: EntityQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_id_str to_string(NetworkHelper.internet_id())

  describe "bounce.create" do
    test "creates the bounce when expected data is given" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()

      {server1, _} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      ip1 = ServerHelper.get_ip(server1)
      ip2 = ServerHelper.get_ip(server2)

      params = %{
        "name" => "lula_preso_amanha",
        "links" => [
          %{
            "network_id" => @internet_id_str,
            "ip" => ip1,
            "password" => server1.password
          },
          %{
            "network_id" => @internet_id_str,
            "ip" => ip2,
            "password" => server2.password
          }
        ]
      }

      ref = push socket, "bounce.create", params
      assert_reply ref, :ok, %{}, timeout(:fast)

      [bounce_created_event] = wait_events [:bounce_created]

      assert bounce_created_event.data.bounce_id
      assert bounce_created_event.data.name == params["name"]
      assert [
        %{network_id: @internet_id_str, ip: ip1},
        %{network_id: @internet_id_str, ip: ip2},
      ] == bounce_created_event.data.links

      assert [bounce] = EntityQuery.get_bounces(entity_id)
      assert to_string(bounce.bounce_id) == bounce_created_event.data.bounce_id
    end

    test "fails when player does not have access to bounce servers" do
      {socket, _} = ChannelSetup.join_account()

      {server1, _} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      ip1 = ServerHelper.get_ip(server1)
      ip2 = ServerHelper.get_ip(server2)

      params = %{
        "name" => "lula_preso_amanha",
        "links" => [
          %{
            "network_id" => @internet_id_str,
            "ip" => ip1,
            "password" => Random.password()
          },
          %{
            "network_id" => @internet_id_str,
            "ip" => ip2,
            "password" => server2.password
          }
        ]
      }

      ref = push socket, "bounce.create", params
      assert_reply ref, :error, response, timeout(:fast)

      assert response.data.message == "bounce_no_access"

      did_not_emit [:bounce_created]
    end
  end
end
