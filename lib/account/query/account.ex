defmodule Helix.Account.Query.Account do

  alias Helix.Account.Internal.Account, as: AccountInternal
  alias Helix.Account.Model.Account

  @spec fetch(Account.id) ::
    Account.t
    | nil
  defdelegate fetch(id),
    to: AccountInternal

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
