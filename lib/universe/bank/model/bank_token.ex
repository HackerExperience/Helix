defmodule Helix.Universe.Bank.Model.BankToken do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Ecto.UUID
  alias Helix.Network.Model.Connection
  alias Helix.Server.Model.Server
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount

  @type idt :: t | id
  @type id :: String.t
  @type t :: %__MODULE__{
    token_id: id,
    account_number: BankAccount.account,
    atm_id: ATM.idtb,
    connection_id: Connection.idtb,
    expiration_date: DateTime.t
  }

  @type creation_params :: %{
    account_number: BankAccount.account,
    atm_id: ATM.idtb,
    connection_id: Connection.idtb
  }

  # Note the token TTL is applied *after* the connection has been closed,
  # so the token exists for the duration of the connection *plus* the TTL.
  @token_ttl 60 * 5  # 5 min

  @creation_fields ~w/atm_id account_number connection_id/a

  @primary_key false
  @ecto_autogenerate {:token_id, {UUID, :autogenerate, []}}
  schema "bank_tokens" do
    field :token_id, UUID,
      primary_key: true
    field :atm_id, Server.ID
    field :account_number, :integer
    field :connection_id, Connection.ID
    field :expiration_date, :utc_datetime
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
  end

  @spec generic_validations(Changeset.t) ::
    Changeset.t
  defp generic_validations(changeset) do
    changeset
    |> validate_required(@creation_fields)
  end

  @spec set_expiration_date(t) ::
    Changeset.t
  def set_expiration_date(token) do
    # TODO: Move to a utils
    expiration_date =
      DateTime.utc_now()
      |> DateTime.to_unix(:second)
      |> Kernel.+(@token_ttl)
      |> DateTime.from_unix!(:second)

    token
    |> change()
    |> put_change(:expiration_date, expiration_date)
  end

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Universe.Bank.Model.BankAccount
    alias Helix.Universe.Bank.Model.BankToken

    @spec by_token(Queryable.t, BankToken.idt) ::
      Queryable.t
    def by_token(query \\ BankToken, token),
      do: where(query, [t], t.token_id == ^token)

    # Check: Do I use this query (and index)?
    @spec by_atm_account(Queryable.t, ATM.idtb, BankAccount.account) ::
      Queryable.t
    def by_atm_account(query \\ BankToken, atm, account),
      do: where(query, [t], t.atm_id == ^atm and t.account_number == ^account)

    @spec by_connection(Queryable.t, Connection.idtb) ::
      Queryable.t
    def by_connection(query \\ BankToken, connection),
      do: where(query, [t], t.connection_id == ^connection)

    # TODO: Move to utils
    @spec filter_expired(Queryable.t) ::
      Queryable.t
    def filter_expired(query) do
        where(
          query,
          [t],
          is_nil(t.expiration_date) or t.expiration_date >= fragment("now() AT TIME ZONE 'UTC'"))
    end
  end
end
