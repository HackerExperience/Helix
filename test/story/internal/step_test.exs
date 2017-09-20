defmodule Helix.Story.Internal.StepTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Internal.Step, as: StepInternal

  alias Helix.Test.Story.Helper, as: StoryHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "get_current_step/1" do
    test "returns current step" do
      {story_step, _} = StorySetup.story_step()

      current = StepInternal.get_current_step(story_step.entity_id)

      assert current == story_step
    end

    test "formats the step meta using `format_meta/1` from Steppable" do
      {story_step, _} =
        StorySetup.story_step(
          name: :fake_steps@test_meta,
          meta: %{foo: :bar, id: Entity.ID.generate()}
        )

      current = StepInternal.get_current_step(story_step.entity_id)

      assert current == story_step
    end

    test "returns nil when entity isn't part of any step" do
      refute StepInternal.get_current_step(Entity.ID.generate())
    end
  end

  describe "proceed/1 and proceed/2" do
    test "proceed/1 setups the first step" do
      entity_id = Entity.ID.generate()
      {first_step, _} = StorySetup.step(entity_id: entity_id)

      # Not part of any step
      refute StepInternal.get_current_step(entity_id)

      # Proceeds to the first step
      assert {:ok, story_step} = StepInternal.proceed(first_step)

      assert story_step.entity_id == entity_id
      assert story_step.step_name == first_step.name

      # Retrieve from DB
      db_entry = StepInternal.get_current_step(entity_id)
      assert db_entry == story_step
    end

    test "removes the entity from the previous step, puts it into the next" do
      {prev_step, next_step, %{entity_id: entity_id}} =
        StorySetup.step_sequence()

      # Currently on `prev_step`
      step_before = StepInternal.get_current_step(entity_id)
      assert step_before.step_name == prev_step.name
      assert step_before.meta == prev_step.meta

      # Proceeds to the next step
      StepInternal.proceed(prev_step, next_step)

      # It proceeded to the next step
      step_after = StepInternal.get_current_step(entity_id)
      assert step_after.step_name == next_step.name
      assert step_after.meta == next_step.meta

      # Make sure there's only one entry (the previous step was deleted)
      assert length(StoryHelper.get_steps_from_entity(entity_id)) == 1
    end
  end

  describe "update_meta/1" do
    test "step meta is overwritten" do
      {_, %{step: step, entity_id: entity_id}} =
        StorySetup.story_step(name: :fake_steps@test_counter, meta: %{i: 0})

      # Current step has the original meta, as expected
      story_step0 = StepInternal.get_current_step(entity_id)
      assert story_step0.meta == %{i: 0}

      # Create a new step with a different meta
      new_step = %{step| meta: %{i: 1}}

      # Persist meta modification
      assert {:ok, _} = StepInternal.update_meta(new_step)

      # Ensure step meta changed
      story_step1 = StepInternal.get_current_step(entity_id)
      assert story_step1.meta == %{i: 1}

      # One more time!
      StepInternal.update_meta(%{step| meta: %{i: 2}})

      story_step2 = StepInternal.get_current_step(entity_id)
      assert story_step2.meta == %{i: 2}
    end

    test "raises if step is not found" do
      {step, _} = StorySetup.step()
      assert_raise Ecto.NoResultsError, fn ->
        StepInternal.update_meta(step)
      end
    end
  end

  describe "unlock_reply/2" do
    test "new reply is saved on the story_step, marked as unlocked" do
      {_, %{step: step, entity_id: entity_id}} = StorySetup.story_step()

      reply_id1 = "1st_reply"
      reply_id2 = "2nd_reply"

      # Mark as unlocked
      assert {:ok, new_entry1} = StepInternal.unlock_reply(step, reply_id1)
      assert new_entry1.allowed_replies == [reply_id1]

      # Ensure data on DB is correct
      db_entry1 = StepInternal.get_current_step(entity_id)
      assert db_entry1.allowed_replies == [reply_id1]

      # Add another reply
      assert {:ok, new_entry2} = StepInternal.unlock_reply(step, reply_id2)
      assert new_entry2.allowed_replies == [reply_id1, reply_id2]

      # Ensure it got pushed into the list
      db_entry2 = StepInternal.get_current_step(entity_id)
      assert db_entry2.allowed_replies == [reply_id1, reply_id2]
    end

    test "repeated replies are not added to the database" do
      {_, %{step: step, entity_id: entity_id}} = StorySetup.story_step()

      reply_id = "my_repeated_reply"

      assert {:ok, _} = StepInternal.unlock_reply(step, reply_id)
      assert {:ok, _} = StepInternal.unlock_reply(step, reply_id)
      assert {:ok, _} = StepInternal.unlock_reply(step, reply_id)

      db_entry = StepInternal.get_current_step(entity_id)
      assert db_entry.allowed_replies == [reply_id]
    end

    test "raises if step is not found" do
      {step, _} = StorySetup.step()
      assert_raise Ecto.NoResultsError, fn ->
        StepInternal.unlock_reply(step, "reply")
      end
    end
  end

  describe "save_email/2" do
    test "new email is saved on the database" do
      {_, %{step: step, entity_id: entity_id}} = StorySetup.story_step()

      email_id1 = "1st_email"
      email_id2 = "2nd_email"

      # Save first email
      assert {:ok, new_entry1} = StepInternal.save_email(step, email_id1)
      assert new_entry1.emails_sent == [email_id1]

      # Ensure data on DB is correct
      db_entry1 = StepInternal.get_current_step(entity_id)
      assert db_entry1.emails_sent == [email_id1]

      # Add another reply
      assert {:ok, new_entry2} = StepInternal.save_email(step, email_id2)
      assert new_entry2.emails_sent == [email_id1, email_id2]

      # Ensure it got pushed into the list
      db_entry2 = StepInternal.get_current_step(entity_id)
      assert db_entry2.emails_sent == [email_id1, email_id2]
    end

    test "repeated emails are pushed to the database as usual" do
      {_, %{step: step, entity_id: entity_id}} = StorySetup.story_step()

      email_id = "my_repeated_email"

      assert {:ok, _} = StepInternal.save_email(step, email_id)
      assert {:ok, _} = StepInternal.save_email(step, email_id)
      assert {:ok, _} = StepInternal.save_email(step, email_id)

      db_entry = StepInternal.get_current_step(entity_id)
      assert db_entry.emails_sent == [email_id, email_id, email_id]
    end

    test "raises if step is not found" do
      {step, _} = StorySetup.step()
      assert_raise Ecto.NoResultsError, fn ->
        StepInternal.save_email(step, "email")
      end
    end
  end
end
