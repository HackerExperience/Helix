defmodule Helix.Account.Query.Account do

  alias Helix.Account.Internal.Account, as: AccountInternal
  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  @spec fetch(Account.id) ::
    Account.t | nil
  def fetch(id),
    do: Repo.get(Account, id)

  @spec fetch_by_email(Account.email) ::
    Account.t
    | nil
  defdelegate fetch_by_email(email),
    to: AccountInternal

  @spec fetch_by_username(Account.username) ::
    Account.t
    | nil
  defdelegate fetch_by_username(username),
    to: AccountInternal
end
