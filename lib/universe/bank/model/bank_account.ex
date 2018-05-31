defmodule Helix.Universe.Bank.Model.BankAccount do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.Password
  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.NPC.Model.NPC

  @account_range 100_000..999_999

  @type account :: 100_000..999_999

  @type t :: %__MODULE__{
    account_number: account,
    bank_id: NPC.id,
    atm_id: ATM.id,
    password: password,
    balance: balance,
    owner_id: Account.id
  }

  @type balance :: non_neg_integer
  @type amount :: pos_integer
  @type password :: String.t

  @type creation_params :: %{
    bank_id: NPC.idtb,
    atm_id: ATM.idtb,
    owner_id: Account.idtb
  }

  @creation_fields ~w/bank_id atm_id owner_id/a

  @primary_key false
  schema "bank_accounts" do
    field :atm_id, Server.ID,
      primary_key: true
    field :account_number, :integer,
      primary_key: true
    field :bank_id, NPC.ID
    field :password, :string
    field :balance, :integer
    field :owner_id, Account.ID
    field :creation_date, :utc_datetime
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
    |> put_defaults()
    |> add_current_time()
  end

  @spec deposit(t, pos_integer) ::
    Changeset.t
  def deposit(account, amount) when amount > 0 do
    changeset = change(account)

    if amount <= 0 do
      add_error(changeset, :balance, "invalid operation")
    else
      put_change(changeset, :balance, account.balance + amount)
    end
  end

  @spec withdraw(t, pos_integer) ::
    Changeset.t
  def withdraw(account, amount) when amount > 0 do
    changeset = change(account)

    cond do
      amount <= 0 ->
        add_error(changeset, :balance, "invalid operation")
      amount > account.balance ->
        add_error(changeset, :balance, "insufficient funds")
      :else ->
        put_change(changeset, :balance, account.balance - amount)
    end
  end

  @spec change_password(t) ::
    Changeset.t
  def change_password(account) do
    change(account)
    |> put_change(:password, generate_account_password())
  end

  @spec cast(term) ::
    {:ok, account}
    | :error
  @doc """
  Ensures that the given account number is valid.

  Similar to HELL's PK.cast()
  """
  def cast(acc) when is_integer(acc) and acc >= 100_000 and acc <= 999_999,
    do: {:ok, acc}
  def cast(_),
    do: :error

  @spec generic_validations(Changeset.t) ::
    Changeset.t
  defp generic_validations(changeset) do
    changeset
    |> validate_required(@creation_fields)
  end

  @spec put_defaults(Changeset.t) ::
    Changeset.t
  defp put_defaults(changeset) do
    defaults = %{
      balance: 0,
      account_number: generate_account_id(),
      password: generate_account_password()
    }

    change(changeset, defaults)
  end

  @spec add_current_time(Changeset.t) ::
    Changeset.t
  defp add_current_time(changeset) do
    put_change(changeset, :creation_date, DateTime.utc_now())
  end

  @spec generate_account_id ::
    account
  defp generate_account_id,
    do: Enum.random(@account_range)

  @spec generate_account_password ::
    BankAccount.password
  defp generate_account_password,
    do: Password.generate(:bank_account)

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Account.Model.Account
    alias Helix.Universe.Bank.Model.BankAccount

    @spec by_atm_account(Queryable.t, ATM.idtb, BankAccount.account) ::
      Queryable.t
    def by_atm_account(query \\ BankAccount, atm, account),
      do: where(query, [b], b.atm_id == ^atm and b.account_number == ^account)

    @spec by_owner(Queryable.t, Account.id) ::
      Queryable.t
    def by_owner(query \\ BankAccount, owner),
      do: where(query, [b], b.owner_id == ^owner)

    @spec order_by_creation_date(Queryable.t) ::
      Queryable.t
    def order_by_creation_date(query),
      do: order_by(query, [b], asc: b.creation_date)

    @spec select_balance(Queryable.t) ::
      Queryable.t
    def select_balance(query),
      do: select(query, [b], b.balance)

    @spec select_sum_balance(Queryable.t) ::
      Queryable.t
    def select_sum_balance(query),
      do: select(query, [b], sum(b.balance))

    @spec lock_for_update(Queryable.t) ::
      Queryable.t
    def lock_for_update(query),
      do: lock(query, "FOR UPDATE")
  end
end
