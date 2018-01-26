defmodule Helix.Network.Model.Tunnel do

  use Ecto.Schema
  use HELL.ID, field: :tunnel_id, meta: [0x0000, 0x0001]

  import Ecto.Changeset
  import HELL.Macros
  import HELL.Ecto.Macros

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Model.Connection
  alias Helix.Network.Model.Network
  alias __MODULE__

  @type t ::
    %__MODULE__{
      tunnel_id: id,
      network_id: Network.id,
      gateway_id: Server.id,
      target_id: Server.id,
      bounce_id: Bounce.id | nil,
      bounce: Bounce.t | nil | struct,
      hops: [Bounce.link],
      network: term,
      connections: term
    }

  @typedoc """
  `Tunnel.bounce[_idt]` represents a valid bounce within the Tunnel model, which
  may not exist, hence the `nil` option. Useful to simplify spec of methods who
  use `Tunnel` directly and are not really concerned about how `Bounce` works.
  """
  @type bounce :: Bounce.t | nil
  @type bounce_id :: Bounce.id | nil
  @type bounce_idt :: Bounce.idt | nil

  @type gateway_endpoints ::
    %{gateway :: Server.id => t}

  @type creation_params ::
    %{
      network_id: Network.id,
      gateway_id: Server.id,
      target_id: Server.id
    }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @creation_fields [:network_id, :gateway_id, :target_id]
  @required_fields [:network_id, :gateway_id, :target_id]

  schema "tunnels" do
    field :tunnel_id, ID,
      primary_key: true

    field :network_id, Network.ID
    field :gateway_id, Server.ID
    field :target_id, Server.ID
    field :bounce_id, Bounce.ID,
      default: nil

    # Default for `hops` is `nil` in order to make sure we explicitly set it to
    # either an empty list (no bounce) or [Bounce.link]. If for any reason the
    # `nil` "leaks", something will blow up. TLDR: nil here avoids silent errors
    field :hops, {:array, :map},
      virtual: true,
      default: nil

    belongs_to :network, Network,
      foreign_key: :network_id,
      references: :network_id,
      define_field: false

    has_many :connections, Connection,
      foreign_key: :tunnel_id,
      references: :tunnel_id,
      on_delete: :delete_all

    has_one :bounce, Bounce,
      foreign_key: :bounce_id,
      references: :bounce_id
  end

  @spec create(creation_params, bounce) ::
    changeset
  def create(params, bounce \\ nil) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> put_bounce_data(bounce)
    |> validate_tunnel()
  end

  @spec put_bounce_data(changeset, bounce) ::
    changeset
  docp """
  Add bounce information to the model. If the received bounce is `nil`, we
  explicitly set `hops` to an empty list. Otherwise, we set all bounce-related  
  fields to their corresponding values
  """
  defp put_bounce_data(changeset, nil),
    do: put_change(changeset, :hops, [])
  defp put_bounce_data(changeset, bounce = %Bounce{}) do
    changeset
    |> put_change(:bounce_id, bounce.bounce_id)
    |> put_change(:hops, bounce.links)
    |> put_assoc(:bounce, bounce)
  end

  @spec format(t) ::
    t
  def format(tunnel = %Tunnel{}) do
    tunnel
    |> Map.replace(:hops, get_hops(tunnel))
    |> Map.replace(:bounce, format_bounce(tunnel))
  end

  @spec format_bounce(t) ::
    Bounce.t
    | nil
  docp """
  Formats all bounce-related data.

  NOTE: If the bounce association is not loaded, format will return the initial
  model format. It's up to the caller to figure out whether the association has
  been loaded or not.
  """
  defp format_bounce(%Tunnel{bounce_id: nil}),
    do: nil
  defp format_bounce(%Tunnel{bounce: %Ecto.Association.NotLoaded{}}),
    do: nil
  defp format_bounce(tunnel = %Tunnel{}),
    do: %{tunnel.bounce | sorted: nil}

  @spec get_hops(t) ::
    [Bounce.link]
    | nil
  @doc """
  NOTE: If the association is not loaded, `get_hops/1` will return the initial
  format, which is pretty much invalid. It's up to the caller to make sure the
  Bounce association has been loaded. Use `TunnelInternal.load_bounce/1`.
  """
  def get_hops(%Tunnel{bounce_id: nil}),
    do: []
  def get_hops(%Tunnel{bounce: bounce = %Bounce{}}),
    do: bounce.links
  def get_hops(%Tunnel{bounce: %Ecto.Association.NotLoaded{}}),
    do: nil

  @spec validate_tunnel(changeset) ::
    changeset
  defp validate_tunnel(changeset) do
    changeset
    |> validate_required(@required_fields)
    |> ensure_valid_target()
    |> ensure_acyclic_graph()
  end

  @spec ensure_valid_target(changeset) ::
    changeset
  defp ensure_valid_target(changeset) do
    gateway_id = get_field(changeset, :gateway_id)
    target_id = get_field(changeset, :target_id)

    if gateway_id == target_id do
      add_error(changeset, :target_id, "same_target")
    else
      changeset
    end
  end

  @spec ensure_acyclic_graph(changeset) ::
    changeset
  docp """
  We assume the Bounce assoc is valid (it's the Bounce responsibility to ensure
  its consistency), but we may still have cyclic references if either the target
  or the gateway are part of the bounce.
  """
  defp ensure_acyclic_graph(changeset) do
    hops = get_field(changeset, :hops)
    gateway_id = get_field(changeset, :gateway_id)
    target_id = get_field(changeset, :target_id)

    Enum.reduce_while(hops, changeset, fn {hop_id, _, _}, acc ->
      cond do
        hop_id == gateway_id ->
          {:halt, add_error(changeset, :hops, "cyclic_gateway")}

        hop_id == target_id ->
          {:halt, add_error(changeset, :hops, "cyclic_target")}

        true ->
          {:cont, acc}
      end
    end)
  end

  query do

    alias Helix.Server.Model.Server
    alias Helix.Network.Model.Bounce
    alias Helix.Network.Model.Network

    @spec by_tunnel(Queryable.t, Tunnel.idtb) ::
      Queryable.t
    def by_tunnel(query \\ Tunnel, tunnel_id),
      do: where(query, [t], t.tunnel_id == ^tunnel_id)

    @spec by_network(Queryable.t, Network.idtb) ::
      Queryable.t
    def by_network(query \\ Tunnel, id),
      do: where(query, [t], t.network_id == ^id)

    @spec by_gateway(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_gateway(query \\ Tunnel, id),
      do: where(query, [t], t.gateway_id == ^id)

    @spec by_target(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_target(query \\ Tunnel, id),
      do: where(query, [t], t.target_id == ^id)

    @spec by_bounce(Queryable.t, Bounce.id) ::
      Queryable.t
    def by_bounce(query \\ Tunnel, bounce_id),
      do: where(query, [t], t.bounce_id == ^bounce_id)

    @spec select_total_tunnels(Queryable.t) ::
      Queryable.t
    def select_total_tunnels(query),
      do: select(query, [t], count(t.tunnel_id))

    @spec select_connection(Queryable.t) ::
      Queryable.t
    def select_connection(query) do
      from tunnel in query,
        left_join: connections in assoc(tunnel, :connections),
        select: connections
    end

    @spec get_remote_endpoints([Server.idtb]) ::
      Queryable.t
    @doc """
    Fetches all remote servers that the given server(s) are connected to. It
    includes only tunnels with connections of type `ssh`.

    Used exclusively for account bootstrap.
    """
    def get_remote_endpoints(servers) do
      from tunnel in Tunnel,
        inner_join: connection in assoc(tunnel, :connections),
        where: tunnel.gateway_id in ^servers,
        where: connection.connection_type == ^:ssh
    end
  end
end
