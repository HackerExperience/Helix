defmodule Helix.Universe.Bank.Internal.ATM do

  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Repo

  @spec fetch(ATM.id) ::
    ATM.t
    | nil
  def fetch(atm_id),
    do: Repo.get(ATM, atm_id)

  @spec create(ATM.creation_params) ::
    {:ok, ATM.t}
    | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> ATM.create_changeset()
    |> Repo.insert()
  end
end
