defmodule Helix.Entity.Repo.Migrations.AddEntityBankAccounts do
  use Ecto.Migration

  def change do
    create table(:database_bank_accounts, primary_key: false) do
      add :entity_id,
        references(
          :entities,
          column: :entity_id,
          type: :inet,
          on_delete: :delete_all),
        primary_key: true
      add :atm_id, :inet, primary_key: true
      add :account_number, :integer, primary_key: true

      add :password, :string
      add :token, :uuid
      add :atm_ip, :inet, null: false
      add :known_balance, :integer

      add :notes, :string

      add :last_login_date, :utc_datetime
      add :last_update, :utc_datetime
    end
    create index(:database_bank_accounts, [:atm_id, :account_number])
    create index(:database_bank_accounts, [:entity_id, :last_update])

    drop table(:database_entries)

    create table(:database_servers, primary_key: false) do
      add :entity_id,
        references(
          :entities,
          column: :entity_id,
          type: :inet,
          on_delete: :delete_all,
          on_update: :update_all),
        primary_key: true
      add :network_id, :inet, primary_key: true
      add :server_ip, :inet, primary_key: true

      add :server_id, :inet, null: false
      add :server_type, :string, null: false
      add :password, :string

      add :alias, :string
      add :notes, :text

      add :last_update, :utc_datetime
    end

    create index(:database_servers, [:network_id, :server_ip])
    create index(:database_servers, [:entity_id, :last_update])
    # NOTE: Index below currently not used, but probably will be once we add
    # e.g. password reset, where we'd have to invalidate/notify all users who
    # have that Server on the Database that it has changed IP.
    create index(:database_servers, [:server_id])
  end
end
