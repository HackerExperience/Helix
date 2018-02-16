defmodule Helix.Software.Repo.Migrations.AddActivationTime do
  use Ecto.Migration

  def change do
    alter table(:viruses_active, primary_key: true) do
      add :activation_time, :utc_datetime,
        null: false,
        default: fragment("now()")
    end
  end
end
