defmodule Helix.Universe.Bank.Model.BankAccount do

  use Ecto.Schema

  alias Ecto.Changeset
  alias HELL.Password
  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.Bank
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.NPC.Model.NPC

  import Ecto.Changeset

  @type account :: integer

  @type t :: %__MODULE__{
    account_number: integer,
    bank_id: NPC.id,
    atm_id: ATM.id,
    password: String.t,
    balance: integer,
    owner_id: Account.id
  }

  @type creation_params :: %{
    bank_id: NPC.idtb,
    atm_id: ATM.id,
    owner_id: Account.idtb
  }

  @creation_fields ~w/bank_id atm_id owner_id/a

  @initial_balance 0

  @primary_key false
  schema "bank_accounts" do
    field :account_number, :integer,
      primary_key: true
    field :bank_id, NPC.ID
    field :atm_id, Server.ID
    field :password, :string
    field :balance, :integer
    field :owner_id, Account.ID
    field :creation_date, :utc_datetime

    belongs_to :banks, Bank,
      references: :npc_id,
      foreign_key: :bank_id,
      primary_key: false,
      define_field: false
    belongs_to :atms, ATM,
      references: :npc_id,
      foreign_key: :atm_id,
      primary_key: false,
      define_field: false
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
    |> add_initial_balance()
    |> add_account_id()
    |> add_account_password()
    |> add_current_time()
  end

  @spec deposit(t, pos_integer) ::
    Changeset.t
  def deposit(account, amount) when amount > 0 do
    change(account)
    |> put_change(:balance, balance_operation(:add, account.balance, amount))
  end

  @spec withdraw(t, pos_integer) ::
    Changeset.t
  def withdraw(account, amount) when amount > 0 do
    change(account)
    |> put_change(:balance, balance_operation(:sub, account.balance, amount))
  end

  @spec change_password(t) ::
    Changeset.t
  def change_password(account) do
    change(account)
    |> add_account_password()
  end

  @spec balance_operation(:add | :sub, non_neg_integer, pos_integer) ::
    non_neg_integer
  def balance_operation(:add, current, amount),
    do: current + amount
  def balance_operation(:sub, current, amount) do
    if amount > current do
      raise "Invalid balance operation"
    end
    current - amount
  end

  @spec generic_validations(Changeset.t) ::
    Changeset.t
  defp generic_validations(changeset) do
    changeset
    |> validate_required(@creation_fields)
  end

  @spec add_initial_balance(Changeset.t) ::
    Changeset.t
  defp add_initial_balance(changeset) do
    changeset
    |> put_change(:balance, @initial_balance)
  end

  @spec add_account_id(Changeset.t) ::
    Changeset.t
  defp add_account_id(changeset) do
    changeset
    |> put_change(:account_number, generate_account_id())
  end

  @spec add_account_password(Changeset.t) ::
    Changeset.t
  defp add_account_password(changeset) do
    changeset
    |> put_change(:password, generate_account_password())
  end

  @spec add_current_time(Changeset.t) ::
    Changeset.t
  defp add_current_time(changeset) do
    changeset
      |> put_change(:creation_date, DateTime.utc_now())
  end

  @spec generate_account_id ::
    100_000..999_999
  defp generate_account_id,
    do: Enum.random(100_000..999_999)

  @spec generate_account_password ::
    String.t
  defp generate_account_password,
    do: Password.generate(:bank_account)

  defmodule Query do

    import Ecto.Query

    alias Helix.Account.Model.Account
    alias Helix.Universe.Bank.Model.BankAccount

    @spec by_id(Ecto.Queryable.t, BankAccount.account) ::
      Ecto.Queryable.t
    def by_id(query \\ BankAccount, account),
      do: where(query, [b], b.account_number == ^account)

    @spec by_owner(Ecto.Queryable.t, Account.id) ::
      Ecto.Queryable.t
    def by_owner(query \\ BankAccount, owner),
      do: where(query, [b], b.owner_id == ^owner)

    def order_by_creation_date(query),
      do: order_by(query, [b], b.creation_date)

    def select_balance(query),
      do: select(query, [b], b.balance)

    def select_sum_balance(query),
      do: select(query, [b], sum(b.balance))

    def lock_for_update(query),
      do: lock(query, "FOR UPDATE")
  end
end
