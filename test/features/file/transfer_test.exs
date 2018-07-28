defmodule Helix.Test.Features.File.TransferTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros
  import Helix.Test.Log.Macros

  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Query.File, as: FileQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Log.Helper, as: LogHelper
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

      account_id = AccountHelper.cast_from_entity(entity.entity_id)

      # Connect to gateway channel too, so we can receive gateway publications
      ChannelSetup.join_server(socket: socket, own_server: true)

      # Connect to account channel, so we can receive notifications
      ChannelSetup.join_account(socket: socket, account_id: account_id)

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
      [file_downloaded_event, file_added_event, notification_added_event] =
        wait_events [:file_downloaded, :file_added, :notification_added]

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

      # Client received the NotificationAddedEvent
      assert notification_added_event.data.class == :server
      assert notification_added_event.data.code == :file_downloaded

      # Notification contains information about which server it took place
      assert notification_added_event.data.server_id ==
        to_string(gateway.server_id)

      # Notification contains required data
      notification_data = notification_added_event.data.data
      assert notification_data.id == to_string(new_file.file_id)
      assert notification_data.name == new_file.name
      assert notification_data.type == to_string(new_file.software_type)
      assert notification_data.extension
      assert notification_data.version

      # Now let's check the log generation

      log_gateway = LogHelper.get_last_log(gateway, :file_download_gateway)

      file_name = LogHelper.log_file_name(dl_file)

      assert_log log_gateway, gateway.server_id, entity.entity_id,
        :file_download_gateway, %{file_name: file_name}

      # Verify logging worked correctly within the bounce nodes
      assert_bounce bounce, gateway, destination, entity

      log_destination =
        LogHelper.get_last_log(destination, :file_download_endpoint)

      # Log on destination (`<someone>` downloaded file at `destination`)
      assert_log log_destination, destination.server_id, entity.entity_id,
        :file_download_endpoint, %{file_name: file_name}

      # TODO: #388 Underlying connection(s) were removed

      TOPHelper.top_stop(gateway)
    end
  end

  describe "file.upload" do
    test "upload lifecycle" do
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

      # Connect to gateway channel too, so we can receive gateway publications
      ChannelSetup.join_server(socket: socket, own_server: true)

      destination_storage = SoftwareHelper.get_storage(destination)
      {up_file, _} = SoftwareSetup.file(server_id: gateway.server_id)

      request_id = Random.string(max: 256)

      params =
        %{
          "file_id" => up_file.file_id |> to_string(),
          "request_id" => request_id
        }

      ref = push socket, "file.upload", params
      assert_reply ref, :ok, response, timeout(:slow)

      # Upload is acknowledge (`:ok`). Contains the `request_id`.
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
      [file_uploaded_event, file_added_event] =
        wait_events [:file_uploaded, :file_added]

      # Process no longer exists
      refute ProcessQuery.fetch(process.process_id)

      # The new file exists on my server
      new_file =
        file_uploaded_event.data.file.id
        |> File.ID.cast!()
        |> FileQuery.fetch()

      assert new_file.storage_id == destination_storage.storage_id

      # The old file still exists on the local server, as expected
      l_file = FileQuery.fetch(up_file.file_id)
      assert l_file.storage_id == SoftwareHelper.get_storage_id(gateway)

      # Client received the FileAddedEvent
      assert file_added_event.data.file.id == to_string(new_file.file_id)

      # Now let's check the log generation
      file_name = LogHelper.log_file_name(up_file)

      # Log on gateway (`gateway` uploaded to `<someone>`)
      log_gateway = LogHelper.get_last_log(gateway, :file_upload_gateway)
      assert_log log_gateway, gateway.server_id, entity.entity_id,
        :file_upload_gateway, %{file_name: file_name}

      # Verify logging worked correctly within the bounce nodes
      assert_bounce bounce, gateway, destination, entity

      # Log on destination (`<someone>` uploaded file at `destination`)
      log_destination =
        LogHelper.get_last_log(destination, :file_upload_endpoint)
      assert_log log_destination, destination.server_id, entity.entity_id,
        :file_upload_endpoint, %{file_name: file_name}

      # TODO: #388 Underlying connection(s) were removed

      TOPHelper.top_stop(gateway)
    end
  end
end
