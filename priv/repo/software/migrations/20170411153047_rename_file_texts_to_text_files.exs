defmodule Helix.Software.Repo.Migrations.RenameFileTextsToTextFiles do
  use Ecto.Migration

  def change do
    rename table(:file_texts), to: table(:text_files)
  end
end
