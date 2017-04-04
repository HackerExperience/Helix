defmodule Helix.Network.Model.Connection do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Network.Model.Tunnel

  import Ecto.Changeset

  @type close_reasons :: :normal | :force
  @type t :: %__MODULE__{}

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
  def close_reasons do
    @close_reasons
  end

  defmodule Query do

    alias Helix.Network.Model.Connection
    alias Helix.Network.Model.Link
    alias Helix.Network.Model.Tunnel

    import Ecto.Query

    def through_node(query \\ Connection, server) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where(
        [c, ..., l],
        l.source_id == ^server or l.destination_id == ^server)
      |> distinct(true)
    end

    def inbound_to(query \\ Connection, server) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where([c, ..., l], l.destination_id == ^server)
    end

    def outbound_from(query \\ Connection, server) do
      query
      |> join(:inner, [c], t in Tunnel, c.tunnel_id == t.tunnel_id)
      |> join(:inner, [c, ..., t], l in Link, t.tunnel_id == l.tunnel_id)
      |> where([c, ..., l], l.source_id == ^server)
    end
  end
end
