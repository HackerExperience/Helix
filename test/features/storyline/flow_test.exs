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
  alias Helix.Test.Story.Vars, as: StoryVars

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

      # Inherit storyline variables
      s = StoryVars.vars()

      # Player is on mission
      assert [%{object: cur_step}] = StoryQuery.get_steps(entity_id)
      assert cur_step.name == Step.first_step_name()

      # We'll now progress on the first step by replying to the email
      params =
        %{
          "reply_id" => s.step.setup_pc.msg2,
          "contact_id" => s.contact.friend
        }
      ref = push account_socket, "email.reply", params
      assert_reply ref, :ok, _, timeout()

      # Contact just replied with the next message
      [story_email_sent] = wait_events [:story_email_sent]

      assert_email \
        story_email_sent, s.step.setup_pc.msg3, s.step.setup_pc.msg4, cur_step

      # Now we'll reply back and finally proceed to the next step
      params =
        %{
          "reply_id" => s.step.setup_pc.msg4,
          "contact_id" => s.contact.friend
        }
      ref = push account_socket, "email.reply", params
      assert_reply ref, :ok, _, timeout(:slow)

      # Now we've proceeded to the next step.
      [story_step_proceeded] = wait_events [:story_step_proceeded]

      assert_transition \
        story_step_proceeded, s.step.setup_pc.name, s.step.setup_pc.next

      # Fetch setup data
      %{object: cur_step} = StoryQuery.fetch_step(entity_id, cur_step.contact)

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
        story_step_proceeded, "download_cracker", s.step.setup_pc.name
    end
  end
end
