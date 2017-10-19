defmodule HELL.ClientUtils do

  alias HELL.HETypes

  @spec to_timestamp(DateTime.t) ::
    HETypes.client_timestamp
  def to_timestamp(datetime = %DateTime{}) do
    datetime
    |> DateTime.to_unix(:millisecond)
    |> Kernel./(1)  # Make it a float...
  end
end
