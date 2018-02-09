defmodule Helix.Story.Model.Story.StepTest do

  use ExUnit.Case, async: true

  import Ecto.Changeset

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Story

  alias HELL.TestHelper.Random
  alias Helix.Test.Story.Helper, as: StoryHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "create_changeset/1" do
    test "changeset is created as expected with valid input" do
      params = %{
        entity_id: Entity.ID.generate(),
        contact_id: StoryHelper.contact_id(),
        step_name: Random.atom(),
        meta: %{}
      }

      changeset = Story.Step.create_changeset(params)
      assert changeset.valid?

      story_step = apply_changes(changeset)
      assert story_step.entity_id == params.entity_id
      assert story_step.step_name == params.step_name
      assert story_step.meta == params.meta
      assert story_step.emails_sent == []
      assert story_step.allowed_replies == []
    end

    test "refuses to create changeset if invalid data is given" do
      params = %{
        entity_id: Entity.ID.generate(),
        step_name: Random.atom(),
        meta: %{}
      }

      params1 = Map.delete(params, :step_name)
      params2 = Map.delete(params, :entity_id)
      params3 = Map.delete(params, :meta)
      params4 = %{params| step_name: "invalid_step"}
      params5 = %{params| meta: "invalid_meta"}

      cs1 = Story.Step.create_changeset(params1)
      cs2 = Story.Step.create_changeset(params2)
      cs3 = Story.Step.create_changeset(params3)
      cs4 = Story.Step.create_changeset(params4)
      cs5 = Story.Step.create_changeset(params5)

      refute cs1.valid?
      refute cs2.valid?
      refute cs3.valid?
      refute cs4.valid?
      refute cs5.valid?
    end
  end

  describe "replace_meta/2" do
    test "Story.Step meta is replaced" do
      {story_step, _} = StorySetup.fake_story_step()

      new_meta = %{palmeiras: :nao, tem: :mundial}
      new_story = Story.Step.replace_meta(story_step, new_meta)

      assert new_story.valid?
      assert get_change(new_story, :meta) == new_meta
    end
  end

  describe "unlock_reply/2" do
    test "new reply is added to the list" do
      {entry1, _} = StorySetup.fake_story_step(allowed_replies: [])
      {entry2, _} = StorySetup.fake_story_step(allowed_replies: ["r1", "r2"])
      {entry3, _} = StorySetup.fake_story_step(allowed_replies: ["r3"])

      new_entry1 = Story.Step.unlock_reply(entry1, "r3")
      new_entry2 = Story.Step.unlock_reply(entry2, "r3")
      new_entry3 = Story.Step.unlock_reply(entry3, "r3")

      # Resulting changeset is valid
      assert new_entry1.valid?
      assert new_entry2.valid?
      assert new_entry3.valid?

      # And contains the new reply...
      assert get_change(new_entry1, :allowed_replies) == ["r3"]

      # Without overwriting the previous ones
      assert get_change(new_entry2, :allowed_replies) == ["r1", "r2", "r3"]

      # And ignoring repeated entries (no changes, since it already has "r3")
      refute get_change(new_entry3, :allowed_replies)
    end
  end

  describe "append_email/2" do
    test "new email is added to the list" do
      {entry1, _} = StorySetup.fake_story_step(emails_sent: [])
      {entry2, _} = StorySetup.fake_story_step(emails_sent: ["e1", "e2"])
      {entry3, _} = StorySetup.fake_story_step(emails_sent: ["e3", "e3"])

      new_entry1 = Story.Step.append_email(entry1, "e3", ["r1"])
      new_entry2 = Story.Step.append_email(entry2, "e3", ["r2"])
      new_entry3 = Story.Step.append_email(entry3, "e3", ["r3"])

      # Resulting changeset is valid
      assert new_entry1.valid?
      assert new_entry2.valid?
      assert new_entry3.valid?

      # And contains the new email...
      assert get_change(new_entry1, :emails_sent) == ["e3"]

      # Without overwriting the previous ones
      assert get_change(new_entry2, :emails_sent) == ["e1", "e2", "e3"]

      # And not caring about repeated entries
      assert get_change(new_entry3, :emails_sent) == ["e3", "e3", "e3"]

      # And allowed_replies is always overwritten
      assert get_change(new_entry1, :allowed_replies) == ["r1"]
      assert get_change(new_entry2, :allowed_replies) == ["r2"]
      assert get_change(new_entry3, :allowed_replies) == ["r3"]
    end
  end
end
