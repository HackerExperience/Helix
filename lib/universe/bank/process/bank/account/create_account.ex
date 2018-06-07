import Helix.Process

process Helix.Universe.Bank.Process.Bank.Account.AccountCreate do

  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount

  process_struct [:atm_id]

  @process_type :bank_create_account

  @type t :: %__MODULE__{}

  @type creation_params :: %{}

  @type objective :: %{cpu: resource_usage}

  @type resource :: %{
    objective: objective,
    static: map,
    l_dynamic: [:cpu],
    r_dynamic: []
  }

  @type resources_params :: %{}

  @spec new(creation_params) :: t
  def new do
    %__MODULE__{}
  end

  @spec resources(resource_params) :: resources
  def resources(params = %{}),
    do: get_resources params

  processable do

    alias Helix.Universe.Bank.Event.Bank.Account.AccountCreate.Processed,
      as: AccountCreateProcess

    on_completion(process, data) do
      event = AccountCreateProcess.new(process, data)

      {:delete, [event]}
    end
  end

  resourceable do

    alias Helix.Universe.Bank.Process.Bank.Account.AccountCreate,
      as: AccountCreateProcess

    @type params :: AccountCreateProcess.resources_params
    @type factors :: term

    # TODO proper balance
    get_factors(%{}) do end

    cpu(_) do
      1
    end

    dynamic do
      [:cpu]
    end

    executable do

      alias Helix.Universe.Bank.Process.Bank.Account.AccountCreate,
        as: AccountCreateProcess

      @type params :: AccountCreateProcess.creation_params

      @type meta ::
        ${
          optional(atom) => term
        }

      resources(_, _, %{}) do
        %{}
      end
    end
  end
end
