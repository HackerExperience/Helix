defmodule Helix.Software.Repo.Migrations.RemoveUselessTimestamps do
  use Ecto.Migration

  def change do
    alter table(:file_types) do
      remove :inserted_at
      remove :updated_at
    end

    alter table(:module_roles) do
      remove :inserted_at
      remove :updated_at
    end
  end
end