defmodule Helix.Test.Process.View.Helper do

  def pview_full do
    ~w/
      process_id
      gateway_id
      target_server_id
      file_id
      network_id
      connection_id
      process_type
      state
      allocated
      priority
      creation_time
    /a
    |> Enum.sort()
  end

  def pview_partial do
    ~w/
      process_id
      target_server_id
      file_id
      network_id
      process_type
    /a
    |> Enum.sort()
  end
end
