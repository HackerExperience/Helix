# defmodule Helix.Software.Model.CryptoKey.InvalidatedEvent do

#   alias Helix.Software.Model.CryptoKey

#   defstruct [:file_id]

#   def event(%CryptoKey{file_id: id}),
#     do: %__MODULE__{file_id: id}
# end
