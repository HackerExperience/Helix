defmodule Helix.Network.Model.Bounce.Sorted do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.MapUtils
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Bounce

  @type t ::
    %__MODULE__{
      bounce_id: Bounce.id,
      sorted_nips: [entry]
    }

  @type entry :: %{s_id: Server.id, n_id: Network.id, ip: Network.ip}

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @creation_fields [:bounce_id, :sorted_nips]
  @required_fields [:bounce_id, :sorted_nips]

  @primary_key false
  schema "sorted_bounces" do
    field :bounce_id, Bounce.ID,
      primary_key: true
    field :sorted_nips, {:array, :map}

    belongs_to :bounce, Bounce,
      foreign_key: :bounce_id,
      references: :bounce_id,
      define_field: false
  end

  @spec create(Bounce.id, [Bounce.link]) ::
    changeset
  def create(bounce_id = %Bounce.ID{}, links) do
    params =
      %{
        bounce_id: bounce_id,
        sorted_nips: generate_nips_map(links)
      }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  @spec update_links(t, [Bounce.link]) ::
    changeset
  def update_links(sorted = %Bounce.Sorted{}, links) do
    sorted
    |> change()
    |> put_change(:sorted_nips, generate_nips_map(links))
    |> validate_required(@required_fields)
  end

  @spec get_links(t) ::
    [Bounce.link]
  def get_links(sorted = %Bounce.Sorted{}) do
    sorted.sorted_nips
    |> MapUtils.atomize_keys()
    |> Enum.map(fn %{s_id: server_id, n_id: network_id, ip: ip} ->
      {Server.ID.cast!(server_id), Network.ID.cast!(network_id), ip}
    end)
  end

  @spec generate_nips_map([Bounce.link]) ::
    [entry]
  def generate_nips_map(links) do
    Enum.map(links, fn {server_id, network_id, ip} ->
      %{s_id: server_id, n_id: network_id, ip: ip}
    end)
  end

  query do

    alias Helix.Network.Model.Bounce

    @spec by_bounce(Queryable.t, Bounce.id) ::
      Queryable.t
    def by_bounce(query \\ Bounce.Sorted, bounce_id),
      do: where(query, [bs], bs.bounce_id == ^bounce_id)
  end
end
