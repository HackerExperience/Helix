defmodule Helix.Process.Model.Process.NaiveStruct do
  @moduledoc false

  import HELL.MacroHelpers

  docp """
  This module is a converter that transforms any struct into a non-struct map
  (while keeping the metadata of which struct that map was) and transforms that
  map back into it's original struct on runtime.

  This is done because Poison will strip that metadata when storing the map
  because it expects that we know at compile time that struct should be
  """

  @behaviour Ecto.Type

  def type, do: :map

  def cast(struct = %{__struct__: _}),
    do: {:ok, struct}
  def cast(_),
    do: :error

  def dump(struct = %{__struct__: module}) do
    not_a_struct =
      struct
      |> Map.from_struct()
      |> Map.put(:"__module_name__", module)

    {:ok, not_a_struct}
  end

  def dump(_),
    do: :error

  def load(not_a_struct = %{"__module_name__" => m}) do
    module = String.to_existing_atom(m)

    {:ok, struct(module, not_a_struct)}
  end

  def load(_),
    do: :error
end
