defmodule Helix.Test.Story.Helper do

  alias Helix.Event
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Action.Flow.Story, as: StoryFlow
  alias Helix.Story.Internal.Step, as: StepInternal
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Steppable
  alias Helix.Story.Model.Story
  alias Helix.Story.Query.Story, as: StoryQuery
  alias Helix.Story.Repo, as: StoryRepo

  def remove_existing_steps(entity_id) do
    entity_id
    |> StepInternal.get_steps()
    |> Enum.each(&(StoryRepo.delete(&1.entry)))
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

  @doc """
  Generates random contact id
  """
  def contact_id do
    # Guaranteed to be random
    :friend
  end

  @doc """
  Generates random reply id
  """
  def reply_id do
    # Guaranteed to be random
    "reply_id"
  end

  @doc """
  Automagically replies to a step.

  It randomly selects the `reply_id` from the `allowed_replies` on the given
  `story_step`. Prone to error in some cases so beware.
  """
  def reply(story_step) do
    # Ensure an up-to-date struct
    %{entry: story_step} =
      StoryQuery.fetch_step(story_step.entity_id, story_step.contact_id)

    reply_id = get_allowed_reply(story_step)

    StoryFlow.send_reply(story_step.entity_id, story_step.contact_id, reply_id)
  end

  @doc """
  Automagically proceeds to the next step. It detects the next step after `step`
  and will proceed to that. IT WILL NOT PROCEED TO `step`, BUT TO THE NEXT ONE!
  """
  def proceed_step(step) do
    next_step =
      step
      |> Steppable.next_step()
      |> Step.fetch(step.entity_id, %{}, step.manager)

    remove_existing_steps(step.entity_id)

    start_step(next_step)
  end

  @doc """
  Helper to simulate a step being started. It's very similar to `update_next/2`
  on StoryHandler.
  """
  def start_step(step) do
    with \
      {:ok, _} <- StoryAction.proceed_step(step),

      {:ok, next_step, events} <- Steppable.start(step),
      Event.emit(events),

      # Update step meta
      {:ok, _} <- StoryAction.update_step_meta(next_step)
    do
      {:ok, next_step}
    end
  end
end
