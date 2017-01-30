defmodule Helix.Account.Model.Setting do

  use Ecto.Schema

  import Ecto.Changeset

  @type id :: String.t
  @type t :: %__MODULE__{
    setting_id: String.t,
    default_value: String.t
  }

  @type creation_params :: %{setting_id: String.t, default_value: String.t}

  @creation_fields ~w/setting_id default_value/a

  @primary_key false
  schema "settings" do
    field :setting_id, :string, primary_key: true
    field :default_value, :string
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
    |> validate_change(:setting_id, &validate_setting_id/2)
  end

  @spec validate_setting_id(:setting_id, String.t) ::
    [] | [setting_id: String.t]
  def validate_setting_id(:setting_id, value) do
    is_binary(value)
    && Regex.match?(~r/^[a-z0-9-_.]{2,32}$/, value)
    && []
    || [setting_id: "invalid value"]
  end

  defmodule Query do

    alias Helix.Account.Model.Setting

    import Ecto.Query, only: [where: 3, select: 3]

    @spec by_id(Setting.id) :: Ecto.Queryable.t
    @spec by_id(Ecto.Queryable.t, Setting.id) :: Ecto.Queryable.t
    def by_id(query \\ Setting, setting_id),
      do: where(query, [s], s.setting_id == ^setting_id)

    @spec select_setting_id_and_default_value() :: Ecto.Queryable.t
    @spec select_setting_id_and_default_value(Ecto.Queryable.t) ::
      Ecto.Queryable.t
    def select_setting_id_and_default_value(query \\ Setting),
      do: select(query, [s], {s.setting_id, s.default_value})
  end
end