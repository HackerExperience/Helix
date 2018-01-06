defmodule Helix.Software.Internal.File.Meta do

  import HELL.Macros

  alias Helix.Software.Internal.Virus, as: VirusInternal
  alias Helix.Software.Model.File

  @spec gather_metadata(File.t) ::
    File.t
  @doc """
  `gather_metadata` receives a `File.t` (right after it's been fetched by
  FileInternal) and merges any metadata that may be associated with the file.
  """
  def gather_metadata(file = %File{software_type: :virus_spyware}),
    do: virus_metadata(file)
  def gather_metadata(file),
    do: file

    @spec virus_metadata(File.t) ::
      File.t
  defp virus_metadata(file) do
    meta =
      %{installed?: VirusInternal.is_active?(file.file_id)}
      |> append_meta(file)

    %{file| meta: meta}
  end

  @spec append_meta(File.meta, File.t) ::
    File.meta
  docp """
  Appends the newly created meta with the file's current meta, with the new meta
  taking precedence over the current one in case of conflicts
  """
  defp append_meta(new_meta, %File{meta: cur_meta}),
    do: Map.merge(new_meta, cur_meta, fn _, a, _b -> a end)
end
