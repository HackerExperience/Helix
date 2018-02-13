defmodule Helix.Story.Event.Handler.StoryTest do

  use Helix.Test.Case.Integration

  import ExUnit.CaptureLog

  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery

  alias Helix.Test.Event.Helper, as: EventHelper
  alias Helix.Test.Event.Setup, as: EventSetup
  alias Helix.Test.Story.Helper, as: StoryHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "handling of ReplySent events" do
    test "event is pattern matched correctly" do
      {_, %{step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.Story.reply_sent(step, "reply_to_e1", "e1")

      assert capture_log(fn ->
        EventHelper.emit(event)
      end) =~ "replied_to_e1"
    end

    test "unregistered event isn't matched" do
      {_, %{step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.Story.reply_sent(step, "invalid_reply", "e1")

      # Nothing happens...
      EventHelper.emit(event)
    end
  end

  describe "handling of completion events" do
    test "proceeds to the next step" do
      {_, %{entity_id: entity_id, step: step}} =
        StorySetup.story_step(name: :fake_steps@test_msg, meta: %{})

      event = EventSetup.Story.reply_sent(step, "reply_to_e3", "e3")

      EventHelper.emit(event)

      %{object: new_step} = StoryQuery.fetch_step(entity_id, step.contact)

      refute new_step == step
      assert new_step.name == Step.get_next_step(step)
    end
  end

  describe "handling of restart events" do
    test "restarts to the specified checkpoint" do
      {story_step, %{step: step}} = StorySetup.story_step(
        name: :tutorial@download_cracker, meta: %{}, ready: true
      )

      # Just to make sure the generated step went through `Steppable.start/1`
      assert story_step.meta.server_id
      assert story_step.meta.ip
      assert story_step.meta.cracker_id

      # Advance a few messages so we can check that it rolled back to checkpoint
      %{entry: story_step} = StoryHelper.send_fake_email(step, "wat")

      # And for the sake of testability, let's pretend that we are allowed to
      # reply back with `foobar`
      story_step = %{story_step| allowed_replies: ["foobar"]}

      # There are 2 registered messages (first one from step setup + "wat")
      story_email = StoryQuery.fetch_email(step.entity_id, step.contact)
      assert length(story_email.emails) == 2

      # Remove the file
      story_step.meta.cracker_id
      |> FileInternal.fetch()
      |> FileInternal.delete()

      # Fake a FileDeletedEvent
      story_step.meta.cracker_id
      |> EventSetup.Software.file_deleted(story_step.meta.server_id)
      |> EventHelper.emit()

      %{entry: new_entry, object: new_step} =
        StoryQuery.fetch_step(step.entity_id, step.contact)

      # Story meta has been updated!
      refute new_entry.meta.cracker_id == story_step.meta.cracker_id

      # Other stuff hasn't changed
      assert new_entry.meta.server_id == story_step.meta.server_id
      assert new_entry.meta.ip == story_step.meta.ip

      # Object (Step.t) meta is also correct
      assert new_entry.meta == new_step.meta
      assert story_step.meta == step.meta
      refute new_entry.meta == story_step.meta

      # The `allowed_replies` is different because the messages were rolled back
      refute new_entry.allowed_replies == story_step.allowed_replies

      story_email = StoryQuery.fetch_email(step.entity_id, step.contact)

      # There's only one email: the one we've rolled back to.
      assert [email] = story_email.emails
      assert email.id == "download_cracker1"

      # Email meta got updated too
      assert email.meta["ip"] == new_entry.meta.ip
    end
  end
end
