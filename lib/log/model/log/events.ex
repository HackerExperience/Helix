defmodule Helix.Log.Model.Log.LogCreatedEvent do
  @moduledoc false

  @enforce_keys [:server_id]
  defstruct [:server_id]
end

defmodule Helix.Log.Model.Log.LogModifiedEvent do
  @moduledoc false

  @enforce_keys [:server_id]
  defstruct [:server_id]
end

defmodule Helix.Log.Model.Log.LogDeletedEvent do
  @moduledoc false

  @enforce_keys [:server_id]
  defstruct [:server_id]
end
