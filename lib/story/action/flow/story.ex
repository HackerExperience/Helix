defmodule Helix.Story.Action.Flow.Story do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Steppable

  def start_story(entity, relay) do
    first_step = Step.first(entity.entity_id)

    flowing do
      with \
        {:ok, story_step} = StoryAction.proceed_step(first_step),
        {:ok, _, events} <- Steppable.setup(first_step, nil),
        on_success(fn -> Event.emit(events, from: relay) end)
      do
        {:ok, story_step}
      end
    end
  end
end
