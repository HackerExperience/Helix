defmodule Helix.Test.Software.Setup.Virus do

  alias Ecto.Changeset
  alias Helix.Software.Internal.File, as: FileInternal
  alias Helix.Software.Internal.Virus, as: VirusInternal
  alias Helix.Software.Model.Virus
  alias Helix.Software.Repo, as: SoftwareRepo

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
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

    # Possibly fetch again in case the user requested a custom `running_time`
    virus =
      if opts[:running_time] do
        {:ok, new_virus} =
          VirusInternal.set_running_time(virus, opts[:running_time])

        new_virus
      else
        virus
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
  - running_time: Set for how long the virus have been running. Defaults to 0s.
  - real_server?: whether to generate the underlying server. Defaults to false.
    When used, overrides `storage_id`.

  Related:
    - File.t (when `real_life?` is set),
    - Server.t (when `real_server?` is set)
  """
  def fake_virus(opts \\ []) do
    if opts[:real_file?] == true and not is_nil(opts[:file_id]),
      do: raise "Cant ask me to generate a file and provide the file id. Duh."

    file_id = Keyword.get(opts, :file_id, SoftwareHelper.id())
    entity_id = Keyword.get(opts, :entity_id, EntityHelper.id())
    is_active? = Keyword.get(opts, :is_active?, true)

    server =
      if opts[:real_server?] do
        ServerSetup.server!()
      else
        nil
      end

    {file_id, file} =
      if opts[:real_file?] == false do
        {file_id, nil}
      else
        type = Keyword.get(opts, :type, :virus_spyware)

        file =
          if server do
            server_storage_id = SoftwareHelper.get_storage_id(server)

            # Underlying server won't be generated because of `storage_id` opt
            SoftwareSetup.file!(type: type, storage_id: server_storage_id)
          else
            file = SoftwareSetup.file!(type: type)

            if opts[:storage_id] do
              %{file | storage_id: opts[:storage_id]}
            else
              file
            end
          end

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
        changeset: Changeset.change(virus),
        server: server
      }

    {virus, related}
  end

  def fake_virus!(opts \\ []) do
    {virus, _} = fake_virus(opts)
    virus
  end
end
