defmodule Helix.Story.Action.Flow.Story do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Steppable
  alias Helix.Story.Model.Story

  @spec start_story(Entity.t, Story.Manager.t, Event.relay) ::
    {:ok, Story.Step.t}
  def start_story(entity, manager, relay) do
    first_step = Step.first(entity.entity_id, manager)

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
