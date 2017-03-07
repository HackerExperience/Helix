defmodule Helix.Account.Model.AccountSetting do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Setting

  import Ecto.Changeset

  @type t :: %__MODULE__{
    account_id: Account.id,
    setting_id: Setting.id,
    setting_value: String.t
  }

  @type creation_params :: %{
    account_id: Account.id,
    setting_id: Setting.id,
    setting_value: String.t
  }

  @creation_fields ~w/account_id setting_id setting_value/a

  @primary_key false
  schema "account_settings" do
    belongs_to :account, Account,
      foreign_key: :account_id,
      references: :account_id,
      type: PK,
      primary_key: true

    belongs_to :setting, Setting,
      foreign_key: :setting_id,
      references: :setting_id,
      type: :string,
      primary_key: true

    field :setting_value, :string
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:account_id, :setting_id, :setting_value])
    |> foreign_key_constraint(:setting_id)
  end

  defmodule Query do

    alias Helix.Account.Model.Account
    alias Helix.Account.Model.AccountSetting
    alias Helix.Account.Model.Setting

    import Ecto.Query, only: [where: 3, select: 3]

    @spec from_account(Ecto.Queryable.t, Account.t | Account.id) ::
      Ecto.Queryable.t
    def from_account(query \\ AccountSetting, account_or_account_id)
    def from_account(query, account = %Account{}),
      do: from_account(query, account.account_id)
    def from_account(query, account_id),
      do: where(query, [as], as.account_id == ^account_id)

    @spec from_setting(Ecto.Queryable.t, Setting.t | Setting.id) ::
      Ecto.Queryable.t
    def from_setting(query \\ AccountSetting, setting_or_setting_id)
    def from_setting(query, setting = %Setting{}),
      do: from_setting(query, setting.setting_id)
    def from_setting(query, setting_id),
      do: where(query, [as], as.setting_id == ^setting_id)

    @spec select_setting_id_and_setting_value() :: Ecto.Queryable.t
    @spec select_setting_id_and_setting_value(Ecto.Queryable.t) ::
      Ecto.Queryable.t
    def select_setting_id_and_setting_value(query \\ AccountSetting),
      do: select(query, [as], {as.setting_id, as.setting_value})
  end
end