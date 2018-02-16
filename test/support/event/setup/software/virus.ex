defmodule Helix.Test.Event.Setup.Software.Virus do

  alias Helix.Software.Event.Virus.Collect.Processed,
    as: VirusCollectProcessedEvent
  alias Helix.Software.Event.Virus.Collected, as: VirusCollectedEvent

  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @doc """
  Opts:
  - virus: Specify origin virus (`Virus.t`). Defaults to generating fake virus
  - earnings: Specify total earnings. Defaults to cash-based earnings
  - bank_account: Set which bank account to use. Defaults to fake bank account.
  - wallet: Set which wallet to use. Defaults to `nil`
  """
  def collected(opts \\ []) do
    virus = Keyword.get(opts, :virus, SoftwareSetup.Virus.fake_virus!())
    earnings = Keyword.get(opts, :earnings, BankHelper.amount())
    bank_acc = Keyword.get(opts, :bank_account, BankSetup.fake_account!())
    wallet = Keyword.get(opts, :wallet, nil)

    VirusCollectedEvent.new(virus, earnings, {bank_acc, wallet})
  end

  @doc """
  Opts:
  - virus: Specify origin file (`File.t`). REQUIRED.
  - earnings: Specify total earnings. Defaults to cash-based earnings
  - bank_account: Set which bank account to use. Defaults to fake bank account.
  - wallet: Set which wallet to use. Defaults to `nil`
  """
  def collect_processed(opts \\ []) do
    file = Keyword.fetch!(opts, :file)
    bank_acc = Keyword.get(opts, :bank_account, BankSetup.fake_account!())
    wallet = Keyword.get(opts, :wallet, nil)

    %VirusCollectProcessedEvent{
      file: file,
      payment_info: {bank_acc, wallet}
    }
  end
end
