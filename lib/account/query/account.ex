defmodule Helix.Account.Query.Account do

  alias Helix.Account.Model.Account
  alias Helix.Account.Repo

  @spec fetch(Account.id) ::
    Account.t | nil
  def fetch(id),
    do: Repo.get(Account, id)
end
