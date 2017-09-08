defmodule Helix.Account.Repo.Migrations.CreateBlacklistedTokens do
  use Ecto.Migration

  def change do
    create table(:blacklisted_tokens, primary_key: false) do
      add :token,
        :text,
        primary_key: true
      add :expiration,
        :utc_datetime,
        null: false
    end
  end
end
