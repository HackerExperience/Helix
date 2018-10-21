defmodule Helix.Log.Websocket.Requests.PaginateTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Log.Websocket.Requests.Paginate, as: LogPaginateRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Log.Helper, as: LogHelper

  @mock_socket ChannelSetup.mock_server_socket()

  describe "LogPaginateRequest.check_params/2" do
    test "accepts when everything is OK" do
      log_id = LogHelper.id()

      p0 = %{
        "log_id" => to_string(log_id),
        "total" => 50
      }
      req0 = LogPaginateRequest.new(p0)

      assert {:ok, req0} = Requestable.check_params(req0, @mock_socket)

      assert req0.params.log_id == log_id
      assert req0.params.total == 50

      p1 = %{
        "log_id" => to_string(log_id),
        "total" => 500_000
      }
      req1 = LogPaginateRequest.new(p1)

      assert {:ok, req1} = Requestable.check_params(req1, @mock_socket)

      # If `total` is greater than `@max_total` allowed, `@max_total` is used.
      assert req1.params.total == 100
    end
  end
end
