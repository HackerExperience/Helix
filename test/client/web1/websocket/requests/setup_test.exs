defmodule Helix.Client.Web1.Websocket.Requests.SetupTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Client.Web1.Websocket.Requests.Setup, as: Web1SetupRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup

  @mock_socket ChannelSetup.mock_account_socket(connect_opts: [client: :web1])

  describe "Web1SetupRequest.check_params" do
    test "accepts when pages list is valid" do
      params = %{
        "pages" => ["welcome", "server"]
      }

      request = Web1SetupRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)
      assert request.params.pages == [:welcome, :server]
    end

    test "rejects when param is not passed" do
      request = Web1SetupRequest.new(%{})
      assert {:error, reason} = Requestable.check_params(request, @mock_socket)
      assert reason.message == "bad_request"
    end

    test "rejects when any of the pages are invalid" do
      params = %{
        "pages" => ["welcome", "iaminvalid", "server"]
      }

      request = Web1SetupRequest.new(params)

      assert {:error, reason} = Requestable.check_params(request, @mock_socket)
      assert reason.message == "invalid_page"
    end
  end
end
