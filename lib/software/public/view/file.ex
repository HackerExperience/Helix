defmodule Helix.Software.Public.View.File do

  alias Helix.Software.Model.File

  @spec render(File.t) ::
    %{
      file_id: HELL.PK.t,
      path: String.t,
      size: non_neg_integer,
      software_type: String.t,
      inserted_at: DateTime.t,
      updated_at: DateTime.t,
      meta: map,
      modules: map
    }
  def render(file = %File{}) do
    %{
      file_id: file.file_id,
      path: file.full_path,
      size: file.file_size,
      software_type: file.software_type,
      inserted_at: file.inserted_at,
      updated_at: file.updated_at,
      meta: %{},
      modules: %{}
    }
  end
end
