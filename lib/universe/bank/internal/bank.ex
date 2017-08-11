defmodule Helix.Universe.Bank.Internal.Bank do

  alias Helix.Universe.Bank.Model.Bank
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Repo

  def fetch(bank_id),
    do: Repo.get(Bank, bank_id)

  def create(params) do
    params
    |> Bank.create_changeset()
    |> Repo.insert()
  end

end
