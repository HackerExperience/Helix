defmodule Helix.Cache.Model.ServerCache do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.IPv4
  alias HELL.PK
  alias Helix.Server.Model.Server

  @type cache_nip :: %{
    network_id: PK.t,
    ip: IPv4.t
  }

  @type t :: %__MODULE__{
    server_id: PK.t,
    networks: [cache_nip],
    storages: [PK.t],
    expiration_date: DateTime.t
  }

  @cache_duration 60 * 60 * 24 * 1000

  @creation_fields ~w/
    server_id
    networks
    storages
    /a

  @primary_key false
  schema "server_cache" do
    field :server_id, PK,
      primary_key: true

    field :networks, {:array, :map}
    field :storages, {:array, PK}

    field :expiration_date, :utc_datetime
  end

  def new(sid, networks \\ [], storages \\ []) do
    %{
      server_id: sid,
      networks: format_network(networks),
      storages: storages
    }
    |> create_changeset()
    |> Changeset.apply_changes()
  end

  defp format_network(networks) do
    Enum.map(networks, fn(net) ->
      %{network_id: to_string(net.network_id), ip: net.ip}
    end)
  end

  def create_changeset(params = %__MODULE__{}),
    do: create_changeset(Map.from_struct(params))
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> workaround_to_add_nil_values(params)
    |> add_expiration_date()
  end

  # Fix for https://github.com/elixir-ecto/ecto/issues/2017
  # Basically, Ecto won't add `nil` values on upsert (insert + :replace_all),
  # even when using changeset and `cast/3`. `put_change` won't work either.
  defp workaround_to_add_nil_values(changeset, params) do
    Enum.reduce(@creation_fields, changeset, fn(field, cs) ->
      value = Map.get(params, field)
      if is_nil(value) do
        force_change(cs, field, value)
      else
        cs
      end
    end)
  end

  @spec add_expiration_date(Changeset.t) ::
    Changeset.t
  defp add_expiration_date(changeset) do
    expire_date =
      DateTime.utc_now()
      |> DateTime.to_unix(:millisecond)
      |> Kernel.+(@cache_duration)
      |> DateTime.from_unix!(:millisecond)

    put_change(changeset, :expiration_date, expire_date)
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Server.Model.Server
    alias Helix.Cache.Model.ServerCache

    @spec by_server(Queryable.t, Server.id) ::
      Queryable.t
    def by_server(query \\ ServerCache, server_id),
      do: where(query, [s], s.server_id == ^server_id)

    @spec filter_expired(Queryable.t) ::
      Queryable.t
    def filter_expired(query),
      do: where(query, [s], s.expiration_date >= fragment("now() AT TIME ZONE 'UTC'"))
  end
end
