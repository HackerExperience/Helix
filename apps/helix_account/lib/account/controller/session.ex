defmodule Helix.Account.Controller.Session do

  @behaviour Guardian.Serializer

  alias Helix.Account.Controller.Account, as: AccountController
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Session

  # REVIEW: What is this expecting to receive exactly ? I'll make it temporarily
  #   just store the account's id
  @spec for_token(Account.t) :: {:ok, Session.t}
  def for_token(%Account{account_id: account_id}) when is_binary(account_id),
    do: {:ok, to_string(account_id)}
    def for_token(_),
      do: {:error, "invalid input"}

  # Well. i think that this module should not be inside the model folders
  # if it depends on external data, but let's leave it as is until we fix it
  @spec from_token(Session.t) :: {:ok, Account.t}
  def from_token(account_id) do
    case AccountController.fetch(account_id) do
      nil ->
        # FIXME: use a better error message
        {:error, "notfound"}
      account ->
        {:ok, account}
    end
  end

  @spec create(Account.t) :: {:ok, Session.t, claims :: map}
  def create(account) do
    Guardian.encode_and_sign(account, :access)
  end

  @spec validate(Session.t) ::
  {:ok, claims :: map}
  | {:error, :unauthorized}
  def validate(jwt) do
    case Guardian.decode_and_verify(jwt) do
      {:ok, claims} ->
        {:ok, claims}
      {:error, _} ->
        {:error, :unauthorized}
    end
  end

end
