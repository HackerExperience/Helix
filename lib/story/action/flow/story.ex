defmodule Helix.Story.Action.Flow.Story do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Action.Flow.Context, as: ContextFlow
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Query.Story, as: StoryQuery
  alias Helix.Story.Model.Step
  alias Helix.Story.Model.Steppable
  alias Helix.Story.Model.Story

  @spec start_story(Entity.t, Story.Manager.t, Event.relay) ::
    {:ok, Story.Step.t}
  @doc """
  Effectively "starts" the storyline for the given `entity`, "proceeding" it to
  the first step.

  Before doing so, however, it creates the Story.Context for that entity, which
  will be used for medium- and long-term storage of storyline data.

  It requires Story.Manager, as it will be used to determine the entity's story
  network/server, which may be used by the first step.
  """
  def start_story(entity, manager, relay) do
    first_step = Step.first(entity.entity_id, manager)

    flowing do
      with \
        {:ok, _} <- ContextFlow.setup(entity),
        {:ok, story_step} <- StoryAction.proceed_step(first_step),
        {:ok, _, events} <- Steppable.start(first_step, nil),
        on_success(fn -> Event.emit(events, from: relay) end)
      do
        {:ok, story_step}
      end
    end
  end

  @spec send_reply(Entity.id, Step.contact, Step.reply_id) ::
    :ok
    | {:error, :bad_step}
    | {:error, {:reply, :not_found}}
    | {:error, :internal}
  @doc """
  Sends `reply_id` from `entity_id` to the `contact_id`.

  Emits: StoryReplySentEvent.t
  """
  def send_reply(entity_id, contact_id, reply_id) do
    flowing do
      with \
        step = %{} <- StoryQuery.fetch_step(entity_id, contact_id) || :badstep,
        {:ok, events} <-
          StoryAction.send_reply(step.object, step.entry, reply_id),
        on_success(fn -> Event.emit(events) end)
      do
        :ok
      else
        :badstep ->
          {:error, :bad_step}

        error ->
          error
      end
    end
  end
end
