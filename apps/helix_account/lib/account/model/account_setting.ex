defmodule Helix.Account.Model.AccountSetting do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Setting

  import Ecto.Changeset

  @primary_key false
  schema "account_settings" do
    field :account_id, PK,
      primary_key: true

    embeds_one :settings, Setting,
      on_replace: :update

    belongs_to :account, Account,
      references: :account_id,
      foreign_key: :account_id,
      primary_key: true,
      define_field: false
  end

  @spec create_changeset(%{account_id: Account.id, settings: map}) ::
    Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:account_id])
    |> foreign_key_constraint(:account_id)
    |> cast_embed(:settings)
  end

  defmodule Query do

    alias Helix.Account.Model.Account
    alias Helix.Account.Model.AccountSetting

    import Ecto.Query, only: [where: 3]

    @spec from_account(Ecto.Queryable.t, Account.t | Account.id) ::
      Ecto.Queryable.t
    def from_account(query \\ AccountSetting, account_or_account_id)
    def from_account(query, account = %Account{}),
      do: from_account(query, account.account_id)
    def from_account(query, account_id),
      do: where(query, [as], as.account_id == ^account_id)
  end
end
