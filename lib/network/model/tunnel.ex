defmodule Helix.Network.Model.Tunnel do

  use Ecto.Schema
  use HELL.ID, field: :tunnel_id, meta: [0x0000, 0x0001]

  import Ecto.Changeset

  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Link
  alias Helix.Network.Model.Network

  @type t :: %__MODULE__{
    tunnel_id: id,
    network_id: Network.id,
    gateway_id: Server.id,
    destination_id: Server.id,
    hash: String.t,
    network: term,
    links: term,
    connections: term
  }

  schema "tunnels" do
    field :tunnel_id, ID,
      primary_key: true

    field :network_id, Network.ID
    field :gateway_id, Server.ID
    field :destination_id, Server.ID

    field :hash, :string

    belongs_to :network, Network,
      foreign_key: :network_id,
      references: :network_id,
      define_field: false

    has_many :links, Link,
      foreign_key: :tunnel_id,
      references: :tunnel_id,
      on_delete: :delete_all

    has_many :connections, Connection,
      foreign_key: :tunnel_id,
      references: :tunnel_id,
      on_delete: :delete_all
  end

  def create(network, gateway, destination, bounces) do
    params = %{
      network_id: network,
      gateway_id: gateway,
      destination_id: destination
    }

    %__MODULE__{}
    |> cast(params, [:gateway_id, :destination_id, :network_id])
    |> validate_required([:gateway_id, :destination_id, :network_id])
    |> bounce([gateway| bounces] ++ [destination])
    |> hash(bounces)
  end

  # TODO: Use something like murmur
  def hash_bounces(bounces),
    do: Enum.join(bounces, "_")

  # TODO: Refactor this ?
  defp bounce(changeset, [gateway| bounces]) do
    set = MapSet.new([gateway])
    result = Enum.reduce_while(bounces, {[], gateway, set, 0}, fn
      to, {acc, from, set, i} ->
        if MapSet.member?(set, to) do
          {:halt, {:error, :repeated}}
        else
          link = Link.create(from, to, i)

          {:cont, {[link| acc], to, MapSet.put(set, to), i + 1}}
        end
    end)

    case result do
      {:error, :repeated} ->
        add_error(changeset, :links, "repeated node")
      {acc, _, _, _} ->
        put_assoc(changeset, :links, acc)
    end
  end

  defp hash(changeset, bounces),
    do: put_change(changeset, :hash, hash_bounces(bounces))

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Server.Model.Server
    alias Helix.Network.Model.Network
    alias Helix.Network.Model.Tunnel

    @spec by_id(Queryable.t, Tunnel.idtb) ::
      Queryable.t
    def by_id(query \\ Tunnel, id),
      do: where(query, [t], t.tunnel_id == ^id)

    @spec by_network(Queryable.t, Network.idtb) ::
      Queryable.t
    def by_network(query \\ Tunnel, id),
      do: where(query, [t], t.network_id == ^id)

    @spec by_gateway(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_gateway(query \\ Tunnel, id),
      do: where(query, [t], t.gateway_id == ^id)

    @spec by_destination(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_destination(query \\ Tunnel, id),
      do: where(query, [t], t.destination_id == ^id)

    @spec select_total_tunnels(Queryable.t) ::
      Queryable.t
    def select_total_tunnels(query),
      do: select(query, [t], count(t.tunnel_id))
  end
end
