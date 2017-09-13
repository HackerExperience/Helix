defmodule Helix.Universe.Repo.Migrations.AddBankToken do
  use Ecto.Migration

  def change do
    create table(:bank_tokens, primary_key: false) do
      add :token_id, :uuid, primary_key: true
      add :atm_id, :inet, null: false
      add :account_number, :integer, null: false
      add :connection_id, :inet, null: false
      add :expiration_date, :utc_datetime
    end
    create index(:bank_tokens, [:atm_id, :account_number])

    # NOTE: as far as game mechanic goes, `connection_id` is unique, since
    # one connection can only hold one token. However, since we lazily remove
    # expired entries, it could happen that a recently expired token would be
    # recreated on that same connection, violating the unique constraint.
    # HOWEVER, tokens are only set to expire once the underlying connection
    # is removed. As such, because of the game mechanics, it's impossible that
    # an expired token, which hasn't been deleted yet, conflicts with a new
    # token using the same connection, since that connection no longer exists.
    create index(:bank_tokens, [:connection_id], unique: true)

    # NOTE: partial index on expiration_date when it's not null would probably
    # *not* be useful due to data distribution:
    #   - Small table size (tokens are only generated when needed)
    #   - Small table size 2 (tokens get removed shortly after expiration)
    #   - Relatively short-lived connections (tokens are set to expire quickly)
    # As a result, it's likely that at any given time, > 80% of the tokens are
    # set to expire within their TTL (5 minutes), and as such their expiration
    # date is NOT NULL.
    create index(:bank_tokens, [:expiration_date])

    execute """
    ALTER TABLE bank_tokens
      ADD CONSTRAINT bank_token_acc_fkey
      FOREIGN KEY (atm_id, account_number)
      REFERENCES bank_accounts(atm_id, account_number)
      ON DELETE CASCADE
    """
  end
end
