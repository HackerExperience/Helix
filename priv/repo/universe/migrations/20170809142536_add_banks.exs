defmodule Helix.Universe.Repo.Migrations.AddBanks do
  use Ecto.Migration

  def change do

    # Note: I wouldn't add an index on `bank_id` here because this table would
    # have at most ~10 rows, so the index is pretty much useless.... BUT we
    # need the unique constraint in order to reference it elsewhere as a FK
    create table(:banks, primary_key: false) do
      add :bank_id,
        references(
          :npcs,
          column: :npc_id,
          type: :inet),
        primary_key: true
      add :name,
        :string,
        null: false
    end

    create table(:atms, primary_key: false) do
      add :atm_id,
        :inet,
        primary_key: true
      add :bank_id,
        references(
          :banks,
          column: :bank_id,
          type: :inet),
        null: false
      add :region,
        :string,
        null: false
    end
    create index(:atms, [:bank_id])

    create table(:bank_accounts, primary_key: false) do
      add :atm_id,
        references(
          :atms,
          column: :atm_id,
          type: :inet),
        primary_key: true
      add :account_number,
        :integer,
        primary_key: true
      add :bank_id,
        references(
          :banks,
          column: :bank_id,
          type: :inet),
        null: false
      add :owner_id,
        :inet,
        null: false
      add :password,
        :string,
        null: false
      add :balance,
        :integer,
        null: false
      add :creation_date,
        :utc_datetime
    end
    create index(:bank_accounts, [:owner_id])
    create constraint(:bank_accounts, :non_neg_balance, check: "balance >= 0")

    create table(:bank_transfers, primary_key: false) do
      add :transfer_id,
        :inet,
        primary_key: true
      add :atm_from,
        :inet,
        null: false
      add :account_from,
        :integer,
        null: false
      add :atm_to,
        :inet,
        null: false
      add :account_to,
        :integer,
        null: false
      add :amount,
        :integer,
        null: false
      add :started_time,
        :utc_datetime,
        null: false
      add :started_by,
        :inet,
        null: false
    end
    create index(:bank_transfers, [:atm_from, :account_from])
    create index(:bank_transfers, [:atm_to, :account_to])
    create index(:bank_transfers, [:started_by])
    create constraint(:bank_transfers, :non_neg_amount, check: "amount >= 0")

    # Apparently Ecto does not work well with composite FKs
    # https://elixirforum.com/t/does-ecto-supports-composite-foreign-keys/2466
    execute """
    ALTER TABLE bank_transfers
      ADD CONSTRAINT bank_transfer_acc_from_fkey
        FOREIGN KEY (atm_from, account_from)
        REFERENCES bank_accounts(atm_id, account_number)
        ON DELETE CASCADE,
      ADD CONSTRAINT bank_transfer_acc_to_fkey
        FOREIGN KEY (atm_to, account_to)
        REFERENCES bank_accounts(atm_id, account_number)
        ON DELETE CASCADE
    """
  end
end
