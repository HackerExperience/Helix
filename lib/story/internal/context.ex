defmodule Helix.Story.Internal.Context do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Model.Story
  alias Helix.Story.Repo

  @spec fetch(Entity.id) ::
    Story.Context.t
    | nil
  def fetch(entity_id) do
    result =
      entity_id
      |> Story.Context.Query.by_entity()
      |> Repo.one()

    with %{} <- result do
      Story.Context.format(result)
    end
  end

  @spec fetch_for_update(Entity.id) ::
    Story.Context.t
    | no_return
  @doc """
  Fetches a row with the intent of updating it.

  The row MUST exist, otherwise an exception is raised.
  """
  def fetch_for_update(entity_id) do
    unless Repo.in_transaction?(),
      do: raise "Transaction required in order to acquire lock"

    entity_id
    |> Story.Context.Query.by_entity()
    |> Story.Context.Query.lock_for_update()
    |> Repo.one!()
    |> Story.Context.format()
  end

  @spec create(Entity.id) ::
    {:ok, Story.Context.t}
    | {:error, Story.Context.changeset}
  def create(entity_id) do
    %{entity_id: entity_id}
    |> Story.Context.create()
    |> Repo.insert()
  end

  @spec save(Entity.id, map, Story.Context.path) ::
    {:ok, Story.Context.t}
    | {:error, :path_exists}
    | no_return
  @doc """
  Adds `entry` to the context that belongs to `entity_id`.

  Notice that `save` is supposed to add a value for the first time! As such, an
  error will raise if the requested key is already set. If you want to update an
  existing key, use `update/3` instead.
  """
  def save(entity_id, entry, path) do
    Repo.transaction fn ->
      cur_story_context = fetch_for_update(entity_id)

      with \
        nil <- get_in(cur_story_context.context, path),
        # /\ Make sure the value we are inserting isn't already saved
        # TODO: this verification WILL fail if the value within `path` is nil

        {:ok, new_story_context} = update_entry(cur_story_context, entry)
      do
        new_story_context
      else
        _ ->
          Repo.rollback(:path_exists)
      end
    end
  end

  @spec update(Entity.id, map, Story.Context.path) ::
    {:ok, Story.Context.t}
    | {:error, :path_not_found}
    | no_return
  @doc """
  Adds `entry` within the given `path`.

  Notice that `update` explicitly requires that the given path already exists!
  Bad things happen for those who defy this rule.
  """
  def update(entity_id, entry, path) do
    Repo.transaction fn ->
      cur_story_context = fetch_for_update(entity_id)

      with \
        true <- not is_nil(get_in(cur_story_context.context, path)),
        # /\ Make sure the value we are updating ALREADY exists

        {:ok, new_story_context} = update_entry(cur_story_context, entry)
      do
        new_story_context
      else
        _ ->
          Repo.rollback(:path_not_found)
      end
    end
  end

  @spec delete(Story.Context.t) ::
    :ok
  def delete(context = %Story.Context{}) do
    context
    |> Repo.delete()

    :ok
  end

  defp update_entry(context, entry) do
    context
    |> Story.Context.update(entry)
    |> Repo.update()
  end
end
