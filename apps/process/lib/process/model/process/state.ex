defmodule Helix.Process.Model.Process.State do

  @behaviour Ecto.Type

  @type states :: :standby | :paused | :running | :completed

  @mappings %{
    0 => :standby,
    1 => :paused,
    2 => :running,
    3 => :complete
  }

  def type, do: :integer

  for {_, v} <- @mappings do
    def cast(unquote(v)),
      do: {:ok, unquote(v)}
    def cast(unquote(Atom.to_string(v))),
      do: {:ok, unquote(v)}
  end

  def cast(_),
    do: :error

  for {k, v} <- @mappings do
    def load(unquote(k)),
      do: {:ok, unquote(v)}
  end

  for {k, v} <- @mappings do
    def dump(unquote(v)),
      do: {:ok, unquote(k)}
  end

  def dump(_),
    do: :error
end