defmodule Helix.Network.Internal.Bounce do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  @type create_errors :: :internal

  @spec fetch(Bounce.id) ::
    Bounce.t
    | nil
  def fetch(bounce_id = %Bounce.ID{}) do
    result =
      bounce_id
      |> Bounce.Query.by_bounce()
      |> Bounce.Query.join_sorted()
      |> Repo.one()

    with bounce = %Bounce{} <- result do
      Bounce.format(bounce)
    end
  end

  @spec get_entries_on_server(Server.id) ::
    [Bounce.t]
  def get_entries_on_server(server_id = %Server.ID{}) do
    server_id
    |> Bounce.Entry.Query.by_server()
    |> Repo.all()
  end

  @spec get_entries_on_nip(Network.id, Network.ip) ::
    [Bounce.t]
  def get_entries_on_nip(network_id = %Network.ID{}, ip) do
    network_id
    |> Bounce.Entry.Query.by_nip(ip)
    |> Repo.all()
  end

  @spec get_by_entity(Entity.id) ::
    [Bounce.t]
  def get_by_entity(entity_id = %Entity.ID{}) do
    entity_id
    |> Bounce.Query.by_entity()
    |> Bounce.Query.join_sorted()
    |> Repo.all()
    |> Enum.map(&Bounce.format/1)
  end

  @spec create(Entity.id, Bounce.name, [Bounce.link]) ::
    {:ok, Bounce.t}
    | {:error, create_errors}
  def create(entity_id, name, links) do
    Repo.transaction fn ->
      result =
        entity_id
        |> Bounce.create(name, links)
        |> Enum.map(&Repo.insert/1)

      case Enum.find(result, fn {status, _} -> status == :error end) do
        # All inserts returned :ok
        nil ->
          [{:ok, bounce} |  _] = result

          Bounce.format(bounce)

        # One of the inserts have failed
        {:error, _changeset} ->
          Repo.rollback(:internal)
      end
    end
  end

  @spec update(Bounce.t, [Bounce.link]) ::
    {:ok, Bounce.t}
    | {:error, :internal}
  def update(bounce = %Bounce{links: links}, links),
    do: {:ok, bounce}
  def update(bounce = %Bounce{}, links) do
    added_links = links -- bounce.links
    removed_links = bounce.links -- links

    Repo.transaction fn ->
      # Add new links
      add_operations = Enum.map(added_links, &(add_entry(bounce, &1)))

      # Remove old links
      Enum.each(removed_links, &(remove_entry(bounce, &1)))

      with \
        true <- Enum.all?(add_operations, fn {status, _} -> status == :ok end),
        {:ok, _} <- update_sorted(bounce, links)
      do
        fetch(bounce.bounce_id)
      else
        _ ->
          Repo.rollback(:internal)
      end
    end
  end

  @spec add_entry(Bounce.t, Bounce.link) ::
    {:ok, Bounce.Entry.t}
    | {:error, Bounce.Entry.changeset}
  defp add_entry(bounce = %Bounce{}, link) do
    bounce
    |> Bounce.add_entry(link)
    |> Repo.insert()
  end

  @spec remove_entry(Bounce.t, Bounce.link) ::
    :ok
  defp remove_entry(bounce = %Bounce{}, {server_id, network_id, _}) do
    bounce.bounce_id
    |> Bounce.Entry.Query.by_pk(server_id, network_id)
    |> Repo.delete_all()

    :ok
  end

  @spec update_sorted(Bounce.t, [Bounce.link]) ::
    {:ok, Bounce.Sorted.t}
    | {:error, Bounce.Sorted.changeset}
  defp update_sorted(bounce = %Bounce{}, links) do
    bounce.sorted
    |> Bounce.Sorted.update_links(links)
    |> Repo.update()
  end
end
