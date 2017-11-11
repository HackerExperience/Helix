defmodule Helix.Server.Websocket.Channel.Server.Requests.ConfigTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros

  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "config.set" do
    test "returns empty successful message when all params are valid" do
      {socket, %{gateway: server}} = ChannelSetup.join_server()

      hostname = "transltr"

      params =
        %{
          "hostname" => %{"hostname" => hostname},
          "location" => %{"lat" => "23.3", "lon" => "24.4"},
          "ignores_me" => %{"wa" => "t"},
          "request_id" => "I'm something else"
        }

      # Perform the request
      ref = push socket, "config.set", params

      # Received an empty but valid (:ok) response
      assert_reply ref, :ok, response, timeout()

      # The response is empty; it also keeps the `request_id` as expected
      assert response.data == %{}
      assert response.meta.request_id == params["request_id"]

      # Actually modified the server hostname
      new_server = ServerQuery.fetch(server.server_id)
      assert new_server.hostname == hostname
    end

    test "returns errors when something is wrong (during check_params)" do
      {socket, _} = ChannelSetup.join_server()

      params =
        %{
          "hostname" => %{"this_is_not_the_correct_key" => "transltr"},
          "location" => %{"lat" => "23.3", "lon" => "24.4"},
          "request_id" => "I'm something else"
        }

      # Perform the request
      ref = push socket, "config.set", params

      # Error!
      assert_reply ref, :error, response, timeout()

      # Detected and returned the error at `hostname`
      assert response.data.hostname == "bad_request"

      # `location` was correct so it's not included in the response payload
      refute Map.has_key?(response.data, "location")
    end

    test "returns errors when something is wrong (during handle_request)" do
      {socket, _} = ChannelSetup.join_server()

      # HACK: 66.7 longitude returns an error during the `handle_request` step
      params =
        %{
          "hostname" => %{"hostname" => "transltr"},
          "location" => %{"lat" => "23.3", "lon" => "66.7"},
          "request_id" => "I'm something else"
        }

      # Perform the request
      ref = push socket, "config.set", params

      # Error!
      assert_reply ref, :error, response, timeout()

      # Detected and returned the error at `location`
      assert response.data.location == "some_uncommon_error"

      # `hostname` was correct so it's not included in the response payload
      refute Map.has_key?(response.data, "hostname")
    end
  end
end
