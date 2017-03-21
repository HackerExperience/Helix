defmodule Helix.Account.Repo.Migrations.AddUsername do
  use Ecto.Migration

  def change do
    drop unique_index(:accounts, [:email], name: :unique_account_email)

    alter table(:accounts) do
      add :username, :string, null: false
      add :display_name, :string, null: false
    end

    create unique_index(:accounts, [:username])
    create unique_index(:accounts, [:email])
  end
end
