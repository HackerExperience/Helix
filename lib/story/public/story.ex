defmodule Helix.Story.Public.Story do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Model.Entity
  alias Helix.Story.Action.Story, as: StoryAction
  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Story, as: StoryQuery

  @spec send_reply(Entity.id, Step.reply_id) ::
    :ok
    | {:error, %{message: String.t}}
    | {:error, :internal}
  @doc """
  Sends a reply from the player to a contact.
  """
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
          {:error, %{message: "not_in_step"}}
        {:error, reason} ->
          case reason do
            {:reply, :not_found} ->
              {:error, %{message: "reply_not_found"}}
            :internal ->
              {:error, %{message: "internal"}}
          end
      end
    end
  end
end
