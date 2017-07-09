defmodule Helix.Entity.Internal.HackDatabase do

  # FIXME: As much as possible, the queries described here should be
  # added to HackDatabase.Query for reuse and readability.

  alias Ecto.Multi
  alias Ecto.Queryable
  alias HELL.PK
  alias HELL.IPv4
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.HackDatabase

  import Ecto.Query, only: [select: 2, where: 3, order_by: 2]

  @select_fields ~w/
    network_id
    server_ip
    server_type
    password
    alias
    notes
    inserted_at
    updated_at/a

  @spec get_database(Entity.t) ::
    Queryable.t
  def get_database(entity) do
    HackDatabase
    |> select_for_presentation()
    |> where([h], h.entity_id == ^entity.entity_id)
    |> order_by(asc: :network_id, asc: :inserted_at)
  end

  @spec get_entry(Entity.t, PK.t, IPv4.t) ::
    Queryable.t
  def get_entry(entity, network_id, ip) do
    HackDatabase
    |> where([h], h.entity_id == ^entity.entity_id)
    |> where([h], h.network_id == ^network_id)
    |> where([h], h.server_ip == ^ip)
  end

  @spec get_entry_by_server_id(Entity.t, PK.t) ::
    Queryable.t
  def get_entry_by_server_id(entity, server_id) do
    HackDatabase
    |> where([h], h.entity_id == ^entity.entity_id)
    |> where([h], h.server_id == ^server_id)
  end

  @spec select_for_presentation(Queryable.t) ::
    Queryable.t
  def select_for_presentation(query),
    do: select(query, ^@select_fields)

  @spec create(Entity.t, PK.t, IPv4.t, PK.t, String.t) ::
    Multi.t
  def create(entity, network_id, ip, server_id, server_type) do
    changeset = HackDatabase.create(
      entity.entity_id,
      network_id,
      ip,
      server_id,
      server_type)

    Multi.new()
    |> Multi.insert({:hack_database, :new}, changeset, on_conflict: :nothing)
  end

  @spec update(HackDatabase.t, map) ::
    Multi.t
  def update(entry, params) do
    changeset = HackDatabase.update(entry, params)

    Multi.new()
    |> Multi.update({:hack_database, :updated}, changeset)
  end

  @spec delete_server_from_network(PK.t, PK.t) ::
    Multi.t
  def delete_server_from_network(server_id, network_id) do
    query =
      HackDatabase
      |> where([h], h.server_id == ^server_id)
      |> where([h], h.network_id == ^network_id)

    Multi.new()
    |> Multi.delete_all({:hack_database, :deleted}, query)
  end

  @spec delete_server(PK.t) ::
    Multi.t
  def delete_server(server_id) do
    query = where(HackDatabase, [h], h.server_id == ^server_id)

    Multi.new()
    |> Multi.delete_all({:hack_database, :deleted}, query)
  end
end
