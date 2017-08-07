defmodule Helix.Account.Model.AccountSetting do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Setting

  @type t :: %__MODULE__{
    account_id: Account.id,
    settings: Setting.t,
    account: term
  }

  @type changeset_params :: %{
    optional(:settings) => map,
    optional(:account_id) => Account.idtb
  }

  @primary_key false
  schema "account_settings" do
    field :account_id, Account.ID,
      primary_key: true

    embeds_one :settings, Setting,
      on_replace: :update

    belongs_to :account, Account,
      references: :account_id,
      foreign_key: :account_id,
      primary_key: true,
      define_field: false
  end

  @spec changeset(%__MODULE__{}, changeset_params) ::
    Changeset.t
  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, [:account_id])
    |> validate_required([:account_id])
    |> cast_embed(:settings)
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Account.Model.Account
    alias Helix.Account.Model.AccountSetting

    @spec by_account(Queryable.t, Account.idtb) ::
      Queryable.t
    def by_account(query \\ AccountSetting, id),
      do: where(query, [as], as.account_id == ^id)

    @spec select_settings(Queryable.t) ::
      Queryable.t
    def select_settings(query),
      do: select(query, [as], as.settings)
  end
end
