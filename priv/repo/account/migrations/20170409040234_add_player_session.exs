defmodule Helix.Account.Repo.Migrations.AddPlayerSession do
  use Ecto.Migration

  def change do
    drop table(:blacklisted_tokens)

    create table(:account_sessions, primary_key: false) do
      add :session_id,
        :uuid,
        primary_key: true
      add :account_id,
        references(
          :accounts,
          column: :account_id,
          type: :inet,
          on_delete: :delete_all)

      timestamps()
    end
  end
end
