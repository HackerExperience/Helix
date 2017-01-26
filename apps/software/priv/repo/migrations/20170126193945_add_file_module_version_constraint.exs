defmodule Helix.Software.Repo.Migrations.AddFileModuleVersionConstraint do
  use Ecto.Migration

  def change do
    create constraint(:file_modules, :module_version_must_be_positive, check: "module_version > 0")
  end
end
