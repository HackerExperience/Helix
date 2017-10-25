defmodule Helix.Core.Listener.Internal.Listener do

  alias Helix.Core.Listener.Model.Listener
  alias Helix.Core.Listener.Model.Owner
  alias Helix.Core.Repo

  def listen(object_id, event, callback, meta, owner_id, subscriber) do
    Repo.transaction fn ->
      with \
        {:ok, listener} <- create_listener(object_id, event, callback, meta),
        {:ok, owner} <- create_owner(owner_id, subscriber, listener)
      do
        listener
      else
        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end
  end

  def unlisten(owner_id, object_id, event, subscriber) do
    event = Listener.hash_event(event)

    owner = fetch_owner(owner_id, object_id, event, subscriber)

    # Deletes Listener *and* Owner. No need for transaction (nor asking to
    # delete `owner` directly) because it will react based on the listener_id
    # FK, which is set to DELETE ON CASCADE.
    if owner do
      delete_listener(owner.listener)
    end

    :ok
  end

  def get_listeners(object_id, event) do
    event = Listener.hash_event(event)

    object_id
    |> Listener.Query.by_object_and_event(event)
    |> Listener.Select.callback()
    |> Repo.all()
    |> format_listeners()
  end

  defp fetch_listener(listener_id) do
    listener_id
    |> Listener.Query.by_listener()
    |> Repo.one()
  end

  def fetch_owner(owner_id, object_id, event, subscriber) do
    owner =
      owner_id
      |> Owner.Query.find_listener(object_id, event, subscriber)
      |> Repo.one()

    if owner do
      %{
        owner: owner,
        listener: owner.listener
      }
    end
  end

  defp create_listener(object_id, event, {module, method}, meta) do
    params = %{
      object_id: object_id,
      event: Listener.hash_event(event),
      callback: [module, method],
      meta: meta
    }

    params
    |> Listener.create_changeset()
    |> Repo.insert()
  end

  defp create_owner(owner_id, subscriber, listener = %Listener{}) do
    %{
      listener_id: listener.listener_id,
      owner_id: owner_id,
      object_id: listener.object_id,
      event: listener.event,
      subscriber: subscriber
    }
    |> Owner.create_changeset()
    |> Repo.insert()
  end

  defp delete_listener(listener = %Listener{}) do
    Repo.delete(listener)

    :ok
  end
  defp delete_listener(listeners) when is_list(listeners),
    do: Enum.each(listeners, &delete_listener/1)
  defp delete_listener(listener_id) do
    listener_id
    |> fetch_listener()
    |> delete_listener()
  end

  defp format_listeners([]),
    do: []
  defp format_listeners(listeners) do
    Enum.map(listeners, fn [[module, method], meta] ->
      %{
        module: module,
        method: method,
        meta: meta
      }
    end)
  end
end
