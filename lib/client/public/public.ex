defmodule Helix.Client.Public do

  alias Helix.Client.Web1.Public, as: Web1Public

  def bootstrap(client, entity_id),
    do: %{client: dispatch_bootstrap(client, entity_id)}

  defp dispatch_bootstrap(:web1, entity_id),
    do: Web1Public.bootstrap(entity_id)

  defp dispatch_bootstrap(_, _),
    do: %{}
end
