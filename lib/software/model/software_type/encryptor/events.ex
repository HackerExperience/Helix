defmodule Helix.Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent do

  @enforce_keys [:target_file_id, :target_server_id, :storage_id, :version]
  defstruct [:target_file_id, :target_server_id, :storage_id, :version]
end
