defmodule Helix.Account.Model.Setting do

  use Ecto.Schema

  import Ecto.Changeset

  @update_fields ~w/is_beta/a

  @primary_key false
  embedded_schema do
    field :is_beta, :boolean, null: true
  end

  @spec changeset(Setting.t, map) :: Ecto.Changeset.t
  def changeset(struct \\ %__MODULE__{}, params) do
    cast(struct, defaults_to_nil(params), @update_fields)
  end

  @spec default :: Setting.t
  def default do
    %__MODULE__{is_beta: false}
  end

  # TODO: this might not be needed with an specialized type for settings
  defp defaults_to_nil(params) do
    unchanged = Map.from_struct(default())

    nullify =
      fn {k, v} ->
        if v == unchanged[k],
          do: {k, nil},
          else: {k, v}
      end

    params
    |> Enum.map(nullify)
    |> :maps.from_list()
  end
end
