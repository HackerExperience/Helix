defmodule Helix.Software.Public.View.File do

  alias Helix.Software.Model.File

  @spec render(File.t) ::
    %{
      file_id: File.id,
      path: File.path,
      size: File.size,
      software_type: File.type,
      modules: File.modules
    }
  def render(file = %File{}) do
    %{
      file_id: file.file_id,
      path: file.full_path,
      size: file.file_size,
      software_type: file.software_type,
      modules: %{}
    }
  end
end
