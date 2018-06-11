import Helix.Process

process Helix.Universe.Bank.Process.Bank.Account.AccountCreate do

  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount

  process_struct [:atm_id]

  @process_type :bank_create_account

  @type t :: %__MODULE__{atm_id: ATM.id}

  @type creation_params :: %{atm_id: ATM.id}

  @type objective :: %{cpu: resource_usage}

  @type resources :: %{
    objective: objective,
    static: map,
    l_dynamic: [:cpu],
    r_dynamic: []
  }

  @type resources_params :: %{}

  @spec new(creation_params) :: t
  def new(%{atm_id: atm_id}) do
    %__MODULE__{atm_id: atm_id}
  end

  @spec resources(resources_params) :: resources
  def resources(params = %{}),
    do: get_resources params

  processable do

    alias Helix.Universe.Bank.Event.AccountCreate.Processed,
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

    # TODO: Use Time, not CPU #364
    cpu(_) do
      1
    end

    dynamic do
      [:cpu]
    end
  end

  executable do

    alias Helix.Universe.Bank.Process.Bank.Account.AccountCreate,
      as: AccountCreateProcess

    @type params :: AccountCreateProcess.creation_params

    @type meta ::
      %{
        optional(atom) => term
      }

    resources(_, _, %{}, _) do
      %{}
    end

    source_connection(_gateway, _target, _params, _meta) do
      {:create, :bank_login}
    end
  end
  process_viewable do

    @type data :: %{}

    render_empty_data()
  end
end
