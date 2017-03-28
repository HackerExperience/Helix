defmodule Helix.Account.Repo.Migrations.RefactorAccountSettings do
  use Ecto.Migration

  def change do
    alter table(:account_settings) do
      remove :setting_id
      remove :setting_value
      add :settings, :map, null: false
    end

    drop table(:settings)
  end
end
