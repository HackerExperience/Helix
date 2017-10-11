defmodule Helix.Software.Repo.Migrations.ChangeFileModules do
  use Ecto.Migration

  def change do
    rename table(:software_modules), :software_module, to: :module

    rename table(:file_modules), :module_version, to: :version
    rename table(:file_modules), :software_module, to: :name

    drop constraint(:file_modules, :module_version_must_be_positive)
    create constraint(
      :file_modules,
      :version_is_positive,
      check: "version > 0"
    )
  end
end
