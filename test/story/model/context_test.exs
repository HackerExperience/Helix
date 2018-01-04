defmodule Helix.Story.Model.Story.ContextTest do

  use ExUnit.Case, async: true

  alias Helix.Server.Model.Server
  alias Helix.Story.Model.Story

  alias Helix.Test.Story.Setup, as: StorySetup

  describe "format/1" do
    test "handles Helix IDs" do
      server_id = Server.ID.generate()

      context = %{foo: %{server_id: Story.Context.store_id(server_id)}}
      {fake_story_context, _} = StorySetup.Context.context(context: context)

      assert is_binary(fake_story_context.context.foo.server_id.__id__)
      assert is_binary(fake_story_context.context.foo.server_id.__root__)

      story_context = Story.Context.format(fake_story_context)

      # Xupa
      assert story_context.context.foo.server_id == server_id
    end
  end
end
