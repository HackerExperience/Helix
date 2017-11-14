defmodule Helix.Test.Features.Process.Lifecycle do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Process.Macros

  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Software.Query.Storage, as: StorageQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :feature

  @internet_id NetworkHelper.internet_id()

  describe "process" do

    test "creation and allocation" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

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

      assert_push "event", top_recalcado_event, timeout()
      assert_push "event", process_created_event, timeout()

      process_id = Process.ID.cast!(process_created_event.data.process_id)

      assert top_recalcado_event.event == "top_recalcado"
      assert process_created_event.event == "process_created"

      # Let's fetch the process, just to make sure
      process = ProcessQuery.fetch(process_id)

      # The process received allocation
      refute Enum.empty?(process.l_reserved)
      refute Enum.empty?(process.r_reserved)

      resources =
        gateway.motherboard_id
        |> MotherboardQuery.fetch()
        |> MotherboardQuery.resources()

      server_dlk = resources.net[@internet_id].downlink

      # Process received no allocations of CPU/ULK (some RAM for static usage)
      assert process.l_allocated.cpu == 0.0
      assert process.l_allocated.ulk[@internet_id] == 0.0
      assert process.l_allocated.ram > 0

      # But received 100% of server DLK resources
      assert_resource process.l_allocated.dlk[@internet_id], server_dlk
    end

    # This is pretty much the same test above, but now we'll focus on the other
    # half: completing the process. We want to avoid using `force_completion`
    # from TOPHelper, so the completion is actually spontaneous.
    # In order to do that we create a very small process which needs to transfer
    # a file of about ~1kb, which takes less than a second.
    test "spontaneous completion" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      # Connect to gateway channel too, so we can receive gateway notifications
      ChannelSetup.join_server(socket: socket, own_server: true)

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
      # Extra time is desired to let all "spawned" connections close
      # Below timer is required because we want to let the process complete by
      # itself, without using `force_completion`
      sleep(200)

      import Helix.Test.Channel.Macros

      wait_events [:top_recalcado, :top_recalcado, :file_downloaded]

      # I haz file!11
      assert [downloaded_file] = StorageQuery.files_on_storage(gateway_storage)

      # Same file...
      assert downloaded_file.name == file.name
      assert downloaded_file.modules == file.modules

      # Different ID
      refute downloaded_file.file_id == file.file_id
    end
  end
end
