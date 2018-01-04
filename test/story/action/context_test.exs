defmodule Helix.Story.Action.ContextTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Action.Context, as: ContextAction

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

    test "refuses to save an entry that already exists" do
      cur_context = %{foo: %{bar: 1}}
      {story_context, _} = StorySetup.Context.context(context: cur_context)

      # We are trying to set `foo.bar = 2`, but it's already set as 1!
      assert {:error, reason} =
        ContextAction.save(story_context.entity_id, :foo, :bar, 2)
      assert reason == :path_exists
    end
  end
end
