defmodule Helix.Account.Repo.Migrations.CreateAccountDatabase do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :account_id, :string, primary_key: true
      add :password, :string, null: false
      add :email, :string
      add :confirmed, :boolean, default: false

      timestamps()
    end

    create unique_index(:accounts, [:account_id], name: :unique_account_id)
    create unique_index(:accounts, [:email], name: :unique_account_email)
  end
end
