defmodule HELM.Software.Repo.Migrations.FixModuleRoles do
  use Ecto.Migration

  def change do
    alter table(:module_roles, primary_key: false) do
      remove :file_type
      remove :module_role
      add :module_role, :string, primary_key: true
      add :file_type, references(:file_types, column: :file_type, type: :string)
    end
  end
end
