defmodule Helix.Universe.Bank.Model.BankTransfer.BankTransferCompletedEvent do
  @moduledoc false

  @enforce_keys ~w/transfer_id connection_id/a
  defstruct ~w/transfer_id connection_id/a
end

defmodule Helix.Universe.Bank.Model.BankTransfer.BankTransferAbortedEvent do
  @moduledoc false

  @enforce_keys ~w/transfer_id connection_id/a
  defstruct ~w/transfer_id connection_id/a
end
