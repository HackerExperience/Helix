defmodule Helix.Server.Repo.Migrations.CreateServerTypeTable do
  use Ecto.Migration

  def change do
    create table(:server_types, primary_key: false) do
      add :server_type, :string, primary_key: true

      timestamps()
    end

    alter table(:servers) do
      modify :server_type, references(:server_types, column: :server_type, type: :string)
    end
  end
end
