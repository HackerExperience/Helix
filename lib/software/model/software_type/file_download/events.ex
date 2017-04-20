defmodule Helix.Software.Model.SoftwareType.FileDownload do
  defmodule ProcessConclusionEvent do

    @enforce_keys [:target_file_id, :server_id, :destination_storage_id]
    defstruct [:target_file_id, :server_id, :destination_storage_id]
  end
end
