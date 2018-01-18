defmodule Helix.Process.Repo.Migrations.AddSourceConnection do
  use Ecto.Migration

  def change do
    alter table(:processes, primary_key: false) do
      add :tgt_connection_id, :inet
      add :tgt_file_id, :inet
      add :tgt_process_id, :inet
    end

    # Rename process origins to `src_*`
    rename table(:processes), :file_id, to: :src_file_id
    rename table(:processes), :connection_id, to: :src_connection_id

    # Index used to query processes based on the connection they are targeting
    create index(
      :processes,
      [:tgt_connection_id],
      where: "tgt_connection_id IS NOT NULL"
    )

    # Index used to query processes based on the file they are targeting
    create index(
      :processes,
      [:tgt_file_id],
      where: "tgt_file_id IS NOT NULL"
    )

    # Index used to query processes based on the process they are targeting
    create index(
      :processes,
      [:tgt_process_id],
      where: "tgt_process_id IS NOT NULL"
    )

    # Recreate processes indexes using partial ones
    drop index(:processes, [:file_id])
    create index(
      :processes,
      [:src_file_id],
      where: "src_file_id IS NOT NULL"
    )

    drop index(:processes, [:connection_id])
    create index(
      :processes,
      [:src_connection_id],
      where: "src_connection_id IS NOT NULL"
    )
  end
end
