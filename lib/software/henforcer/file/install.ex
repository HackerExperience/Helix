defmodule Helix.Software.Henforcer.File.Install do

  import Helix.Henforcer

  alias Helix.Entity.Henforcer.Entity, as: EntityHenforcer
  alias Helix.Entity.Model.Entity
  alias Helix.Software.Henforcer.File, as: FileHenforcer
  alias Helix.Software.Model.File

  @type can_install_relay :: %{file: File.t, entity: Entity.t}
  @type can_install_relay_partial :: map
  @type can_install_error ::
    is_installable_error
    | EntityHenforcer.entity_exists_error

  @spec can_install?(File.id, Entity.id) ::
    {true, can_install_relay}
    | can_install_error
  @doc """
  Checks whether the given `file_id` can be installed by `entity_id`.

  This is a very "soft" / thin verification, i.e. it only makes sure the file
  is installable. The caller is supposed to verify the file class (e.g. virus)
  and henforce accordingly. For an example of this, see FileInstallRequest
  """
  def can_install?(file_id = %File.ID{}, entity_id = %Entity.ID{}) do
    with \
      {true, r1} <- is_installable?(file_id),
      {true, r2} <- EntityHenforcer.entity_exists?(entity_id)
    do
      reply_ok(relay(r1, r2))
    end
  end

  @type is_installable_relay :: %{file: File.t}
  @type is_installable_relay_partial :: is_installable_relay
  @type is_installable_error ::
    {false, {:file, :not_installable}, is_installable_relay_partial}

  @spec is_installable?(File.idt) ::
    {true, is_installable_relay}
    | is_installable_error
  @doc """
  Henforces the given file is installable.

  (Not to confuse with Executable. Executable files are the ones handled by
  ActionFlow.execute, while Installable files are the ones handled by
  FileInstallProcess)
  """
  def is_installable?(file_id = %File.ID{}) do
    henforce(FileHenforcer.file_exists?(file_id)) do
      is_installable?(relay.file)
    end
  end

  def is_installable?(file = %File{}) do
    installable_software = [:virus_spyware]

    if file.software_type in installable_software do
      reply_ok()
    else
      reply_error({:file, :not_installable})
    end
    |> wrap_relay(%{file: file})
  end
end
