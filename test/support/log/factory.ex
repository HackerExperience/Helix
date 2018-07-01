defmodule Helix.Test.Log.Factory do

  alias Ecto.Changeset
  alias Helix.Log.Model.Log
  alias Helix.Log.Repo

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  @type thing :: :log

  @spec build(thing, map | Keyword.t) ::
    struct
  def build(thing, params \\ %{}) do
    thing
    |> changeset(params)
    |> ensure_valid_changeset()
    |> Changeset.apply_changes()
  end

  @spec build_list(pos_integer, thing, map | Keyword.t) ::
    [struct, ...]
  def build_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: build(thing, params)
  end

  @spec insert(thing, map | Keyword.t) ::
    struct
  def insert(thing, params \\ %{}) do
    thing
    |> changeset(params)
    |> Repo.insert!()
  end

  @spec insert_list(pos_integer, thing, map | Keyword.t) ::
    [struct, ...]
  def insert_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: insert(thing, params)
  end

  @spec params_for(thing) ::
    map
  defp params_for(:log) do
    %{
      server_id: ServerHelper.id(),
      entity_id: EntityHelper.id,
      message: "TODO: Use a generator for nice messages"
    }
  end
  @spec fabricate_changeset(thing, map) ::
    Changeset.t
  defp fabricate_changeset(:log, params),
    do: Log.create_changeset(params)

  @spec changeset(thing, map | Keyword.t) ::
    Changeset.t
  defp changeset(thing, params) do
    attrs =
      thing
      |> params_for()
      |> Map.merge(to_map(params))

    fabricate_changeset(thing, attrs)
  end

  defp to_map(x = %{}),
    do: x
  defp to_map(x) when is_list(x),
    do: :maps.from_list(x)

  defp ensure_valid_changeset(cs = %Changeset{valid?: true}),
    do: cs
  defp ensure_valid_changeset(cs),
    do: raise "invalid changeset generated on factory: #{inspect cs}"
end
