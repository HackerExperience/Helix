defmodule Helix.Network.Model.Connection do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.PK
  alias Helix.Network.Model.Tunnel

  @type close_reasons :: :normal | :force
  @type id :: PK.t
  @type t :: %__MODULE__{}
  @type type :: String.t

  @close_reasons [:normal, :force]

  # TODO: ConnectionType as a constant

  @primary_key false
  @ecto_autogenerate {:connection_id, {PK, :pk_for, [:network_connection]}}
  schema "connections" do
    field :connection_id, PK,
      primary_key: true
    field :tunnel_id, PK

    field :connection_type, :string

    belongs_to :tunnel, Tunnel,
      foreign_key: :tunnel_id,
      references: :tunnel_id,
      define_field: :false
  end

  def create(tunnel = %Tunnel{}, connection_type) do
    %__MODULE__{}
    |> cast(%{connection_type: connection_type}, [:connection_type])
    |> put_assoc(:tunnel, tunnel)
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

    @spec by_connection(Queryable.t, Connection.t | Connection.id) ::
      Queryable.t
    def by_connection(query \\ Connection, connection_or_connection_id)
    def by_connection(query, connection = %Connection{}),
      do: by_connection(query, connection.connection_id)
    def by_connection(query, connection_id),
      do: where(query, [c], c.connection_id == ^connection_id)

    @spec through_node(Ecto.Queryable.t, Server.t | Server.id) ::
      Queryable.t
    def through_node(query \\ Connection, server_or_server_id)
    def through_node(query, server = %Server{}),
      do: through_node(query, server.server_id)
    def through_node(query, server_id) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where(
        [c, ..., l],
        l.source_id == ^server_id or l.destination_id == ^server_id)
      |> distinct(true)
    end

    @spec inbound_to(Ecto.Queryable.t, Server.t | Server.id) ::
      Queryable.t
    def inbound_to(query \\ Connection, server_or_server_id)
    def inbound_to(query, server = %Server{}),
      do: inbound_to(query, server.server_id)
    def inbound_to(query, server_id) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where([c, ..., l], l.destination_id == ^server_id)
    end

    @spec outbound_from(Ecto.Queryable.t, Server.t | Server.id) ::
      Queryable.t
    def outbound_from(query \\ Connection, server_or_server_id)
    def outbound_from(query, server = %Server{}),
      do: outbound_from(query, server.server_id)
    def outbound_from(query, server_id) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where([c, ..., l], l.source_id == ^server_id)
    end

    @spec from_gateway_to_endpoint(
      Ecto.Queryable.t, Server.t | Server.id, Server.t | Server.id) ::
      Queryable.t
    def from_gateway_to_endpoint(query \\ Connection, s_or_id, s_or_id)
    def from_gateway_to_endpoint(query, gateway = %Server{}, destination_id),
      do: from_gateway_to_endpoint(query, gateway.server_id, destination_id)
    def from_gateway_to_endpoint(query, gateway_id, destination = %Server{}),
      do: from_gateway_to_endpoint(query, gateway_id, destination.server_id)
    def from_gateway_to_endpoint(query, gateway_id, destination_id) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> where([c, ..., t], t.gateway_id == ^gateway_id)
      |> where([c, ..., t], t.destination_id == ^destination_id)
    end
  end
end
