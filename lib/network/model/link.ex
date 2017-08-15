defmodule Helix.Network.Model.Link do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Tunnel

  @type t :: %__MODULE__{
    tunnel_id: Tunnel.id,
    source_id: Server.id,
    destination_id: Server.id,
    sequence: non_neg_integer
  }

  @primary_key false
  schema "links" do
    field :tunnel_id, Tunnel.ID,
      primary_key: true
    field :source_id, Server.ID,
      primary_key: true

    field :destination_id, Server.ID

    field :sequence, :integer
  end

  @spec create(Server.id, Server.id, non_neg_integer) ::
    Changeset.t
  def create(source, destination, sequence) do
    params = %{
      source_id: source,
      destination_id: destination,
      sequence: sequence
    }

    %__MODULE__{}
    |> cast(params, [:source_id, :destination_id, :sequence])
    |> validate_required([:source_id, :destination_id, :sequence])
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Network.Model.Link
    alias Helix.Network.Model.Tunnel

    @spec by_tunnel(Queryable.t, Tunnel.idtb) ::
      Queryable.t
    def by_tunnel(query \\ Link, tunnel),
      do: where(query, [l], l.tunnel_id == ^tunnel)

    @spec by_tunnel(Queryable.t) ::
      Queryable.t
    def order_by_sequence(query),
      do: order_by(query, [l], l.sequence)
  end
end
