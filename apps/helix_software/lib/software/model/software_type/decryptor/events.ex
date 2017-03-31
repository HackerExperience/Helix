defmodule Helix.Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent do

  @enforce_keys [:target_file_id, :storage_id, :target_server_id, :scope]
  defstruct [:target_file_id, :storage_id, :target_server_id, :scope]
end
