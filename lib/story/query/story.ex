defmodule Helix.Story.Query.Story do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Internal.Email, as: EmailInternal
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.StoryEmail
  alias Helix.Story.Model.StoryStep

  @spec fetch_current_step(Entity.id) ::
    %{
      object: Step.t(struct),
      entry: StoryStep.t
    }
    | nil
  def fetch_current_step(entity_id) do
    with story_step = %{} <- StepInternal.get_current_step(entity_id) do
      %{
        object: Step.fetch(story_step.step_name, entity_id, story_step.meta),
        entry: story_step
      }
    end
  end

  @spec get_emails(Entity.id) ::
    [StoryEmail.t]
  defdelegate get_emails(entity_id),
    to: EmailInternal
end
