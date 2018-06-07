import Helix.Process

process Helix.Universe.Bank.Process.Bank.Account.AccountClose do

  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount

  process_struct [:account]

  @process_type :bank_close_account

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
  def new(%{}) do
    %__MODULE__{}
  end

  @spec resources(resources_params) :: resources
  def resources(params = %{})
    do: get_resources params

  processable do

    alias Helix.Universe.Bank.Event.AccountClose.Processed,
      as: AccountCloseProcessedEvent

    on_completion(process, data) do
      event = AccountCloseProcessedEvent.new(process, data)

      {:delete, [event]}
    end

    resourceable do
      alias Heli.Universe.Bank.Process.Bank.Account.AccountClose,
        as: AccountCloseProcess

      @type params :: AccountCloseProcess.resources_params
      @type factors :: term

      # TODO proper balance
      get_factors(%{}) do end

      cpu(_) do

      end

      dynamic do
        [:cpu]
      end
    end

    executable do

      alias Helix.Universe.Bank.Process.Bank.Account.AccountClose,
        as: AccountCloseProcess

      @type params :: AccountCloseProcess.creation_params

      @type meta ::
        %{
          optional(atom) => term
        }

      resources(_, _, %{}, _) do
        %{}
      end
    end
  end
