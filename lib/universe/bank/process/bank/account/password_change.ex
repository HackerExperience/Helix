import Helix.Process

process Helix.Universe.Bank.Process.Bank.Account.ChangePassword do

  process_struct []

  @process_type :bank_change_password

  @type t ::
    %__MODULE__{}

  @type creation_params ::
    %{}

  @type objective :: %{cpu: resource_usage}

  @type resources ::
  %{
    objective: objective,
    static: map,
    l_dynamic: [:cpu],
    r_dynamic: []
  }

  @type resources_params ::
  %{}

  @spec new(creation_params) ::
  t
  def new(%{}) do
    %__MODULE__{}
  end

  @spec resources(resources_params) ::
  resources
  def resources(params = %{}),
    do: get_resources params

  processable do

    alias Helix.Universe.Bank.Event.ChangePassword.Processed,
      as: ChangePasswordProcessedEvent

    on_completion(process, data) do
      event = ChangePasswordProcessedEvent.new(process, data)

      {:delete, [event]}
    end
  end

  resourceable do

    alias Helix.Universe.Bank.Process.Bank.Account.ChangePassword,
      as: ChangePasswordProcess

    @type params :: ChangePasswordProcess.resources_params
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

    alias Helix.Universe.Bank.Process.Bank.Account.ChangePassword,
      as: ChangePasswordProcess

    @type params :: ChangePasswordProcess.creation_params

    @type meta ::
    %{
      optional(atom) => term
    }

    resources(_gateway, _atm, %{}, _meta) do
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
