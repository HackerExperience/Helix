defmodule Helix.Software.Repo.Migrations.CreateFileTextTable do
  use Ecto.Migration

  def change do
    create table(:file_texts, primary_key: false) do
      add :file_id, references(:files, column: :file_id, type: :inet, on_delete: :delete_all), primary_key: true
      add :contents, :text
    end

    create constraint(:file_texts, :contents_size, check: "char_length(contents) <= 8192")
  end
end
