defmodule Helix.Network.Model.Link do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Tunnel

  @type t ::
    %__MODULE__{
      tunnel_id: Tunnel.id,
      source_id: Server.id,
      target_id: Server.id,
      sequence: sequence
    }

  @type sequence :: non_neg_integer

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @creation_fields [:source_id, :target_id, :sequence]
  @required_fields [:source_id, :target_id, :sequence]

  @primary_key false
  schema "links" do
    field :tunnel_id, Tunnel.ID,
      primary_key: true
    field :source_id, Server.ID,
      primary_key: true

    field :target_id, Server.ID

    field :sequence, :integer
  end

  @spec create(Tunnel.t) ::
    [changeset]
  def create(tunnel = %Tunnel{hops: hops}) do
    hops = Enum.map(hops, fn {hop_id, _, _} -> hop_id end)

    links =
      if Enum.empty?(hops) do
        [{tunnel.gateway_id, tunnel.destination_id}]
      else
        [tunnel.gateway_id | hops]
        |> Enum.zip(hops)
        |> Kernel.++([{List.last(hops), tunnel.destination_id}])
      end

    links
    |> Enum.with_index()
    |> Enum.map(fn {{source_id, target_id}, seq} ->
        create_changeset(source_id, target_id, seq, tunnel.tunnel_id)
      end)
  end

  @spec create_changeset(Server.id, Server.id, sequence, Tunnel.id) ::
    changeset
  defp create_changeset(source_id, target_id, sequence, tunnel_id) do
    params = %{
      source_id: source_id,
      target_id: target_id,
      sequence: sequence
    }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
    |> put_change(:tunnel_id, tunnel_id)
  end

  query do

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
