import Helix.Process

process Helix.Universe.Bank.Process.Bank.Account.RevealPassword do

  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken

  process_struct [:token_id, :atm_id, :account_number]

  @process_type :bank_reveal_password

  @type t ::
    %__MODULE__{
      token_id: BankToken.id,
      atm_id: ATM.id,
      account_number: BankAccount.account
    }

  @type creation_params ::
    %{
      token_id: BankToken.id,
      account: BankAccount.t
    }

  @type objective :: %{cpu: resource_usage}

  @type resources :: %{
    objective: objective,
    static: map,
    dynamic: [:cpu]
  }

  @typep resources_params ::
    %{
      account: BankAccount.t
    }

  @spec new(creation_params) ::
    t
  def new(%{token_id: token_id, account: account = %BankAccount{}}) do
    %__MODULE__{
      token_id: token_id,
      atm_id: account.atm_id,
      account_number: account.account_number
    }
  end

  @spec resources(resources_params) ::
    resources
  def resources(params = %{account: %BankAccount{}}),
    do: get_resources params

  processable do

    alias Helix.Universe.Bank.Event.RevealPassword.Processed,
      as: RevealPasswordProcessedEvent

    on_completion(process, data) do
      event = RevealPasswordProcessedEvent.new(process, data)

      {:delete, [event]}
    end
  end

  resourceable do

    alias Helix.Universe.Bank.Process.Bank.Account.RevealPassword,
      as: RevealPasswordProcess

    @type params :: RevealPasswordProcess.objective_params
    @type factors :: term

    # TODO proper balance
    get_factors(%{account: _account}) do end

    cpu(_) do
      1
    end

    dynamic do
      [:cpu]
    end
  end

  executable do

    alias Helix.Universe.Bank.Process.Bank.Account.RevealPassword,
      as: RevealPasswordProcess

    @type params :: RevealPasswordProcess.creation_params

    @type meta ::
      %{
        optional(atom) => term
      }

    resources(_, _, %{account: account}, _) do
      %{account: account}
    end
  end
end
