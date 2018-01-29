defmodule Helix.Network.Websocket.Requests.Bounce.RemoveTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Network.Query.Bounce, as: BounceQuery
  alias Helix.Network.Websocket.Requests.Bounce.Remove, as: BounceRemoveRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Network.Setup, as: NetworkSetup

  @socket ChannelSetup.mock_account_socket()

  describe "check_params/2" do
    test "casts params" do
      {bounce, _} =
        NetworkSetup.Bounce.bounce(entity_id: @socket.assigns.entity_id)

      params = %{
        "bounce_id" => to_string(bounce.bounce_id)
      }

      request = BounceRemoveRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @socket)
      assert request.params.bounce_id == bounce.bounce_id
    end

    test "rejects invalid bounce id" do
      p1 = %{"bounce_id" => "not_an_id"}
      p2 = %{}

      req1 = BounceRemoveRequest.new(p1)
      req2 = BounceRemoveRequest.new(p2)

      assert {:error, reason1, _} = Requestable.check_params(req1, @socket)
      assert {:error, reason2, _} = Requestable.check_params(req2, @socket)

      assert reason1 == %{message: "bad_request"}
      assert reason2 == reason1
    end
  end

  describe "check_perm/2" do
    test "accepts when everything is ok" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      params = %{
        "bounce_id" => to_string(bounce.bounce_id)
      }

      request = BounceRemoveRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert request.meta.bounce == bounce
    end

    test "rejects when player is not the owner of the bounce" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce()

      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      params = %{
        "bounce_id" => to_string(bounce.bounce_id)
      }

      request = BounceRemoveRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, reason, _} =
        Requestable.check_permissions(request, socket)

      assert reason == %{message: "bounce_not_belongs"}
    end

    test "rejects when bounce is being used by a tunnel/connection" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      NetworkSetup.tunnel(bounce_id: bounce.bounce_id)

      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      params = %{
        "bounce_id" => to_string(bounce.bounce_id)
      }

      request = BounceRemoveRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, reason, _} =
        Requestable.check_permissions(request, socket)

      assert reason == %{message: "bounce_in_use"}
    end
  end

  describe "handle_request/2" do
    test "removes the bounce" do
      {entity, _} = EntitySetup.entity()
      {bounce, _} = NetworkSetup.Bounce.bounce(entity_id: entity.entity_id)

      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      params = %{
        "bounce_id" => to_string(bounce.bounce_id)
      }

      request = BounceRemoveRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)
      assert {:ok, _request} = Requestable.handle_request(request, socket)

      refute BounceQuery.fetch(bounce.bounce_id)
    end
  end
end
