defmodule Helix.Test.Story.Helper do

  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo, as: StoryRepo

  def remove_existing_step(entity_id) do
    with %{entry: story_step} <- StepInternal.fetch_current_step(entity_id) do
      StoryRepo.delete(story_step)
    end
  end

  def get_steps_from_entity(entity_id) do
    entity_id
    |> Story.Step.Query.by_entity()
    |> StoryRepo.all()
  end

  def get_allowed_reply(entry) do
    entry
    |> Story.Step.get_allowed_replies()
    |> Enum.random()
  end
end
