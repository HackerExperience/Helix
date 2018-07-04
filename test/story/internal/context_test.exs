defmodule Helix.Story.Internal.ContextTest do

  use Helix.Test.Case.Integration

  alias Helix.Story.Model.Story
  alias Helix.Story.Internal.Context, as: ContextInternal
  alias Helix.Story.Repo, as: StoryRepo

  alias HELL.TestHelper.Random
  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Story.Setup, as: StorySetup

  describe "fetch/1" do
    test "returns the row, formatting it" do
      # The row we'll retrieve has the following context:
      context =
        %{
          foo: %{
            bar: 1,
            baz: %{vai: "curintia"},
            bab: "bage"
          }
        }

      # Context much
      {story_context, _} = StorySetup.Context.context(context: context)

      entry = ContextInternal.fetch(story_context.entity_id)

      assert %Story.Context{} = entry
      assert entry.context == context
    end

    test "returns empty when nothing is found" do
      refute ContextInternal.fetch(EntityHelper.id())
    end
  end

  describe "fetch_for_update/1" do
    test "returns the row, formatting it" do
      context = %{foo: %{bar: [1, "2", %{tr: "es"}]}}
      {story_context, _} = StorySetup.Context.context(context: context)

      StoryRepo.transaction fn ->
        entry = ContextInternal.fetch_for_update(story_context.entity_id)

        assert entry.context == context
      end
    end

    test "blows up when not in transaction" do
      assert_raise RuntimeError, fn ->
        ContextInternal.fetch_for_update(EntityHelper.id())
      end
    end
  end

  describe "create/1" do
    test "creates the entry for entity" do
      entity_id = EntityHelper.id()

      assert {:ok, context} = ContextInternal.create(entity_id)

      assert context.entity_id == entity_id
      assert Enum.empty?(context.context)
    end
  end

  describe "save/2" do
    test "appends the entry (on empty context)" do
      {story_context, _} = StorySetup.Context.context()

      # Empty context
      assert Enum.empty?(story_context.context)

      entry = %{field: %{sub: Random.number()}}

      assert {:ok, new_story_context} =
        ContextInternal.save(story_context.entity_id, entry, [:field, :sub])

      assert new_story_context.context == entry
    end

    test "appends the entry (on existing, non-conflicting context)" do
      # Current context
      cur_context =
        %{
          foo: %{bar: 1},
          tro: %{lo: "lo"}
        }

      {story_context, _} = StorySetup.Context.context(context: cur_context)

      # We want to add this entry
      entry = %{foo: %{baz: 2}}

      assert {:ok, new_story_context} =
        ContextInternal.save(story_context.entity_id, entry, [:foo, :baz])

      # Expected context (previous one + recently added entry)
      expected_context =
        %{
          foo: %{bar: 1, baz: 2},
          tro: %{lo: "lo"}
        }

      assert new_story_context.context == expected_context
    end

    test "refuses to append an entry that is already set" do
      cur_context = %{foo: %{bar: 1}}
      {story_context, _} = StorySetup.Context.context(context: cur_context)

      # We are trying to set `foo.bar = 2`, but it's already set as 1!
      entry = %{foo: %{bar: 2}}

      assert {:error, reason} =
        ContextInternal.save(story_context.entity_id, entry, [:foo, :bar])
      assert reason == :path_exists
    end
  end
end
