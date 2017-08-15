defmodule Helix.Universe.Bank.Internal.Bank do

  alias Helix.Universe.Bank.Model.Bank
  alias Helix.Universe.Repo

  @spec fetch(Bank.id) ::
    Bank.t
    | nil
  def fetch(bank_id),
    do: Repo.get(Bank, bank_id)

  @spec create(Bank.creation_params) ::
    {:ok, Bank.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> Bank.create_changeset()
    |> Repo.insert()
  end
end
