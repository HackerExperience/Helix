defmodule Helix.Network.Model.Connection do

  use Ecto.Schema
  use HELL.ID, field: :connection_id, meta: [0x0000, 0x0001, 0x0001]

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Constant
  alias Helix.Network.Model.Tunnel

  @typep t_of_type(type) ::
    %__MODULE__{
      connection_id: id,
      tunnel_id: Tunnel.id,
      connection_type: type,
      tunnel: term,
      meta: meta
    }

  @type t :: t_of_type(type)

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type ssh :: t_of_type(:ssh)
  @type ftp :: t_of_type(:ftp)
  @type public_ftp :: t_of_type(:public_ftp)
  @type bank_login :: t_of_type(:bank_login)
  @type wire_transfer :: t_of_type(:wire_transfer)
  @type cracker_bruteforce :: t_of_type(:cracker_bruteforce)

  @type meta :: map | nil
  @type close_reasons :: :normal | :force

  @type type ::
    :ssh
    | :ftp
    | :public_ftp
    | :bank_login
    | :wire_transfer
    | :cracker_bruteforce

  @close_reasons [:normal, :force]

  schema "connections" do
    field :connection_id, ID,
      primary_key: true

    field :tunnel_id, Tunnel.ID

    field :connection_type, Constant

    field :meta, :map

    belongs_to :tunnel, Tunnel,
      foreign_key: :tunnel_id,
      references: :tunnel_id,
      define_field: :false
  end

  @spec create(Tunnel.idtb, type, meta) ::
    Changeset.t
  def create(tunnel, connection_type, meta) do
    params = %{
      tunnel_id: tunnel,
      connection_type: connection_type,
      meta: meta
    }

    %__MODULE__{}
    |> cast(params, [:tunnel_id, :connection_type, :meta])
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
        l.source_id == ^id or l.target_id == ^id)
      |> distinct(true)
    end

    @spec inbound_to(Queryable.t, Server.idtb) ::
      Queryable.t
    def inbound_to(query \\ Connection, id) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where([c, ..., l], l.target_id == ^id)
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
