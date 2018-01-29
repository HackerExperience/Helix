defmodule Helix.Network.Model.Bounce.Entry do

  use Ecto.Schema

  import Ecto.Changeset
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias HELL.IPv4
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Network

  @type t ::
    %__MODULE__{
      bounce_id: Bounce.id,
      server_id: Server.id,
      network_id: Network.id,
      ip: Network.ip
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @creation_fields [:bounce_id, :server_id, :network_id, :ip]
  @required_fields [:bounce_id, :server_id, :network_id, :ip]

  @primary_key false
  schema "bounce_entries" do
    field :bounce_id, Bounce.ID,
      primary_key: true
    field :server_id, Server.ID,
      primary_key: true
    field :network_id, Network.ID,
      primary_key: true

    field :ip, IPv4

    belongs_to :bounce, Bounce,
      foreign_key: :bounce_id,
      references: :bounce_id,
      define_field: false
  end

  @spec create(Bounce.id, Bounce.link) :: changeset
  @spec create(Bounce.id, [Bounce.link]) :: [changeset]
  def create(id, link = {_, _, _}),
    do: create_entry(id, link)
  def create(id, links) when is_list(links),
    do: Enum.map(links, &(create_entry(id, &1)))

  @spec create_entry(Bounce.id, Bounce.link) ::
    changeset
  defp create_entry(id = %Bounce.ID{}, {server_id, network_id, ip}) do
    params =
      %{
        bounce_id: id,
        server_id: server_id,
        network_id: network_id,
        ip: ip
      }

    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
  end

  query do

    alias Helix.Server.Model.Server
    alias Helix.Network.Model.Bounce
    alias Helix.Network.Model.Network

    @spec by_pk(Queryable.t, Bounce.id, Server.id, Network.id) ::
      Queryable.t
    def by_pk(query \\ Bounce.Entry, bounce_id, server_id, network_id) do
      where(
        query,
        [be],
        be.bounce_id == ^bounce_id
        and be.server_id == ^server_id
        and be.network_id == ^network_id
      )
    end

    @spec by_server(Queryable.t, Server.id) ::
      Queryable.t
    def by_server(query \\ Bounce.Entry, server_id),
      do: where(query, [be], be.server_id == ^server_id)

    @spec by_nip(Queryable.t, Network.id, Network.ip) ::
      Queryable.t
    def by_nip(query \\ Bounce.Entry, network_id, ip),
      do: where(query, [be], be.network_id == ^network_id and be.ip == ^ip)
  end
end
