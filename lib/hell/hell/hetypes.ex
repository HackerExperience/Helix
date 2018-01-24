defmodule HELL.HETypes do
  @moduledoc """
  Common types used by Helix and not directly related to a specific service.
  """

  @type client_timestamp :: float
  @type client_nip :: %{network_id: String.t, ip: String.t}

  @type uuid :: String.t

end
