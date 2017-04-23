defmodule Helix.Software.Model.SoftwareType.FileDownload do
  defmodule ProcessConclusionEvent do
    @enforce_keys ~w/
      to_server_id
      from_server_id
      from_file_id
      to_storage_id
      network_id/a
    defstruct ~w/
      to_server_id
      from_server_id
      from_file_id
      to_storage_id
      network_id/a
  end
end
