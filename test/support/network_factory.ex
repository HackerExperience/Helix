defmodule Helix.Network.Factory do

  alias HELL.TestHelper.Random
  alias Helix.Network.Model.Network
  alias Helix.Network.Model.Tunnel
  alias Helix.Network.Model.Connection

  alias Helix.Network.Repo

  @type thing :: :network | :tunnel | :connection

  @spec changeset(thing, map | Keyword.t) ::
    Ecto.Changeset.t
  def changeset(thing, params \\ %{}) do
    attrs =
      thing
      |> params_for()
      |> Map.merge(to_map(params))

    fabricate_changeset(thing, attrs)
  end

  @spec changeset_list(pos_integer, thing, map | Keyword.t) ::
    [Ecto.Changeset.t, ...]
  def changeset_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: changeset(thing, params)
  end

  @spec build(thing, map | Keyword.t) ::
    Ecto.Schema.t
  def build(thing, params \\ %{}) do
    thing
    |> changeset(params)
    |> ensure_valid_changeset()
    |> Ecto.Changeset.apply_changes()
  end

  @spec build_list(pos_integer, thing, map | Keyword.t) ::
    [Ecto.Schema.t, ...]
  def build_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: build(thing, params)
  end

  @spec insert(thing, map | Keyword.t) ::
    Ecto.Schema.t
  def insert(thing, params \\ %{}) do
    thing
    |> changeset(params)
    |> Repo.insert!()
  end

  @spec insert_list(pos_integer, thing, map | Keyword.t) ::
    [Ecto.Schema.t, ...]
  def insert_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: insert(thing, params)
  end

  @spec params_for(thing) ::
    map
  defp params_for(:network) do
    %{
      name: Random.username()
    }
  end

  defp params_for(:tunnel) do
    bounces = for _ <- 0..3, do: Random.pk()

    # REVIEW: maybe it's better to use internet as the default network
    %{
      network: changeset(:network),
      gateway_id: Random.pk(),
      destination_id: Random.pk(),
      bounces: bounces
    }
  end

  defp params_for(:connection) do
    # FIXME: update after turning `connection_type` into a constant
    %{
      tunnel: build(:tunnel),
      connection_type: "ssh"
    }
  end

  @spec fabricate_changeset(:network, %{name: String.t}) ::
    Ecto.Changeset.t
  defp fabricate_changeset(:network, params) do
    Network
    |> struct(params)
    |> Ecto.Changeset.cast(%{}, [])
  end

  @spec fabricate_changeset(:tunnel, map) ::
    Ecto.Changeset.t
  defp fabricate_changeset(:tunnel, params) do
    Tunnel.create(
      params.network,
      params.gateway_id,
      params.destination_id,
      params.bounces)
  end

  @spec fabricate_changeset(:connection, map) ::
    Ecto.Changeset.t
  defp fabricate_changeset(:connection, params) do
    Connection.create(params.tunnel, params.connection_type)
  end

  defp to_map(x = %{}),
    do: x
  defp to_map(x) when is_list(x),
    do: :maps.from_list(x)

  defp ensure_valid_changeset(cs = %Ecto.Changeset{valid?: true}),
    do: cs
  defp ensure_valid_changeset(cs),
    do: raise "invalid changeset generated on factory: #{inspect cs}"
end
