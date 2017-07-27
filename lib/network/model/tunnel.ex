defmodule Helix.Network.Model.Tunnel do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.PK
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Link
  alias Helix.Network.Model.Network

  @type id :: PK.t
  @type t :: %__MODULE__{}

  @primary_key false
  @ecto_autogenerate {:tunnel_id, {PK, :pk_for, [:network_tunnel]}}
  schema "tunnels" do
    field :tunnel_id, PK,
      primary_key: true

    field :network_id, PK
    field :gateway_id, PK
    field :destination_id, PK

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
    params = %{gateway_id: gateway, destination_id: destination}

    %__MODULE__{}
    |> cast(params, [:gateway_id, :destination_id])
    |> validate_required([:gateway_id, :destination_id])
    |> put_assoc(:network, network)
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

    import Ecto.Query, only: [select: 3, where: 3]

    alias Ecto.Queryable
    alias Helix.Server.Model.Server
    alias Helix.Network.Model.Network
    alias Helix.Network.Model.Tunnel

    @spec by_tunnel(Queryable.t, Tunnel.t | Tunnel.id) ::
      Queryable.t
    def by_tunnel(query \\ Tunnel, tunnel_or_tunnel_id)
    def by_tunnel(query, tunnel = %Tunnel{}),
      do: by_tunnel(query, tunnel.tunnel_id)
    def by_tunnel(query, tunnel_id),
      do: where(query, [t], t.tunnel_id == ^tunnel_id)

    @spec from_network(Queryable.t, Network.t | Network.id) ::
      Queryable.t
    def from_network(query \\ Tunnel, network_or_network_id)
    def from_network(query, network = %Network{}),
      do: from_network(query, network.network_id)
    def from_network(query, network_id),
      do: where(query, [t], t.network_id == ^network_id)

    @spec by_gateway(Queryable.t, Server.t | Server.id) ::
      Queryable.t
    def by_gateway(query \\ Tunnel, server_or_server_id)
    def by_gateway(query, gateway = %Server{}),
      do: by_gateway(query, gateway.server_id)
    def by_gateway(query, gateway_id),
      do: where(query, [t], t.gateway_id == ^gateway_id)

    @spec by_destination(Queryable.t, Server.t | Server.id) ::
      Queryable.t
    def by_destination(query \\ Tunnel, server_or_server_id)
    def by_destination(query, destination = %Server{}),
      do: by_destination(query, destination.server_id)
    def by_destination(query, destination_id),
      do: where(query, [t], t.destination_id == ^destination_id)

    @spec select_total_tunnels(Queryable.t) ::
      Queryable.t
    def select_total_tunnels(query),
      do: select(query, [t], count(t.tunnel_id))
  end
end
