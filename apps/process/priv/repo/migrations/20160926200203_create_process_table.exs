defmodule HELM.Process.Repo.Migrations.CreateProcessTable do
  use Ecto.Migration

  def change do
    create table(:processes, primary_key: false) do
      add :process_id, :string, primary_key: true

      timestamps()
    end
    create unique_index(:processes, [:process_id], name: :unique_process_id)
  end
end
