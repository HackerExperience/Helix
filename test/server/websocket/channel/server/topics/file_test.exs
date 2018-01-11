defmodule Helix.Server.Websocket.Channel.Server.Topics.FileTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "file.install (virus)" do
    test "installs virus" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      file = SoftwareSetup.virus!(server_id: destination.server_id)

      params =
        %{
          "file_id" => file.file_id |> to_string()
        }

      ref = push socket, "file.install", params
      assert_reply ref, :ok, response, timeout(:slow)

      [process_created_event] = wait_events [:process_created]

      # "install_virus" process was created!
      assert process_created_event.data.type == "install_virus"
      assert process_created_event.meta.request_id == response.meta.request_id

      TOPHelper.top_stop(gateway)
    end

    test "performs noop when installing same virus twice" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      file = SoftwareSetup.virus!(server_id: destination.server_id)

      params =
        %{
          "file_id" => file.file_id |> to_string()
        }

      # Requested to install the virus (first time)
      ref = push socket, "file.install", params
      assert_reply ref, :ok, _response, timeout(:slow)

      # It worked; process was created
      wait_events [:process_created]

      # Requested to install the virus (second time)
      ref = push socket, "file.install", params
      assert_reply ref, :ok, response, timeout(:slow)

      # User received nothing; basically performed a noop
      assert Enum.empty?(response.data)
      did_not_emit [:process_created]

      TOPHelper.top_stop(gateway)
    end
  end
end
