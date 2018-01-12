defmodule Helix.Process.Repo.Migrations.AddSourceConnection do
  use Ecto.Migration

  def change do
    alter table(:processes, primary_key: false) do
      add :target_connection_id, :inet
      add :target_file_id, :inet
    end

    # Index used to query processes based on the connection they are targeting
    create index(
      :processes,
      [:target_connection_id],
      where: "target_connection_id IS NOT NULL"
    )

    # Index used to query processes based on the file they are targeting
    create index(
      :processes,
      [:target_file_id],
      where: "target_file_id IS NOT NULL"
    )

    # Recreate processes indexes using partial ones
    drop index(:processes, [:file_id])
    create index(
      :processes,
      [:file_id],
      where: "file_id IS NOT NULL"
    )

    drop index(:processes, [:connection_id])
    create index(
      :processes,
      [:connection_id],
      where: "connection_id IS NOT NULL"
    )
  end
end
