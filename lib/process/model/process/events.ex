defmodule Helix.Process.Model.Process.ProcessCreatedEvent do

  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process

  @type t :: %__MODULE__{
    process_id: Process.id,
    gateway_id: Server.id,
    target_id: Server.id
  }

  @enforce_keys [:process_id, :gateway_id, :target_id]
  defstruct [:process_id, :gateway_id, :target_id]
end

defmodule Helix.Process.Model.Process.ProcessConclusionEvent do

  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{
    gateway_id: Server.id,
    target_id: Server.id
  }

  # This event is used solely to update the TOP display on the client
  @enforce_keys [:gateway_id, :target_id]
  defstruct [:gateway_id, :target_id]
end
