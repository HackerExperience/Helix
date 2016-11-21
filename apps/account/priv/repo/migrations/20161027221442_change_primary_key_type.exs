defmodule HELM.Account.Repo.Migrations.ChangePrimaryKeyType do
  use Ecto.Migration

  def change do
    alter table(:accounts) do
      remove :account_id
      add :account_id, :binary_id, primary_key: true
    end
  end
end