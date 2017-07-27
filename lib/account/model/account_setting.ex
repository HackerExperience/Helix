defmodule Helix.Account.Model.AccountSetting do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Setting

  @type t :: %__MODULE__{}

  @type changeset_params :: %{
    :settings => map,
    optional(:account_id) => Account.id,
    optional(any) => any
  }

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

  @spec changeset(t, changeset_params) ::
    Changeset.t
  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [:account_id])
    |> foreign_key_constraint(:account_id)
    |> cast_embed(:settings)
  end

  defmodule Query do

    import Ecto.Query, only: [select: 3, where: 3]

    alias Ecto.Queryable
    alias Helix.Account.Model.Account
    alias Helix.Account.Model.AccountSetting

    @spec from_account(Queryable.t, Account.t | Account.id) ::
      Queryable.t
    def from_account(query \\ AccountSetting, account_or_account_id)
    def from_account(query, account = %Account{}),
      do: from_account(query, account.account_id)
    def from_account(query, account_id),
      do: where(query, [as], as.account_id == ^account_id)

    @spec select_settings(Queryable.t) ::
      Queryable.t
    def select_settings(query),
      do: select(query, [as], as.settings)
  end
end
