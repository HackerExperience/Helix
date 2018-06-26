defmodule Helix.Test.Features.Process.Lifecycle do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros
  import Helix.Test.Process.Macros

  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :feature

  @internet_id NetworkHelper.internet_id()

  describe "process" do

    skip_on_travis_slowpoke()
    test "creation and allocation" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      ServerHelper.update_server_specs(gateway, dlk: 100, ulk: 10)
      ServerHelper.update_server_specs(destination, dlk: 100, ulk: 10)

      # Create the File that we'll downloaded
      {file, _} = SoftwareSetup.file(server_id: destination.server_id)

      params = %{
        "file_id" => file.file_id |> to_string(),
      }

      # Starts the file download
      ref = push socket, "file.download", params
      assert_reply ref, :ok, response, timeout(:slow)

      # The process was created
      assert response.data == %{}

      [top_recalcado_event, process_created_event] =
        wait_events [:top_recalcado, :process_created]

      process_id = Process.ID.cast!(process_created_event.data.process_id)

      assert top_recalcado_event.event == "top_recalcado"
      assert process_created_event.event == "process_created"

      # Let's fetch the process, just to make sure
      process = ProcessQuery.fetch(process_id)

      # The process received allocation
      refute Enum.empty?(process.l_reserved)
      refute Enum.empty?(process.r_reserved)

      # Process received no allocations of CPU/ULK (some RAM for static usage)
      assert process.l_allocated.cpu == 0.0
      assert process.l_allocated.ulk[@internet_id] == 0.0
      assert process.l_allocated.ram > 0

      # But received 100% of server DLK resources (made available by target ULK)
      # Notice that 100% of gateway DLK is 100, but destination ULK is 10, so
      # the download speed will be limited to 10.
      assert_resource process.l_allocated.dlk[@internet_id], 10
    end

    # This is pretty much the same test above, but now we'll focus on the other
    # half: completing the process. We want to avoid using `force_completion`
    # from TOPHelper, so the completion is actually spontaneous.
    # In order to do that we create a very small process which needs to transfer
    # a file of about ~1kb, which takes less than a second on a 100Mbit link.
    skip_on_travis_slowpoke()
    test "spontaneous completion" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      # Connect to gateway channel too, so we can receive gateway publications
      ChannelSetup.join_server(socket: socket, own_server: true)

      # Let's cheat and give ourselves (and destination) a decent link
      ServerHelper.update_server_specs(gateway, dlk: 100)
      ServerHelper.update_server_specs(destination, ulk: 100)

      # Create the File that we'll downloaded
      {file, _} = SoftwareSetup.file(server_id: destination.server_id, size: 10)

      params = %{
        "file_id" => file.file_id |> to_string(),
      }

      # Starts the file download
      ref = push socket, "file.download", params
      assert_reply ref, :ok, _, timeout(:slow)

      gateway_storage = SoftwareHelper.get_storage(gateway)

      # No files on gateway server. Download process started but not completed.
      assert [] == StorageQuery.files_on_storage(gateway_storage)

      # Wait for process completion (Process itself takes about 100ms)
      # Below timer is required because we want to let the process complete by
      # itself, without using `force_completion`
      :timer.sleep(100)

      wait_events [:top_recalcado, :top_recalcado, :file_downloaded]

      # I haz file!11
      assert [downloaded_file] = StorageQuery.files_on_storage(gateway_storage)

      # Same file...
      assert downloaded_file.name == file.name
      assert downloaded_file.modules == file.modules

      # Different ID
      refute downloaded_file.file_id == file.file_id

      # Sleep for some extra time so all "spawned" connections can be closed
      sleep(50)
    end
  end
end
