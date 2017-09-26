defmodule Helix.Story.Public.Story do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery

  @spec send_reply(Entity.id, Step.reply_id) ::
    :ok
    | {:error, {:entity, :not_in_step}}
    | {:error, {:reply, :not_found}}
    | {:error, :internal}
  def send_reply(entity_id, reply_id) do
    flowing do
      with \
        step = %{} <- StoryQuery.fetch_current_step(entity_id) || :badstep,
        {:ok, events} <-
          StoryAction.send_reply(step.object, step.entry, reply_id),
        on_success(fn -> Event.emit(events) end)
      do
        :ok
      else
        :badstep ->
          {:error, {:entity, :not_in_step}}
        error ->
          error
      end
    end
  end
end
