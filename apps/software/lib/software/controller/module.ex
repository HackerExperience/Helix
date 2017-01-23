defmodule Helix.Software.Controller.Module do

  #alias Helix.Software.Model.ModuleRole
  alias Helix.Software.Model.Module
  alias Helix.Software.Model.File
  alias Helix.Software.Repo

  @type module_roles :: %{role :: HELL.PK.t => version :: non_neg_integer}

  @spec create(File.t, module_roles) ::
    {:ok, module_roles}
    | {:error, :internal}
  def create(file, roles) do
    Repo.transaction(fn ->
      roles
      |> Enum.map(fn {module_role_id, version} ->
        %{
          file_id: file.file_id,
          module_role_id: module_role_id,
          module_version: version
        }
        |> Module.create_changeset()
        |> Repo.insert()
        |> case do
          {:ok, _} ->
            {module_role_id, version}
          {:error, _} ->
            Repo.rollback(:internal)
        end
      end)
      |> Enum.into(%{})
    end)
  end

  @spec find(File.t) :: module_roles
  def find(file) do
    file.file_id
    |> Module.Query.by_file()
    |> Repo.all()
    |> Enum.map(&({&1.module_role_id, &1.module_version}))
    |> Enum.into(%{})
  end

  @spec update(File.t, HELL.PK.t, version :: non_neg_integer) ::
    {:ok, Module.t}
    | {:error, :notfound | :internal}
  def update(file, module_role, version) do
    file.file_id
    |> Module.Query.by_file()
    |> Module.Query.by_role(module_role)
    |> Repo.one()
    |> case do
      nil ->
        {:error, :notfound}
      file_module ->
        file_module
        |> Module.update_changeset(%{module_version: version})
        |> Repo.update()
        |> case do
          {:ok, file_module} ->
            {:ok, file_module}
          {:error, _} ->
            {:error, :internal}
        end
    end
  end
end