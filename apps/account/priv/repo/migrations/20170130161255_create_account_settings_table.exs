defmodule Helix.Account.Repo.Migrations.CreateAccountSettingsTable do
  use Ecto.Migration

  def change do
    create table(:settings, primary_key: false) do
      add :setting_id, :string, primary_key: true
      add :default_value, :string, null: false
    end

    create table(:account_settings, primary_key: false) do
      add :account_id, references(:accounts, column: :account_id, type: :inet, on_delete: :delete_all), primary_key: true
      add :setting_id, references(:settings, column: :setting_id, type: :string, on_delete: :delete_all), primary_key: true
      add :setting_value, :string, null: false
    end
  end
end
