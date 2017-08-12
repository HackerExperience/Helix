defmodule Helix.Log.Model.Log.LogCreatedEvent do
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{server_id: Server.id}

  @enforce_keys [:server_id]
  defstruct [:server_id]
end

defmodule Helix.Log.Model.Log.LogModifiedEvent do
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{server_id: Server.id}

  @enforce_keys [:server_id]
  defstruct [:server_id]
end

defmodule Helix.Log.Model.Log.LogDeletedEvent do
  alias Helix.Server.Model.Server

  @type t :: %__MODULE__{server_id: Server.id}

  @enforce_keys [:server_id]
  defstruct [:server_id]
end
