defmodule Helix.Process.Model.Process.Limitations do

  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{
    cpu: non_neg_integer | nil,
    ram: non_neg_integer | nil,
    dlk: non_neg_integer | nil,
    ulk: non_neg_integer | nil
  }

  embedded_schema do
    field :cpu, :integer
    field :ram, :integer
    field :dlk, :integer
    field :ulk, :integer
  end

  def changeset(limitations, params) do
    limitations
    |> cast(params, ~w/cpu dlk ulk/a)
    |> validate_number(:cpu, greater_than_or_equal_to: 0)
    |> validate_number(:ram, greater_than_or_equal_to: 0)
    |> validate_number(:dlk, greater_than_or_equal_to: 0)
    |> validate_number(:ulk, greater_than_or_equal_to: 0)
  end

  defp validate_value(_, nil),
    do: []
  defp validate_value(_, val) when val >= 0,
    do: []
  defp validate_value(field, _),
    do: [{field, "invalid value"}]
end