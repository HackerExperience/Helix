defmodule Helix.Account.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :account_id, :inet, primary_key: true
      add :username, :string, null: false
      add :password, :string, null: false
      add :display_name, :string, null: false
      add :email, :string, null: false
      add :confirmed, :boolean, default: false

      timestamps()
    end

    create unique_index(:accounts, [:username])
    create unique_index(:accounts, [:email])

    create table(:account_settings, primary_key: false) do
      add :account_id, references(:accounts, column: :account_id, type: :inet, on_delete: :delete_all), primary_key: true
      add :settings, :map, null: false
    end
  end
end
