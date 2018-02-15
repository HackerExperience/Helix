defmodule Helix.Software.Public.Virus do

  alias Helix.Software.Action.Flow.Virus, as: VirusFlow

  @doc """
  Starts a `VirusCollectProcess` for the given viruses.
  """
  defdelegate start_collect(gateway, viruses, bounce_id, payment_info, relay),
    to: VirusFlow
end
