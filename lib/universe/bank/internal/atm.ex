defmodule Helix.Universe.Bank.Internal.ATM do

  alias Helix.Universe.Bank.Model.Bank
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Repo

  def fetch(atm_id),
    do: Repo.get(ATM, atm_id)

  def create(params) do
    params
    |> ATM.create_changeset()
    |> Repo.insert()
  end
end
