defmodule Helix.Network.Websocket.Requests.Bounce.UpdateTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Network.Query.Bounce, as: BounceQuery
  alias Helix.Network.Websocket.Requests.Bounce.Update, as: BounceUpdateRequest

  alias HELL.TestHelper.Random
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup

  @socket ChannelSetup.mock_account_socket()

  @internet_id NetworkHelper.internet_id()
  @internet_id_str to_string(@internet_id)

  describe "check_params/2" do
    test "casts params" do
      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: @socket.assigns.entity_id)

      # `p1` has both `name` and `links` set
      p1 =
        %{
          "bounce_id" => to_string(bounce.bounce_id),
          "name" => NetworkHelper.Bounce.name(),
          "links" => [
            %{"network_id" => "::", "ip" => "1.2.3.4", "password" => "abc"},
            %{"network_id" => "::", "ip" => "4.3.2.1", "password" => "cba"}
          ]
        }

      # `p2` only has `name` set
      p2 =
        %{
          "bounce_id" => to_string(bounce.bounce_id),
          "name" => NetworkHelper.Bounce.name()
        }

      # `p3` only has `links` set
      p3 =
        %{
          "bounce_id" => to_string(bounce.bounce_id),
          "links" => [
            %{"network_id" => "::", "ip" => "1.2.3.4", "password" => "abc"},
            %{"network_id" => "::", "ip" => "4.3.2.1", "password" => "cba"}
          ]
        }

      req1 = BounceUpdateRequest.new(p1)
      req2 = BounceUpdateRequest.new(p2)
      req3 = BounceUpdateRequest.new(p3)

      assert {:ok, req1} = Requestable.check_params(req1, @socket)
      assert {:ok, req2} = Requestable.check_params(req2, @socket)
      assert {:ok, req3} = Requestable.check_params(req3, @socket)

      # req1 must update both `name` and `links`
      assert req1.params.bounce_id == bounce.bounce_id
      assert req1.params.new_name == p1["name"]
      Enum.each(req1.params.new_links, fn link ->
        assert link.network_id == @internet_id
        assert is_binary(link.ip)
        assert is_binary(link.password)
      end)

      # req2 only updates the name
      assert req1.params.bounce_id == bounce.bounce_id
      assert req2.params.new_name == p2["name"]
      refute req2.params.new_links

      # req3 only updates the links
      assert req1.params.bounce_id == bounce.bounce_id
      refute req3.params.new_name
      Enum.each(req3.params.new_links, fn link ->
        assert link.network_id == @internet_id
        assert is_binary(link.ip)
        assert is_binary(link.password)
      end)
    end

    test "requires bounce ID" do
      p1 =
        %{
          "bounce_id" => "not_an_id",
          "name" => "blar"
        }

      p2 =
        %{
          "name" => "wut"
        }

      req1 = BounceUpdateRequest.new(p1)
      req2 = BounceUpdateRequest.new(p2)

      assert {:error, reason1, _} = Requestable.check_params(req1, @socket)
      assert {:error, reason2, _} = Requestable.check_params(req2, @socket)

      assert reason1 == %{message: "bad_request"}
      assert reason2 == reason1
    end

    test "requires at least one change (`name` or `links`)" do
      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: @socket.assigns.entity_id)

      params =
        %{
          "bounce_id" => to_string(bounce.bounce_id)
        }

      request = BounceUpdateRequest.new(params)

      assert {:error, reason, _} = Requestable.check_params(request, @socket)
      assert reason == %{message: "no_changes"}
    end

    test "validates bounce name" do
      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: @socket.assigns.entity_id)

      params =
        %{
          "bounce_id" => to_string(bounce.bounce_id),
          "name" => "($*%(@$*&%(@$%*&#@)))"
        }

      request = BounceUpdateRequest.new(params)

      assert {:error, reason, _} = Requestable.check_params(request, @socket)
      assert reason == %{message: "bad_request"}
    end

    test "validates links" do
      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: @socket.assigns.entity_id)

      base_params = %{"bounce_id" => to_string(bounce.bounce_id)}

      p1 = %{
        "name" => NetworkHelper.Bounce.name(),
        "links" => [
          %{"network_id" => "invalid", "ip" => "1.2.3.4", "password" => "abc"},
          %{"network_id" => "::", "ip" => "4.3.2.1", "password" => "cba"}
        ]
      } |> Map.merge(base_params)

      p2 = %{
        "links" => [
          %{"network_id" => "::", "ip" => "invalid", "password" => "abc"},
          %{"network_id" => "::", "ip" => "4.3.2.1", "password" => "cba"}
        ]
      } |> Map.merge(base_params)

      p3 = %{
        "links" => [
          %{"network_id" => "::", "ip" => "1.2.3.4", "password" => nil},
          %{"network_id" => "::", "ip" => "4.3.2.1", "password" => "cba"}
        ]
      } |> Map.merge(base_params)

      p4 = %{
        "links" => [%{"network_id" => "::"}, %{"foo" => true}]
      } |> Map.merge(base_params)

      req1 = BounceUpdateRequest.new(p1)
      req2 = BounceUpdateRequest.new(p2)
      req3 = BounceUpdateRequest.new(p3)
      req4 = BounceUpdateRequest.new(p4)

      assert {:error, r1, _} = Requestable.check_params(req1, @socket)
      assert {:error, r2, _} = Requestable.check_params(req2, @socket)
      assert {:error, r3, _} = Requestable.check_params(req3, @socket)
      assert {:error, r4, _} = Requestable.check_params(req4, @socket)

      assert r1 == %{message: "bad_link"}
      assert r2 == r1
      assert r3 == r2
      assert r4 == r3
    end
  end

  describe "check_permissions/2" do
    test "accepts when everything is OK" do
      {entity, _} = EntitySetup.entity()
      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      {server, _} = ServerSetup.server()
      ip = ServerHelper.get_ip(server)

      params = %{
        "bounce_id" => to_string(bounce.bounce_id),
        "name" => "lula_preso_amanha",
        "links" => [
          %{
            "network_id" => @internet_id_str,
            "ip" => ip,
            "password" => server.password,
          }
        ]
      }

      request = BounceUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.entity == entity
      assert request.meta.bounce == bounce
      assert request.meta.servers == [server]
    end

    test "rejects when entity is not the owner of the bounce" do
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
            "password" => server.password,
          }
        ]
      }

      request = BounceUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, @socket)
      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, @socket)

      assert reason == "entity_not_found"
    end

    test "rejects when bounce is being used" do
      {entity, _} = EntitySetup.entity()
      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      # Start using the bounce
      NetworkSetup.tunnel(bounce_id: bounce.bounce_id)

      {server, _} = ServerSetup.server()
      ip = ServerHelper.get_ip(server)

      params = %{
        "bounce_id" => to_string(bounce.bounce_id),
        "name" => "lula_preso_amanha",
        "links" => [
          %{
            "network_id" => @internet_id_str,
            "ip" => ip,
            "password" => server.password,
          }
        ]
      }

      request = BounceUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, socket)

     assert reason == "bounce_in_use"
    end

    test "rejects when password is wrong" do
      {entity, _} = EntitySetup.entity()
      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

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
            "password" => Random.password(),
          },
          %{
            "network_id" => @internet_id_str,
            "ip" => ip2,
            "password" => server2.password
          }
        ]
      }

      request = BounceUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, socket)

      assert reason == "bounce_no_access"
    end

    test "rejects when NIP is wrong" do
      {entity, _} = EntitySetup.entity()
      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      {server, _} = ServerSetup.server()

      params = %{
        "bounce_id" => to_string(bounce.bounce_id),
        "name" => "lula_preso_amanha",
        "links" => [
          %{
            "network_id" => @internet_id_str,
            "ip" => NetworkHelper.ip(),
            "password" => server.password,
          }
        ]
      }

      request = BounceUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, %{message: reason}, _} =
        Requestable.check_permissions(request, socket)

      assert reason == "nip_not_found"
    end
  end

  describe "handle_request/2" do
    test "updates the bounce when everything is ok" do
      {entity, _} = EntitySetup.entity()
      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      {server, _} = ServerSetup.server()
      ip = ServerHelper.get_ip(server)

      params = %{
        "bounce_id" => to_string(bounce.bounce_id),
        "name" => "lula_preso_amanha",
        "links" => [
          %{
            "network_id" => @internet_id_str,
            "ip" => ip,
            "password" => server.password,
          }
        ]
      }

      request = BounceUpdateRequest.new(params)
      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert {:ok, _request} = Requestable.handle_request(request, socket)

      new_bounce = BounceQuery.fetch(bounce.bounce_id)

      assert new_bounce.name == params["name"]
      assert new_bounce.links == [{server.server_id, @internet_id, ip}]
      assert new_bounce.entity_id == entity.entity_id
    end
  end
end
