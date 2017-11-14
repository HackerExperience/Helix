defmodule Helix.Test.Features.Storyline.Flow do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros
  import Helix.Test.Story.Macros

  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  @internet_id NetworkHelper.internet_id()

  @moduletag :feature

  describe "tutorial" do
    test "flow" do
      {server_socket, %{gateway: _server, account: account}} =
        ChannelSetup.join_server(own_server: true)

      entity = EntityHelper.fetch_entity_from_account(account)
      entity_id = entity.entity_id

      {account_socket, _} =
        ChannelSetup.join_account(
          account_id: account.account_id, socket: server_socket
        )

      # Register player at the first step
      # TODO: This should be done as a response of AccountCreatedEvent
      StorySetup.story_step(
        entity_id: entity_id, name: :tutorial@SetupPc, meta: %{}
      )

      # Player is on mission
      assert %{object: %{name: step_name}} =
        StoryQuery.fetch_current_step(entity_id)
      assert step_name == :tutorial@setup_pc

      # We'll now complete the first mission by replying to the email
      params = %{"reply_id" => "back_thanks"}
      ref = push account_socket, "email.reply", params
      assert_reply ref, :ok, _, timeout(:slow)

      # Now we've proceeded to the next step
      [story_step_proceeded] = wait_events [:story_step_proceeded]

      assert_transition story_step_proceeded, "setup_pc", "download_cracker"

      # Fetch setup data
      %{object: cur_step} = StoryQuery.fetch_current_step(entity_id)

      cracker_id = cur_step.meta.cracker_id
      target_id = cur_step.meta.server_id

      # Now I'll download the requested file
      params =
        %{
          "file_id" => to_string(cracker_id),
          "ip" => ServerHelper.get_ip(target_id),
          "network_id" => to_string(@internet_id)
        }

      # Start the download (using the PublicFTP)
      ref = push server_socket, "pftp.file.download", params
      assert_reply ref, :ok, _, timeout(:slow)

      [process_created] = wait_events [:process_created], timeout()

      # Finish the download
      TOPHelper.force_completion(process_created.data.process_id)

      # We've proceeded to the next step!
      [story_step_proceeded] = wait_events [:story_step_proceeded]

      assert_transition \
        story_step_proceeded, "download_cracker", "download_cracker"
    end
  end
end
