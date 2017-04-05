defmodule Helix.Account.Service.API.Account do

  alias Helix.Account.Controller.Account, as: AccountController
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Session

  @spec create(String.t, String.t, String.t) ::
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
    AccountController.create(params)
  end

  @spec login(Account.username, Account.password) ::
    {:ok, Session.t}
    | {:error, reason :: atom}
  @doc """
  Checks if `password` logs into `username`'s account

  This function is safe against timing attacks
  """
  def login(username, password) do
    # TODO: if it makes sense, use `erlang:send_after/3` to make the database
    #   fetch time be constant even when the user account doesn't exist to avoid
    #   guessing about it's validity. Albeit i don't think it's really worth as
    #   anyone that has an account can check if a certain username exists. (it
    #   would make sense if we used email for login tho)
    # TODO: check account status (when implemented) and return error for
    #   non-confirmed email and for banned account
    account = AccountController.fetch_by_username(username)

    if Account.check_password(account, password) do
      {token, _} = Helix.Account.Service.API.Session.generate_token(account)
      {:ok, token}
    else
      {:error, :notfound}
    end
  end

  @spec logout(Session.t) :: :ok
  @doc """
  Invalidates session `token`
  """
  def logout(token),
   do: Helix.Account.Service.API.Session.invalidate_token(token)
end
