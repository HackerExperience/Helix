defmodule Helix.Test.Story.Setup.Context do

  alias Ecto.Changeset
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo, as: StoryRepo

  alias Helix.Test.Entity.Helper, as: EntityHelper

  @doc """
  See docs on `fake_context/1`.
  """
  def context(opts \\ []) do
    {story_context, related} = fake_context(opts)
    inserted = StoryRepo.insert!(story_context)
    {inserted, related}
  end

  @doc """
  Opts:
  - entity_id: Specify entity ID. Defaults to randomly generated (fake) entity
  - context: Specify context value. Defaults to empty (%{})
  """
  def fake_context(opts \\ []) do
    entity_id = Keyword.get(opts, :entity_id, EntityHelper.id())
    context = Keyword.get(opts, :context, %{})

    story_context =
      %Story.Context{
        entity_id: entity_id,
        context: context
      }

    changeset = Changeset.change(story_context)

    related = %{changeset: changeset}

    {story_context, related}
  end
end
