defmodule Helix.Network.Internal.Bounce do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias Helix.Network.Repo

  @type create_errors :: :internal
  @type update_errors :: :internal

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

  @spec fetch_from_connection(Connection.idt) ::
    Bounce.t
    | nil
  @doc """
  Given a connection, figure out which bounce it uses.
  """
  def fetch_from_connection(connection) do
    result =
      connection
      |> Bounce.Query.by_connection()
      |> Repo.one()

    with [bounce, sorted] = [%Bounce{}, %Bounce.Sorted{}] <- result do
      bounce
      |> Map.replace!(:sorted, sorted)
      |> Bounce.format()
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

  @spec update(Bounce.t, [links: [Bounce.link], name: Bounce.name]) ::
    {:ok, Bounce.t}
    | {:error, update_errors}
  def update(bounce = %Bounce{}, name: name, links: links),
    do: do_update(bounce, links, name)
  def update(bounce = %Bounce{}, name: name),
    do: do_update(bounce, bounce.links, name)
  def update(bounce = %Bounce{}, links: links),
    do: do_update(bounce, links, bounce.name)

  @spec remove(Bounce.t) ::
    {:ok, Bounce.t}
    | {:error, Bounce.changeset}
  @doc """
  Removes the bounce.

  All underlying components (Bounce.Sorted, Bounce.Entry) will be delete as well
  (through CASCADE).
  """
  def remove(bounce = %Bounce{}),
    do: Repo.delete(bounce)

  @spec do_update(Bounce.t, [Bounce.link], Bounce.name) ::
    {:ok, Bounce.t}
    | {:error, update_errors}
  defp do_update(bounce = %Bounce{links: links, name: name}, links, name),
    do: {:ok, bounce}
  defp do_update(bounce = %Bounce{}, new_links, new_name) do
    Repo.transaction fn ->

      update_link_attempt =
        if bounce.links == new_links do
          {:ok, bounce.sorted}
        else
          added_links = new_links -- bounce.links
          removed_links = bounce.links -- new_links

          # Remove old links
          Enum.each(removed_links, &(remove_entry(bounce, &1)))

          # Returns true if all insert operations returned {:ok, _}
          # Add new links
          insert_valid? =
            added_links
            |> Enum.map(&(add_entry(bounce, &1)))
            |> Enum.all?(fn {status, _} -> status == :ok end)

          with \
            true <- insert_valid?,
            {1, [sorted]} <- update_sorted(bounce, new_links)
          do
            {:ok, sorted}
          else
            _ ->
              {:error, bounce.sorted}
          end
        end

      update_name_attempt =
        if bounce.name == new_name do
          {:ok, bounce}
        else
          with {:ok, bounce} <- rename(bounce, new_name) do
            {:ok, bounce}
          end
        end

      with \
        {:ok, new_sorted} <- update_link_attempt,
        {:ok, new_bounce} <- update_name_attempt
      do
        new_bounce
        |> Map.replace!(:sorted, new_sorted)
        |> Bounce.format()
      else
        _ ->
          Repo.rollback(:internal)
      end
    end
  end

  @spec rename(Bounce.t, Bounce.name) ::
    {:ok, Bounce.t}
    | {:error, Bounce.changeset}
  def rename(bounce = %Bounce{name: name}, name),
    do: {:ok, bounce}
  def rename(bounce = %Bounce{}, name) do
    bounce
    |> Bounce.rename(name)
    |> Repo.update()
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
    {non_neg_integer, [Bounce.Sorted.t]}
    | no_return
  defp update_sorted(bounce = %Bounce{}, links) do
    sorted_nips = Bounce.Sorted.generate_nips_map(links)

    bounce.bounce_id
    |> Bounce.Sorted.Query.by_bounce()
    |> Repo.update_all([set: [sorted_nips: sorted_nips]], [returning: true])
  end
end
