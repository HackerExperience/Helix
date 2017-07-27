defmodule Helix.Account.Action.Account do

  alias Helix.Event
  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Account.Internal.Account, as: AccountInternal
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Account.AccountCreatedEvent
  alias Helix.Account.Model.AccountSession

  @spec create(Account.email, Account.username, Account.password) ::
    {:ok, Account.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates an user

  ## Examples

      iex> create("foo@bar.com", "not_an_admin", "password_rhymes_with_assword")
      {:ok, %Account{}}

      iex> create("invalid email", "I^^^nvalid U**ser", "badpas")
      {:error, %Ecto.Changeset{}}
  """
  def create(email, username, password) do
    params = %{
      email: email,
      username: username,
      password: password
    }

    create(params)
  end

  @spec create(Account.creation_params) ::
    {:ok, Account.t}
    | {:error, Ecto.Changeset.t}
  @doc """
  Creates an user

  ## Examples

      iex> create(%{
        email: "foo@bar.com",
        username: "not_an_admin",
        password: "letmeinpl0x"
      })
      {:ok, %Account{}}

      iex> create(%{
        email: "invalid email",
        username: "I^^^nvalid U**ser",
        password: "badpas"
      })
      {:error, %Ecto.Changeset{}}
  """
  def create(params) do
    case AccountInternal.create(params) do
      {:ok, account} ->
        Event.emit(%AccountCreatedEvent{account_id: account.account_id})
        {:ok, account}
      error ->
        error
    end
  end

  @spec login(Account.username, Account.password) ::
    {:ok, Account.t, AccountSession.token}
    | {:error, :notfound}
    | {:error, :internalerror}
  @doc """
  Checks if `password` logs into `username`'s account

  This function is safe against timing attacks
  """
  def login(username, password) do
    # TODO: check account status (when implemented) and return error for
    #   non-confirmed email and for banned account
    with \
      account = %{} <- AccountInternal.fetch_by_username(username) || :nxacc,
      true <- Account.check_password(account, password) || :badpass,
      {:ok, token} <- SessionAction.generate_token(account) || :badserver
    do
      {:ok, account, token}
    else
      :nxacc ->
        {:error, :notfound}
      :badpass ->
        {:error, :notfound}
      :badserver ->
        {:error, :internalerror}
      _ ->
        {:error, :internalerror}
    end
  end
end
