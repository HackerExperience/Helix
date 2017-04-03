defmodule Helix.Network.Model.Tunnel do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Network.Model.Link
  alias Helix.Network.Model.Network

  import Ecto.Changeset

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

  defp hash(changeset, bounces) do
    hash = Enum.join(bounces, "_")

    put_change(changeset, :hash, hash)
  end
end
