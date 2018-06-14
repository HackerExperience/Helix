defmodule Helix.Test.Features.Storyline.Quests.Tutorial do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros
  import Helix.Test.Story.Macros

  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Story.Vars, as: StoryVars

  @moduletag :feature

  describe "tutorial" do

    skip_on_travis_slowpoke()
    test "flow" do
      {server_socket, %{account: account, manager: manager}} =
        ChannelSetup.join_storyline_server(socket_opts: [client: :web1])

      entity = EntityHelper.fetch_entity_from_account(account)
      entity_id = entity.entity_id
      gateway = ServerHelper.fetch(server_socket.assigns.gateway.server_id)
      gateway_ip = ServerHelper.get_ip(gateway, manager.network_id)

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
          "reply_id" => s.tutorial.setup.msg2,
          "contact_id" => s.contact.friend
        }
      ref = push account_socket, "email.reply", params
      assert_reply ref, :ok, _, timeout()

      # Contact just replied with the next message
      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg3, :msg4, s.tutorial.setup

      # Now we'll reply back and finally proceed to the next step
      params =
        %{
          "reply_id" => s.tutorial.setup.msg4,
          "contact_id" => s.contact.friend
        }
      ref = push account_socket, "email.reply", params
      assert_reply ref, :ok, _, timeout(:slow)

      # Now we've proceeded to the next step.
      [story_step_proceeded] = wait_events [:story_step_proceeded]

      assert_transition story_step_proceeded, s.tutorial.setup

      # Fetch setup data
      %{object: cur_step} = StoryQuery.fetch_step(entity_id, cur_step.contact)

      EventHelper.flush_timer()

      # Soon we receive the first message (setup message) of the step
      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg1, [], s.tutorial.dl_crc

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

      # Right after the download has started, we receive an email
      [process_created] = wait_events [:process_created], timeout()

      EventHelper.flush_timer()

      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg2, [:msg3], s.tutorial.dl_crc

      # Flush pending messages
      EventHelper.flush_timer()

      # There's an automatic reply right after that
      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg3, :msg2, [], s.tutorial.dl_crc

      # Finish the download
      TOPHelper.force_completion(process_created.data.process_id)

      # A reply is automatically submitted once the download is finished
      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg4, :msg3, [:msg5], s.tutorial.dl_crc

      # Flush pending messages
      EventHelper.flush_timer()

      # Jenkins slowpoke
      if System.get_env("HELIX_TEST_ENV") == "jenkins" do
        :timer.sleep(500)
      end

      # And soon after that we'll receive yet another email and proceed to the
      # next step
      [story_email_sent, story_step_proceeded] =
        wait_events [:story_email_sent, :story_step_proceeded]

      assert_email story_email_sent, :msg5, [], s.tutorial.dl_crc

      assert_transition story_step_proceeded, s.tutorial.dl_crc

      # Fetch setup data
      %{object: cur_step} = StoryQuery.fetch_step(entity_id, cur_step.contact)

      # Generated metadata from the Tutorial.NastyVirus setup
      assert cur_step.meta.ip
      assert cur_step.meta.server_id
      assert cur_step.meta.spyware_id

      EventHelper.flush_timer()

      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg1, [], s.tutorial.nasty

      EventHelper.flush_timer()

      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg2, [:msg3], s.tutorial.nasty

      # Let's reply to :msg2 using :msg3
      params =
        %{
          "reply_id" => s.tutorial.nasty.msg3,
          "contact_id" => s.contact.friend
        }
      ref = push account_socket, "email.reply", params
      assert_reply ref, :ok, _, timeout()

      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg3, :msg2, [], s.tutorial.nasty

      EventHelper.flush_timer()

      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg4, [], s.tutorial.nasty

      EventHelper.flush_timer()

      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg5, [], s.tutorial.nasty
      assert story_email_sent.data.meta["ip"] == cur_step.meta.ip

      # Let's bruteforce that IP

      # Now I'll download the requested file
      params =
        %{
          "ip" => cur_step.meta.ip,
          "network_id" => to_string(manager.network_id),
          "bounce_id" => nil
        }

      # Start the download (using the PublicFTP)
      ref = push server_socket, "cracker.bruteforce", params
      assert_reply ref, :ok, _, timeout(:slow)

      [process_created] = wait_events [:process_created]

      process = TOPHelper.fetch_process(process_created)

      EventHelper.flush_timer()

      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg6, [:msg7], s.tutorial.nasty

      # Let's answer with the expected reply
      # Now we'll reply back and finally proceed to the next step
      params =
        %{
          "reply_id" => s.tutorial.nasty.msg7,
          "contact_id" => s.contact.friend
        }
      ref = push account_socket, "email.reply", params
      assert_reply ref, :ok, _, timeout(:slow)

      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg7, :msg6, [], s.tutorial.nasty

      EventHelper.flush_timer()

      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg8, [], s.tutorial.nasty

      # Now we'll simulate the user opening the task manager
      params =
        %{
          "action" => "tutorial_accessed_task_manager"
        }

      ref = push account_socket, "client.action", params
      assert_reply ref, :ok, _, timeout(:slow)

      # After some time, Contact replies with another message
      EventHelper.flush_timer()
      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg9, [:msg10], s.tutorial.nasty

      # Automatic reply comes next
      EventHelper.flush_timer()

      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg10, :msg9, [], s.tutorial.nasty

      # Simulate completion of the process now
      TOPHelper.force_completion(process)

      [server_password_acquired] = wait_events [:server_password_acquired]

      # Automatic email comes right after process completion
      EventHelper.flush_timer()

      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg11, [:msg12], s.tutorial.nasty

      # Next email is sent when user "spots" the targeted virus. Let's simulate
      # this by sending this custom action to the backend.
      params =
        %{
          "action" => "tutorial_spotted_nasty_virus"
        }

      ref = push account_socket, "client.action", params
      assert_reply ref, :ok, _, timeout(:slow)

      # Soon after auto reply `spotted` will be sent
      EventHelper.flush_timer()

      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg12, :msg11, [], s.tutorial.nasty

      # After which `spotted2` will be automatically sent by the contact
      EventHelper.flush_timer()
      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg13, [:msg14], s.tutorial.nasty

      # Let's join the target server
      topic =
        ChannelHelper.server_topic_name(manager.network_id, cur_step.meta.ip)

      join_params =
        %{
          "gateway_ip" => gateway_ip,
          "password" => server_password_acquired.data.password
        }

      # Joins the RCN server
      {:ok, _, target_socket} = join(account_socket, topic, join_params)

      # Now we'll start the download of the spyware virus
      params =
        %{
          "file_id" => cur_step.meta.spyware_id
        }

      ref = push target_socket, "file.download", params
      assert_reply ref, :ok, _, timeout(:slow)

      # And soon after that, player will automatically start pointless_convo
      EventHelper.flush_timer()
      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg14, :msg13, [], s.tutorial.nasty

      # After which Contact automatically replies...
      EventHelper.flush_timer()
      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg15, [:msg16], s.tutorial.nasty

      # And player automatically bounces back...
      EventHelper.flush_timer()
      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg16, :msg15, [], s.tutorial.nasty

      # One more round; auto reply from contact...
      EventHelper.flush_timer()
      [story_email_sent] = wait_events [:story_email_sent]

      assert_email story_email_sent, :msg17, [:msg18], s.tutorial.nasty

      # And auto reply from player...
      EventHelper.flush_timer()
      [story_reply_sent] = wait_events [:story_reply_sent]

      assert_reply story_reply_sent, :msg18, :msg17, [], s.tutorial.nasty
    end
  end
end
