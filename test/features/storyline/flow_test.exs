defmodule Helix.Test.Features.Storyline.Flow do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros
  import Helix.Test.Story.Macros

  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  @moduletag :feature

  describe "tutorial" do
    test "flow" do
      {server_socket, %{account: account, manager: manager}} =
        ChannelSetup.join_storyline_server()

      entity = EntityHelper.fetch_entity_from_account(account)
      entity_id = entity.entity_id

      {account_socket, _} =
        ChannelSetup.join_account(
          account_id: account.account_id, socket: server_socket
        )

      # Player is on mission
      assert %{object: %{name: step_name}} =
        StoryQuery.fetch_current_step(entity_id)
      assert step_name == Step.first_step_name()

      # We'll now complete the first step by replying to the email
      params = %{"reply_id" => "back_thanks"}
      ref = push account_socket, "email.reply", params
      assert_reply ref, :ok, _, timeout(:slow)

      # Now we've proceeded to the next step.
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
          "ip" => ServerHelper.get_ip(target_id, manager.network_id),
          "network_id" => to_string(manager.network_id)
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
