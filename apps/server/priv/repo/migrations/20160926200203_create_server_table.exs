defmodule HELM.Server.Repo.Migrations.CreateServerTable do
  use Ecto.Migration

  def change do
    create table(:servers, primary_key: false) do
      add :server_id, :string, primary_key: true

      timestamps
    end
    create unique_index(:servers, [:server_id], name: :unique_server_id)
  end
end
