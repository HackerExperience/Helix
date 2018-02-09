defmodule Helix.Story.Websocket.Requests.Email.ReplyTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Story.Websocket.Requests.Email.Reply, as: EmailReplyRequest

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Story.Helper, as: StoryHelper

  @socket ChannelSetup.mock_account_socket()

  describe "check_params/2" do
    test "rejects invalid contact" do
      base_params = %{"reply_id" => StoryHelper.reply_id()}

      # Contact below does not exist
      p1 =
        %{
          "contact_id" => "ThisContactDoesNotExist"
        }
        |> Map.merge(base_params)

      # Invalid contact
      p2 =
        %{
          "contact_id" => 42
        }
        |> Map.merge(base_params)

      # No contact defined
      p3 = base_params

      req1 = EmailReplyRequest.new(p1)
      req2 = EmailReplyRequest.new(p2)
      req3 = EmailReplyRequest.new(p3)

      assert {:error, reason1, _} = Requestable.check_params(req1, @socket)
      assert {:error, reason2, _} = Requestable.check_params(req2, @socket)
      assert {:error, reason3, _} = Requestable.check_params(req3, @socket)

      assert reason1 == %{message: "bad_contact"}
      assert reason2 == reason1
      assert reason3 == reason2
    end
  end
end
