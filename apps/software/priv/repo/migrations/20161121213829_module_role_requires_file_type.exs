defmodule Helix.Software.Repo.Migrations.ModuleRoleRequiresFileType do
  use Ecto.Migration

  def change do
    alter table(:module_roles) do
      modify :file_type, :string, null: false
    end
  end
end