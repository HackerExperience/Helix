defmodule Helix.Test.Account.Helper do

  import Ecto.Query, only: [from: 1]

  alias Helix.Account.Model.Account
  alias Helix.Account.Repo, as: AccountRepo

  @doc """
  Fetches all accounts
  """
  def get_all,
    do: AccountRepo.all(from a in Account)
end
