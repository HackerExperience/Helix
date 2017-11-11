defmodule Helix.Server.Websocket.Requests.Config.SetTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Server.Websocket.Requests.Config.Set, as: ConfigSetRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  @mock_socket ChannelSetup.mock_server_socket()

  describe "ConfigSetRequest.check_params" do
    test "sets all the defined backends" do
      p1 =
        %{
          "hostname" => %{"hostname" => "phoebe-asdfasdf"},
          "location" => %{"lat" => "23.3", "lon" => "24.4"}
        }

      # P2 only received `hostname`
      p2 = Map.delete(p1, "location")

      req1 = ConfigSetRequest.new(p1)
      req2 = ConfigSetRequest.new(p2)

      assert {:ok, req1} = Requestable.check_params(req1, @mock_socket)
      assert {:ok, req2} = Requestable.check_params(req2, @mock_socket)

      # Req1 detected two changes (`hostname` and `location`)
      assert 2 == req1.meta.sub_requests |> Map.to_list() |> length()

      # While req2 only found one (`hostname`)
      assert 1 == req2.meta.sub_requests |> Map.to_list() |> length()
    end

    test "returns errors when any of the underlying configs are invalid" do
      params =
        %{
          "hostname" => %{"this_is_not_the_correct_key" => "transltr"},
          "location" => %{"lat" => "23.3", "lon" => "24.4"},
          "request_id" => "I'm something else"
        }

      request = ConfigSetRequest.new(params)

      # There was an error on one of the keys
      assert {:error, reason} = Requestable.check_params(request, @mock_socket)

      # And it returns both the key and the corresponding error
      assert reason.__ready__ == %{hostname: "bad_request"}
    end
  end

  describe "ConfigSetRequest.check_permissions" do
    test "returns errors when any of the underlying configs are invalid" do
      # Will fail on permission because the `@mock_socket` entity does not exist
      params =
        %{
          "hostname" => %{"hostname" => "transltr"},
          "location" => %{"lat" => "23.3", "lon" => "123.3"},
          "request_id" => "I'm something else"
        }

      assert {:error, reason} =
        ConfigSetRequest.new(params)
        |> Requestable.check_params(@mock_socket)
        |> elem(1)
        |> Requestable.check_permissions(@mock_socket)

      assert reason.__ready__.hostname == "entity_not_found"

      # `location` was correct so it's not included in the response payload
      refute Map.has_key?(reason.__ready__, :location)
    end
  end
end
