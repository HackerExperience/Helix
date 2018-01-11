defmodule Helix.Story.Query.ContextTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Query.Context, as: ContextQuery

  alias Helix.Test.Story.Setup, as: StorySetup

  describe "get/2" do
    test "returns root field when found" do
      context = %{foo: %{bar: [1, 2, 3]}}
      {story_context, _} = StorySetup.Context.context(context: context)

      # Searching from entity
      assert context.foo == ContextQuery.get(story_context.entity_id, :foo)

      # Searching from Story.Context
      assert context.foo == ContextQuery.get(story_context, :foo)
    end

    test "returns empty (nil) when not found" do
      context = %{foo: %{bar: [1, 2, 3]}}
      {story_context, _} = StorySetup.Context.context(context: context)

      # Searching from entity
      refute ContextQuery.get(Entity.ID.generate(), :wat)
      refute ContextQuery.get(story_context.entity_id, :wat)

      # Searching from Story.Context
      refute ContextQuery.get(story_context, :fool)
    end
  end

  describe "get/3" do
    test "returns arbitrarily nested subfields" do
      context = %{foo: %{bar: %{baz: %{inga: 42}}}}
      {%{entity_id: entity_id}, _} =
        StorySetup.Context.context(context: context)

      assert context.foo.bar == ContextQuery.get(entity_id, :foo, :bar)
      assert context.foo.bar.baz ==
        ContextQuery.get(entity_id, :foo, [:bar, :baz])
      assert 42 == ContextQuery.get(entity_id, :foo, [:bar, :baz, :inga])
    end

    test "returns empty (nil) when not found" do
      context = %{foo: %{bar: %{baz: %{inga: 42}}}}
      {story_context = %{entity_id: entity_id}, _} =
        StorySetup.Context.context(context: context)

      # Searching from entity
      refute ContextQuery.get(entity_id, :foo, :ba)
      refute ContextQuery.get(entity_id, :foo, [:bar, :baz, :uca])

      # Searching from Story.Context
      refute ContextQuery.get(story_context, [:w, :a, :t])
    end
  end
end
