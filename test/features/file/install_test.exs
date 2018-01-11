defmodule Helix.Test.Features.File.InstallTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Case.ID
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros

  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Software.Model.Virus
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Query.Virus, as: VirusQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @moduletag :feature

  describe "file.install" do
    test "install lifecycle (virus)" do
      {
        socket,
        %{gateway: gateway, destination: destination, gateway_entity: entity}
      } = ChannelSetup.join_server()

      # Connect to the account channel so we can receive Account notifications
      ChannelSetup.join_account(account_id: entity.entity_id, socket: socket)

      file = SoftwareSetup.virus!(server_id: destination.server_id)
      request_id = Random.string(max: 256)

      params =
        %{
          "file_id" => file.file_id |> to_string(),
          "request_id" => request_id
        }

      ref = push socket, "file.install", params
      assert_reply ref, :ok, response, timeout(:slow)

      # Installation is acknowledge (`:ok`). Contains the `request_id`.
      assert response.meta.request_id == request_id
      assert response.data == %{}

      # After a while, client receives the new process through top recalque
      [l_process_created_event] = wait_events [:process_created]

      # Force completion of the process
      process = ProcessQuery.fetch(l_process_created_event.data.process_id)
      TOPHelper.force_completion(process)

      # Process no longer exists
      refute ProcessQuery.fetch(process.process_id)

      # Virus has been installed
      virus = VirusQuery.fetch(process.file_id)

      assert %Virus{} = virus
      assert virus.file_id == file.file_id
      assert virus.entity_id == entity.entity_id
      assert virus.is_active?

      # The file metadata returns it as installed
      new_file = FileQuery.fetch(file.file_id)
      assert new_file.meta.installed?

      # Client receives confirmation that the virus has been installed
      [virus_installed] = wait_events [:virus_installed]

      assert_id virus_installed.data.file.id, file.file_id
      assert_id virus_installed.meta.process_id, process.process_id

      TOPHelper.top_stop(gateway)
    end
  end
end
