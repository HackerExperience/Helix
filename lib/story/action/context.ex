defmodule Helix.Story.Action.Context do

  import HELL.Macros

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Internal.Context, as: ContextInternal
  alias Helix.Story.Model.Story

  @typep key :: Story.Context.key

  @spec create(Entity.idt) ::
    {:ok, Story.Context.t}
    | {:error, Story.Context.changeset}
  @doc """
  Creates the Story.Context entry for Entity. Initial context is empty (%{}).
  """
  def create(entity = %Entity{}),
    do: create(entity.entity_id)
  def create(entity_id = %Entity.ID{}),
    do: ContextInternal.create(entity_id)

  @spec save(Entity.idt, key, key | [key], Story.Context.value) ::
    {:ok, Story.Context.t}
    | {:error, :path_exists}
  @doc """
  Appends a new entry to the entity's context. The given path may be nested.

  Save is an explicit operation and as such the path MUST NOT exist.

  # Example:

  Calling `save(entity, :foo, [:bar, :baz], 10)` will add the entry
  `%{foo: %{bar: %{baz: 10}}}`
  """
  def save(entity = %Entity{}, field, subfield, value),
    do: save(entity.entity_id, field, subfield, value)
  def save(entity_id, field, subfield, value) when not is_list(subfield),
    do: save(entity_id, field, [subfield], value)
  def save(entity_id, field, subfields, value) do
    path = [field] ++ subfields
    entry = mapify_entry(path, value)

    ContextInternal.save(entity_id, entry, path)
  end

  @spec update(Entity.idt, key, key | [key], Story.Context.value) ::
    {:ok, Story.Context.t}
    | {:error, :path_exists}

  @doc """
  Updates an existing entry on the entity's context. Path may be nested.

  Update is an explicit operation and as such the path MUST ALREADY exist.

  # Example:

  Calling `update(entity, :foo, [:bar, :baz], 10)` will update the entry on
  path [:foo, :bar, :baz] to `%{foo: %{bar: %{baz: 10}}}`
  """
  def update(entity = %Entity{}, field, subfield, value),
    do: update(entity.entity_id, field, subfield, value)
  def update(entity_id, field, subfield, value) when not is_list(subfield),
    do: update(entity_id, field, [subfield], value)
  def update(entity_id, field, subfields, value) do
    path = [field] ++ subfields
    entry = mapify_entry(path, value)

    ContextInternal.update(entity_id, entry, path)
  end

  defdelegate delete(context),
    to: ContextInternal

  @spec mapify_entry([atom], term) ::
    map
  docp """
  Maps the given keys (list of atoms) to a nested map with value `value`.

  # Example:

  > mapify_entry([:foo, :bar], 1)
  > %{foo: %{bar: 2}}
  """
  defp mapify_entry(path, value) do
    Enum.reduce(path, {%{}, []}, fn key, {map, iterated} ->
      relative_key = iterated ++ [key]

      if relative_key == path do
        put_in(map, relative_key, value)
      else
        {put_in(map, relative_key, %{}), relative_key}
      end
    end)
  end
end
