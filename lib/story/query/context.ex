defmodule Helix.Story.Query.Context do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Internal.Context, as: ContextInternal
  alias Helix.Story.Model.Story

  @typep key :: Story.Context.key

  defdelegate fetch(entity_id),
    to: ContextInternal

  @spec get(Entity.idt | Story.Context.t, key) ::
    Story.Context.context
    | nil
  def get(entity = %Entity{}, root),
    do: get(entity.entity_id, root)
  def get(entity_id = %Entity.ID{}, root) do
    with story_context = %{} <- fetch(entity_id) do
      get(story_context, root)
    end
  end
  def get(%Story.Context{context: context}, root),
    do: Map.get(context, root)

  @spec get(Entity.idt | Story.Context.t, key, key | [key]) ::
    Story.Context.context
    | Story.Context.value
    | nil
  def get(entity = %Entity{}, root, fields),
    do: get(entity.entity_id, root, fields)
  def get(entity_id = %Entity.ID{}, root, fields) do
    with story_context = %{} <- fetch(entity_id) do
      get(story_context, root, fields)
    end
  end

  def get(story_context = %Story.Context{}, root, key) when not is_list(key),
    do: get(story_context, root, [key])
  def get(%Story.Context{context: context}, root, keys) do
    path = [root] ++ keys
    get_in(context, path)
  end
end
