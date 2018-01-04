defmodule Helix.Story.Action.Flow.Context do

  import HELF.Flow

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Action.Context, as: ContextAction
  alias Helix.Story.Model.Story

  @spec setup(Entity.t) ::
    {:ok, Story.Context.t}
  @doc """
  Creates the Story.Context entry for the given Entity.

  Must be called during the preparation/setup of the Storyline, as steps will
  assume the Story.Context entry already exists.
  """
  def setup(entity) do
    flowing do
      with \
        {:ok, context} <- ContextAction.create(entity),
        on_fail(fn -> ContextAction.delete(context) end)
      do
        {:ok, context}
      end
    end
  end
end
