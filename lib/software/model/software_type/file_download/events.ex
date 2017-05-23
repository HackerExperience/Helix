defmodule Helix.Software.Model.SoftwareType.FileDownload do
  @moduledoc false

  defmodule ProcessConclusionEvent do
    @moduledoc false

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
