defmodule Helix.Test.Software.Setup.Virus do

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Internal.Virus, as: VirusInternal
  alias Helix.Software.Model.File
  alias Helix.Software.Model.Virus
  alias Helix.Software.Repo, as: SoftwareRepo

  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @doc """
  See doc on `fake_virus/1`.
  """
  def virus(opts \\ []) do
    {fake_virus, related = %{file: file}} = fake_virus(opts)

    virus = SoftwareRepo.insert!(fake_virus)

    {virus, file} =
      if virus.is_active? do
        {:ok, new_virus} = VirusInternal.activate_virus(virus, file.storage_id)

        # Fetch again to update the File's metadata (since it got installed)
        new_file = FileInternal.fetch(file.file_id)

        {new_virus, new_file}
      else
        {virus, file}
      end

    related = Map.replace(related, :file, file)

    {virus, related}
  end

  @doc """
  Opts:
  - file_id: Set file id.
  - entity_id: Set entity id.
  - storage_id: Set storage id (used only if Virus is active).
  - is_active?: Whether to mark virus as active. Defaults to true.
  - real_file?: Whether to generate the underlying virus file. Defaults to true
  - type: Virus type. Defaults to `spyware`. Only used when `real_file?` is set

  Related: File.t (when `real_life?` is set)
  """
  def fake_virus(opts \\ []) do
    if opts[:real_file?] == true and not is_nil(opts[:file_id]),
      do: raise "Cant ask me to generate a file and provide the file id. Duh."

    file_id = Keyword.get(opts, :file_id, File.ID.generate())
    entity_id = Keyword.get(opts, :entity_id, Entity.ID.generate())
    is_active? = Keyword.get(opts, :is_active?, true)

    {file_id, file} =
      if opts[:real_file?] == false do
        {file_id, nil}
      else
        type = Keyword.get(opts, :type, :virus_spyware)
        file = SoftwareSetup.file!(type: type)

        # Replace file `storage_id` in case one was specified
        file = %{file| storage_id: opts[:storage_id] || file.storage_id}

        {file.file_id, file}
      end

    virus =
      %Virus{
        entity_id: entity_id,
        file_id: file_id,
        is_active?: is_active?
      }
      |> Map.replace(:active, nil)

    related =
      %{
        file: file,
        changeset: Changeset.change(virus)
      }

    {virus, related}
  end
end
