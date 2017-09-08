defmodule Helix.Universe.Bank.Model.BankTransfer do

  use Ecto.Schema
  use HELL.ID, field: :transfer_id, meta: [0x0040]

  import Ecto.Changeset

  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.ATM

  @type t :: %__MODULE__{
    transfer_id: id,
    account_from: BankAccount.account,
    account_to: BankAccount.account,
    atm_from: ATM.id,
    atm_to: ATM.id,
    amount: pos_integer,
    started_by: Account.id,
    started_time: DateTime.t,
  }

  @type creation_params :: %{
    account_from: BankAccount.account,
    account_to: BankAccount.account,
    atm_from: ATM.idtb,
    atm_to: ATM.idtb,
    amount: pos_integer,
    started_by: Account.idtb,
  }

  @creation_fields ~w/
    account_from
    account_to
    atm_from
    atm_to
    amount
    started_by/a

  @primary_key false
  schema "bank_transfers" do
    field :transfer_id, ID,
      primary_key: true
    field :account_from, :integer
    field :account_to, :integer
    field :atm_from, Server.ID
    field :atm_to, Server.ID
    field :amount, :integer
    field :started_by, Account.ID
    field :started_time, :utc_datetime
  end

  @spec create_changeset(creation_params) ::
    Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
    |> add_time_information()
  end

  defp generic_validations(changeset) do
    changeset
    |> validate_required(@creation_fields)
    |> validate_number(:amount, greater_than: 0)
    |> validate_accounts()
  end

  defp validate_accounts(changeset) do
    from = get_change(changeset, :account_from)
    to = get_change(changeset, :account_to)

    if from == to do
      add_error(changeset, :accounts, "identical")
    else
      changeset
    end
  end

  defp add_time_information(changeset) do
    put_change(changeset, :started_time, DateTime.utc_now())
  end

  defmodule Query do

    import Ecto.Query, only: [where: 3, lock: 2]

    alias Helix.Account.Model.Account
    alias Helix.Universe.Bank.Model.BankTransfer

    @spec by_id(Ecto.Queryable.t, BankTransfer.id) ::
      Ecto.Queryable.t
    def by_id(query \\ BankTransfer, transfer),
      do: where(query, [t], t.transfer_id == ^transfer)

    def lock_for_update(query),
      do: lock(query, "FOR UPDATE")
  end
end
