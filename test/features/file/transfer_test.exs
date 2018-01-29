defmodule Helix.Test.Features.File.TransferTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros
  import Helix.Test.Log.Macros

  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Query.File, as: FileQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :feature

  describe "file.download" do
    test "download lifecycle" do
      {socket, %{entity: entity, server: gateway}} =
        ChannelSetup.create_socket()

      {bounce, _} =
        NetworkSetup.Bounce.bounce(total: 3, entity_id: entity.entity_id)

      {socket, %{gateway: gateway, destination: destination}} =
        ChannelSetup.join_server(
          bounce_id: bounce.bounce_id,
          gateway_id: gateway.server_id,
          socket: socket
        )

      # Connect to gateway channel too, so we can receive gateway notifications
      ChannelSetup.join_server(socket: socket, own_server: true)

      gateway_storage = SoftwareHelper.get_storage(gateway)
      {dl_file, _} = SoftwareSetup.file(server_id: destination.server_id)

      request_id = Random.string(max: 256)

      params =
        %{
          "file_id" => dl_file.file_id |> to_string(),
          "request_id" => request_id
        }

      ref = push socket, "file.download", params
      assert_reply ref, :ok, response, timeout(:slow)

      # Download is acknowledge (`:ok`). Contains the `request_id`.
      assert response.meta.request_id == request_id
      assert response.data == %{}

      # After a while, client receives the new process through top recalque
      [l_top_recalcado_event, l_process_created_event] =
        wait_events [:top_recalcado, :process_created]

      # Each one have the client-defined request_id
      assert l_top_recalcado_event.meta.request_id == request_id
      assert l_process_created_event.meta.request_id == request_id

      # Force completion of the process
      # Due to forced completion, we won't have the `request_id` information
      # on the upcoming events available on our tests. But they should exist on
      # real life.
      process = ProcessQuery.fetch(l_process_created_event.data.process_id)
      TOPHelper.force_completion(process)

      # Note we are subscribed to events on both the `gateway` and `destination`
      [file_downloaded_event, file_added_event] =
        wait_events [:file_downloaded, :file_added]

      # Process no longer exists
      refute ProcessQuery.fetch(process.process_id)

      # The new file exists on my server
      new_file =
        file_downloaded_event.data.file.id
        |> File.ID.cast!()
        |> FileQuery.fetch()

      assert new_file.storage_id == gateway_storage.storage_id

      # The old file still exists on the target server, as expected
      r_file = FileQuery.fetch(dl_file.file_id)
      assert r_file.storage_id == SoftwareHelper.get_storage_id(destination)

      # Client received the FileAddedEvent
      assert file_added_event.data.file.id == to_string(new_file.file_id)

      # Now let's check the log generation

      # Log on gateway (`gateway` downloaded from `<someone>`)
      assert [log_gateway | _] = LogQuery.get_logs_on_server(gateway.server_id)
      assert_log \
        log_gateway, gateway.server_id, entity.entity_id,
        "localhost downloaded",
        contains: [dl_file.name]

      # Verify logging worked correctly within the bounce nodes
      assert_bounce \
        bounce, gateway, destination, entity,
        rejects: [dl_file.name, "download"]

      # Log on destination (`<someone>` downloaded file at `destination`)
      assert [log_destination | _] =
        LogQuery.get_logs_on_server(destination.server_id)
      assert_log \
        log_destination, destination.server_id, entity.entity_id,
        "from localhost",
        contains: [dl_file.name]

      TOPHelper.top_stop(gateway)
    end
  end
end
