defmodule Helix.Account.Repo.Migrations.ChangePkToIp do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      remove :account_id
      add :account_id, :inet, primary_key: true
    end
  end
end