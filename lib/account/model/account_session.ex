defmodule Helix.Account.Model.AccountSession do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Account.Model.Account

  @type id :: String.t
  @type token :: String.t
  @type t :: %__MODULE__{
    session_id: id,
    account_id: Account.id,
    account: term,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @primary_key false
  @ecto_autogenerate {:session_id, {Ecto.UUID, :generate, []}}
  schema "account_sessions" do
    field :session_id, Ecto.UUID,
      primary_key: true

    field :account_id, Account.ID

    belongs_to :account, Account,
      references: :account_id,
      foreign_key: :account_id,
      define_field: false

    timestamps()
  end

  @spec create_changeset(Account.idtb) ::
    Changeset.t
  def create_changeset(account) do
    %__MODULE__{}
    |> cast(%{account_id: account}, [:account_id])
    |> validate_required([:account_id])
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Account.Model.Account
    alias Helix.Account.Model.AccountSession

    @spec by_account(Queryable.t, Account.idtb) ::
      Queryable.t
    def by_account(query \\ AccountSession, id),
      do: where(query, [as], as.account_id == ^id)
  end
end
