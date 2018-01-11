defmodule Helix.Story.Action.ContextTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Model.Server
  alias Helix.Story.Action.Context, as: ContextAction
  alias Helix.Story.Query.Context, as: ContextQuery

  alias Helix.Test.Story.Setup, as: StorySetup

  describe "save/4" do
    test "saves the value within the given path" do
      {%{entity_id: entity_id}, _} = StorySetup.Context.context()

      assert {:ok, story_context} =
        ContextAction.save(entity_id, :foo, :bar, "baridade")

      # Added the context as expected
      expected_context = %{foo: %{bar: "baridade"}}
      assert story_context.context == expected_context
    end

    test "accepts nested subfields" do
      {%{entity_id: entity_id}, _} = StorySetup.Context.context()

      assert {:ok, story_context} =
        ContextAction.save(entity_id, :foo, [:bar, :baz, :inga], 42)

      assert story_context.context == %{foo: %{bar: %{baz: %{inga: 42}}}}
    end

    test "handles Helix ID transparently" do
      {%{entity_id: entity_id}, _} = StorySetup.Context.context()

      server_id = Server.ID.generate()
      assert {:ok, story_context} =
        ContextAction.save(entity_id, :foo, [:id], server_id)

      assert story_context.context.foo.id == server_id

      # Let's query it to make sure it returns the same result
      db_context = ContextQuery.fetch(entity_id)
      assert db_context.context.foo.id == server_id
    end

    test "refuses to save an entry that already exists" do
      cur_context = %{foo: %{bar: 1}}
      {story_context, _} = StorySetup.Context.context(context: cur_context)

      # We are trying to set `foo.bar = 2`, but it's already set as 1!
      assert {:error, reason} =
        ContextAction.save(story_context.entity_id, :foo, :bar, 2)
      assert reason == :path_exists
    end
  end

  describe "update/4" do
    test "updates an entry" do
      cur_context = %{foo: %{bar: 1}}
      {story_context, _} = StorySetup.Context.context(context: cur_context)

      assert {:ok, new_story_context} =
        ContextAction.update(story_context.entity_id, :foo, :bar, 2)

      refute story_context == new_story_context
      assert new_story_context.context.foo.bar == 2
    end

    test "accepts nested subfields" do
      cur_context = %{foo: %{bar: %{baz: 1}}}
      {story_context, _} = StorySetup.Context.context(context: cur_context)

      assert {:ok, new_story_context} =
        ContextAction.update(story_context.entity_id, :foo, [:bar, :baz], 2)

      assert new_story_context.context.foo.bar.baz == 2
    end

    test "handles Helix ID transparently" do
      {%{entity_id: entity_id}, _} = StorySetup.Context.context()

      id_1 = Server.ID.generate()
      id_2 = Server.ID.generate()

      # Let's add a Server.ID to `foo.bar`
      assert {:ok, _} = ContextAction.save(entity_id, :foo, :bar, id_1)

      # Now let's update it to another ID
      assert {:ok, story_context} =
        ContextAction.update(entity_id, :foo, :bar, id_2)

      assert story_context.context.foo.bar == id_2

      # Fetching from DB also returns the correct ID
      db_context = ContextQuery.fetch(entity_id)
      assert db_context.context.foo.bar == id_2
    end

    test "refuses to update an entry that does not exist" do
      {story_context, _} = StorySetup.Context.context()
      assert Enum.empty?(story_context.context)

      assert {:error, reason} =
        ContextAction.update(story_context.entity_id, :foo, :bar, 1)
      assert reason == :path_not_found
    end
  end
end
