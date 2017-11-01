defmodule Helix.Test.Features.ProcessLifecycle do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Case.ID

  alias HELL.Utils
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Model.Process
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Server.Websocket.Channel.Server, as: ServerChannel

  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :feature

  @internet_id NetworkHelper.internet_id()

  describe "process" do

    test "creation and allocation" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      player_entity_id = socket.assigns.gateway.entity_id

      target_nip = ServerHelper.get_nip(destination)

      # Create the File that we'll downloaded
      {file, _} = SoftwareSetup.file(server_id: destination.server_id)

      params = %{
        "file_id" => file.file_id |> to_string(),
      }

      # Starts the file download
      ref = push socket, "file.download", params

      assert_reply ref, :ok, response

      # The process was created
      assert response.data.process_id
      process_id = Process.ID.cast!(response.data.process_id)

      # Wait a bit to ensure the process has received allocation
      :timer.sleep(10)

      # Let's fetch the process, just to make sure
      process = ProcessQuery.fetch(process_id)

      # The process received allocation
      assert process.allocated

      resources =
        gateway.motherboard_id
        |> MotherboardQuery.fetch()
        |> MotherboardQuery.resources()

      server_dlk = resources.net[@internet_id].downlink

      # Process received no allocations of CPU, RAM or ULK
      assert process.allocated.cpu == 0.0
      assert process.allocated.ram == 0.0
      assert process.allocated.ulk[@internet_id] == 0.0

      # But received 100% of server DLK resources
      assert_in_delta process.allocated.dlk[@internet_id], server_dlk, 0.1
    end

    # This is pretty much the same test above, but now we'll focus on the other
    # half: completing the process. We want to avoid using `force_completion`
    # from TOPHelper, so the completion is actually spontaneous.
    # In order to do that we create a very small process which needs to transfer
    # a file of about ~1kb, taking less than a second.
    test "spontaneous completion" do
      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server()

      player_entity_id = socket.assigns.gateway.entity_id

      target_nip = ServerHelper.get_nip(destination)

      # Create the File that we'll downloaded
      {file, _} = SoftwareSetup.file(server_id: destination.server_id, size: 10)

      params = %{
        "file_id" => file.file_id |> to_string(),
      }

      # Starts the file download
      ref = push socket, "file.download", params

      assert_reply ref, :ok, response

      # The process was created
      assert response.data.process_id
      process_id = Process.ID.cast!(response.data.process_id)

      process = ProcessQuery.fetch(process_id)

      alias Helix.Test.Software.Helper, as: SoftwareHelper
      alias Helix.Software.Query.Storage, as: StorageQuery
      gateway_storage = SoftwareHelper.get_storage(gateway)

      # No files on gateway server. Download process started but not completed.
      assert [] == StorageQuery.files_on_storage(gateway_storage)

      # Wait for process completion (Process itself takes about 100ms)
      # Extra time is desired to let all "spawned" connections close
      :timer.sleep(200)

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
