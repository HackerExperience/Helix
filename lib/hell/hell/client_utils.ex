defmodule HELL.ClientUtils do

  alias HELL.HETypes

  @spec to_timestamp(DateTime.t) ::
  HETypes.client_timestamp
  def to_timestamp(datetime) do
    datetime
    |> DateTime.to_unix()
  end
end
