defmodule Helix.Test.Story.Helper do

  alias Helix.Story.Model.StoryStep
  alias Helix.Story.Repo, as: StoryRepo

  def get_steps_from_entity(entity_id) do
    entity_id
    |> StoryStep.Query.by_entity()
    |> StoryRepo.all()
  end
end
