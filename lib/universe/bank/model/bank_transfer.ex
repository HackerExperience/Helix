defmodule Helix.Universe.Bank.Model.BankTransfer do

  use Ecto.Schema
  use HELL.ID, field: :transfer_id, meta: [0x0040]

  alias Helix.Account.Model.Account
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.ATM

  import Ecto.Changeset

  @type t :: %__MODULE__{
    transfer_id: id,
    account_from: BankAccount.account,
    account_to: BankAccount.account,
    atm_from: ATM.id,
    atm_to: ATM.id,
    amount: Integer.t,
    started_by: Account.id,
    started_time: DateTime.t,
    finish_time: DateTime.t
  }

  @type creation_params :: %{
    account_from: BankAccount.account,
    account_to: BankAccount.account,
    atm_from: ATM.id,
    atm_to: ATM.id,
    amount: Integer.t,
    started_by: Account.id,
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
    field :transfer_id, ID, primary_key: true
    field :account_from, :integer
    field :account_to, :integer
    field :atm_from, Server.ID
    field :atm_to, Server.ID
    field :amount, :integer
    field :started_by, Account.ID
    field :started_time, :utc_datetime
    field :finish_time, :utc_datetime
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
    now = DateTime.utc_now()
    amount = get_change(changeset, :amount)

    changeset
    |> put_change(:started_time, now)
    |> put_change(:finish_time, get_finish_time(amount, now))
  end

  defp get_finish_time(amount, now) do
    duration = calculate_duration(amount)

    now
    |> DateTime.to_unix(:second)
    |> Kernel.+(duration)
    |> DateTime.from_unix!(:second)
  end

  def calculate_duration(_amount) do
    600
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

    # @spec by_owner(Ecto.Queryable.t, Account.id) ::
    #   Ecto.Queryable.t
    # def by_owner(query \\ BankAccount, owner),
    #   do: where(query, [b], b.owner_id == ^owner)

  end
end
