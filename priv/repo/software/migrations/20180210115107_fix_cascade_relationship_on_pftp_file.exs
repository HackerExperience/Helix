defmodule Helix.Software.Repo.Migrations.FixCascadeRelationshipOnPFTPFile do
  use Ecto.Migration

  def change do
    # Remove old FK
    execute """
    ALTER TABLE pftp_files
      DROP CONSTRAINT pftp_files_file_id_fkey
    """

    # Add new FK with ON DELETE CASCADE (as opposed to SET NULL)
    execute """
    ALTER TABLE pftp_files
      ADD CONSTRAINT pftp_files_file_id_fkey
      FOREIGN KEY (file_id)
      REFERENCES files(file_id)
      ON DELETE CASCADE;
    """
  end
end
