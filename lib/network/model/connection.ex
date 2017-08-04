defmodule Helix.Network.Model.Connection do

  use Ecto.Schema
  use HELL.ID, field: :connection_id, meta: [0x0000, 0x0001, 0x0001]

  import Ecto.Changeset

  alias Helix.Network.Model.Tunnel

  @type close_reasons :: :normal | :force
  @type type :: String.t
  @type t :: %__MODULE__{
    connection_id: id,
    tunnel_id: Tunnel.id,
    connection_type: type,
    tunnel: term
  }

  @close_reasons [:normal, :force]

  # TODO: ConnectionType as a constant

  schema "connections" do
    field :connection_id, ID,
      primary_key: true

    field :tunnel_id, Tunnel.ID

    field :connection_type, :string

    belongs_to :tunnel, Tunnel,
      foreign_key: :tunnel_id,
      references: :tunnel_id,
      define_field: :false
  end

  @spec create(Tunnel.idtb, type) ::
    Changeset.t
  def create(tunnel, connection_type) do
    params = %{
      tunnel_id: tunnel,
      connection_type: connection_type
    }

    %__MODULE__{}
    |> cast(params, [:tunnel_id, :connection_type])
    |> validate_required([:connection_type])
  end

  @doc false
  def close_reasons,
    do: @close_reasons

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Server.Model.Server
    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Link
    alias Helix.Network.Model.Tunnel

    @spec by_id(Queryable.t, Connection.idtb) ::
      Queryable.t
    def by_id(query \\ Connection, id),
      do: where(query, [c], c.connection_id == ^id)

    @spec through_node(Queryable.t, Server.idtb) ::
      Queryable.t
    def through_node(query \\ Connection, id) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where(
        [c, ..., l],
        l.source_id == ^id or l.destination_id == ^id)
      |> distinct(true)
    end

    @spec inbound_to(Queryable.t, Server.idtb) ::
      Queryable.t
    def inbound_to(query \\ Connection, id) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where([c, ..., l], l.destination_id == ^id)
    end

    @spec outbound_from(Queryable.t, Server.idtb) ::
      Queryable.t
    def outbound_from(query \\ Connection, id) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where([c, ..., l], l.source_id == ^id)
    end

    @spec from_gateway_to_endpoint(Queryable.t, Server.idtb, Server.idtb) ::
      Queryable.t
    def from_gateway_to_endpoint(query \\ Connection, gateway, destination) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> where([c, ..., t], t.gateway_id == ^gateway)
      |> where([c, ..., t], t.destination_id == ^destination)
    end
  end
end
