defmodule Helix.Test.Universe.Bank.Websocket.Requests.CloseAccount do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Websocket.Requestable
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Requests.CloseAccount, as: BankCloseAccountRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "BankCloseAccountRequest.handle_request/2" do
    # Tested on BankAccountInternal
  end
end
