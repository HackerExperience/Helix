defmodule Helix.Account.Websocket.Channel.Account.Topics.BounceTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros

  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Query.Bounce, as: BounceQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_id NetworkHelper.internet_id()
  @internet_id_str to_string(@internet_id)

  describe "bounce.create" do
    test "creates the bounce when expected data is given" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()

      {server1, _} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      ip1 = ServerHelper.get_ip(server1)
      ip2 = ServerHelper.get_ip(server2)

      params = %{
        "name" => "lula_preso_Amanda",
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
    end
  end

  describe "bounce.update" do
    test "updates the bounce when expected data is given" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()

      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity_id)

      {server1, _} = ServerSetup.server()
      {server2, _} = ServerSetup.server()

      ip1 = ServerHelper.get_ip(server1)
      ip2 = ServerHelper.get_ip(server2)

      params = %{
        "bounce_id" => to_string(bounce.bounce_id),
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
        ],
        "request_id" => "fingerprint"
      }

      ref = push socket, "bounce.update", params
      assert_reply ref, :ok, %{}, timeout(:fast)

      [bounce_updated_event] = wait_events [:bounce_updated]

      assert bounce_updated_event.data.bounce_id == to_string(bounce.bounce_id)
      assert bounce_updated_event.data.name == params["name"]
      assert [nip1, nip2] = bounce_updated_event.data.links

      assert nip1.network_id == @internet_id_str
      assert nip1.ip == ip1
      assert nip2.network_id == @internet_id_str
      assert nip2.ip == ip2

      assert bounce_updated_event.meta.request_id == params["request_id"]

      # Updated the bounce
      new_bounce = BounceQuery.fetch(bounce.bounce_id)
      assert new_bounce.name == params["name"]
      assert [
        {server1.server_id, @internet_id, ip1},
        {server2.server_id, @internet_id, ip2}
      ] == new_bounce.links
    end

    test "fails when player is not the owner of the bounce" do
      {socket, _} = ChannelSetup.join_account()

      {bounce, _} = NetworkSetup.Bounce.bounce()

      {server, _} = ServerSetup.server()
      ip = ServerHelper.get_ip(server)

      params = %{
        "bounce_id" => to_string(bounce.bounce_id),
        "name" => "lula_preso_amanha",
        "links" => [
          %{
            "network_id" => @internet_id_str,
            "ip" => ip,
            "password" => server.password
          }
        ],
        "request_id" => "f1ngerpr1nt"
      }

      ref = push socket, "bounce.update", params
      assert_reply ref, :error, response, timeout(:fast)

      assert response.data.message == "bounce_not_belongs"
      assert response.meta.request_id == params["request_id"]
    end
  end

  describe "bounce.remove" do
    test "removes the bounce when everything is OK" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()

      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity_id)

      params = %{
        "bounce_id" => to_string(bounce.bounce_id),
        "request_id" => "fingerprint"
      }

      ref = push socket, "bounce.remove", params
      assert_reply ref, :ok, %{}, timeout(:fast)

      [bounce_removed_event] = wait_events [:bounce_removed]

      assert bounce_removed_event.data.bounce_id == to_string(bounce.bounce_id)
      assert bounce_removed_event.meta.request_id == params["request_id"]

      # Removed the bounce
      refute BounceQuery.fetch(bounce.bounce_id)
    end

    test "rejects when player is not the owner of the bounce" do
      {socket, _} = ChannelSetup.join_account()
      {bounce, _} = NetworkSetup.Bounce.bounce()

      params = %{"bounce_id" => to_string(bounce.bounce_id)}

      ref = push socket, "bounce.remove", params
      assert_reply ref, :error, response, timeout(:fast)

      assert response.data.message == "bounce_not_belongs"
    end
  end
end
