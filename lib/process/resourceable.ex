defmodule Helix.Process.Resourceable do
  @moduledoc """
  # Resourceable

  `Process.Resourceable` is a DSL to calculate how many resources, for each type
  of hardware resource, a process should use. This usage involves:

  - Figuring out the process' objective, the total amount of work a process
    should perform before being deemed completed.
  - How many resources the project should allocate statically, whether it's
    paused or running.
  - What resources can be dynamically allocated, according to the server's total
    available resources.

  It builds upon `Helix.Factor` and its `FactorClient` API, which will
  efficiently retrieve all data you need to figure out the correct resource
  usage for that process.

  Once you have the factors, each resource will be called:

  ### Objective

  - cpu (Processor usage)
  - ram (Memory usage)
  - dlk (Downlink usage)
  - ulk (Uplink usage)

  You must specify at least one resource. You can specify them with the namesake
  macros `cpu`, `ram`, `dlk` and `ulk`.

  These resource blocks should return either `nil` or an integer that represents
  how much the process should work - its objectives.

  ### Allocation:

  - static(params, factors) -- Specifies static resource allocation 
  - dynamic(params, factors) -- List of dynamically allocated resources

  The resource blocks argument is the `params` specified at Process's top-level
  `objective/n`. On top of that, within the block scope you have access to the
  `f` variable, which is a map containing all factors returned from the
  `get_factors` function you defined beforehand.

  # Usage example

  ```
  resourceable do

    @type params :: %{type: :download | :upload}

    @type factors :: %{size: integer}

    # Gets all the data I need
    get_factors(params) do
      factor Helix.Software.Factor.File, params, only: :size
    end

    # Specifies the Downlink usage if it's a download
    dlk(%{type: :download}) do
      f.file.size  # Variable `f` contains the results of `get_factors`
    end

    # Specifies the Uplink usage if it's an uplink
    ulk(%{type: :upload}) do
      f.file.size
    end

    # Safety fallbacks (see section below)
    dlk(%{type: :upload})
    ulk(%{type: :download})

    # Static allocation

    static do
      %{paused: %{ram: 50}}
    end

    # Dynamic allocation
    dynamic(%{type: :download}) do
      [:dlk]
    end

    dynamic(%{type: :upload}) do
      [:ulk]
    end
  end
  ```

  ### Safety fallback

  When pattern match params within `Process.Objective`, like the example above,
  you are required to match against all possible input values.

  While putting a `dlk(_)` would suffice, it's better to be explicit on which
  fallbacks should return a `nil` usage, like we do on the example above.

  This way, a small typo on the pattern match, like `dlk(%{type: :downlaod})`,
  would blow up, instead of returning a silent bug that would allow players to
  download files instantaneously :-).
  """

  import HELL.Macros

  alias Helix.Process.Model.Process

  @type resource :: Process.resource
  @type resource_usage :: number

  @resources [:dlk, :ulk, :cpu, :ram]

  @doc """
  We have to `use` Resourceable so we can perform some compile-time checks.
  """
  defmacro __using__(_args) do
    quote do

      import unquote(__MODULE__)

      Module.register_attribute(
        __MODULE__,
        :handled_resources,
        accumulate: true
      )

      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  Perform some verifications and fallbacks.
  """
  defmacro __before_compile__(_env) do
    handled_resources =
      Module.get_attribute(__CALLER__.module, :handled_resources)
    unhandled_resources = @resources -- handled_resources

    # Blows up if module is defined but there are no resource handlers declared
    if Enum.empty?(handled_resources),
      do: raise "Missing resource handlers for #{__CALLER__.module}"

    # Declares handlers for unused resources (only the ones who were not
    # defined; see "Safety Fallbacks" section on moduledoc for more info.)
    fallback_objective =
      for resource <- unhandled_resources do
        quote do

          @doc false
          def calculate(unquote(resource), _, _),
            do: 0

        end
      end

    # Fallbacks in case the user did not specify static and dynamic allocations
    fallback_allocations =
      quote do
        @doc false
        def static(_, _),
          do: %{}

        @doc false
        def l_dynamic(_, _),
          do: []

        @doc false
        def r_dynamic(_, _),
          do: []

        @doc false
        def set_network(_, _),
          do: nil
      end

    [fallback_allocations, fallback_objective]
  end

  @doc """
  Top-level macro for `Process.Resourceable`.

  Automatically imports `Helix.Factor.Client`; also defines the `calculate/2`
  flow which will be called from `Helix.Process`.
  """
  defmacro resourceable(do: block) do
    quote location: :keep do
      defmodule Resourceable do

        use Helix.Process.Resourceable

        import Helix.Factor.Client

        # Defining the typespecs below outside of the macro/loop because it
        # could be defined multiple times, raising dialyzer's overloaded
        # contract warning.
        @spec calculate(atom, params, factors) ::
          Helix.Process.Resourceable.resource_usage | term  # elixir-lang 6426

        @spec static(params, factors) ::
          Process.static

        @spec l_dynamic(params, factors) ::
          Process.dynamic

        @spec r_dynamic(params, factors) ::
          Process.dynamic

        @spec calculate(params, factors) ::
          objectives :: map
        @doc """
        Coordinates the calculation of each hardware resource objective based on
        the given `params` and `factors`.

        It removes any non-objective (when required resource usage is 0).
        """
        def calculate(params, factors) do
          network_id = set_network(params, factors)

          {dlk, ulk} =
            if network_id do
              dlk = calculate(:dlk, params, factors)
              ulk = calculate(:ulk, params, factors)

              dlk = Map.put(%{}, network_id, dlk)
              ulk = Map.put(%{}, network_id, ulk)

              dlk =
                dlk
                |> Enum.filter(fn {_net_id, val} ->
                  is_number(val) && val > 0
                end)
                |> Map.new()

              ulk =
                ulk
                |> Enum.filter(fn {_net_id, val} ->
                  is_number(val) && val > 0
                end)
                |> Map.new()

              {dlk, ulk}
            else
              {%{}, %{}}
            end

          %{
            cpu: calculate(:cpu, params, factors),
            ram: calculate(:ram, params, factors),
            dlk: dlk,
            ulk: ulk
          }
          |> Enum.reject(fn {_, total} -> total == %{} end)
          |> Enum.reject(fn {_, total} -> total == 0 end)
          |> Map.new()
        end

        unquote(block)
      end
    end
  end

  # Defines the macros which the programmer can use to specify the objectives.
  for resource <- @resources do
    defmacro unquote(resource)(params, do: block),
      do: set_resource(unquote(resource), params, block)

    defmacro unquote(resource)(do: block),
      do: set_resource(unquote(resource), quote(do: _params), block)

    # Used for safe fallbacks: non-catch-all fail-safe of pattern match
    defmacro unquote(resource)(fallback),
      do: set_resource(unquote(resource), fallback)
  end

  # Special macro used to determine the process' network
  defmacro network(params, do: block) do
    quote do

      def set_network(unquote(params), factors) do
        # Special variable `f` holds previously calculated `factors`
        var!(f) = factors

        var!(f)  # Mark as used

        unquote(block)
      end

    end
  end

  docp """
  Generates the macros for each resource.

  It returns a "global", unhygienic variable `f`, which contains the factors
  retrieved on the `get_factors/1` macro from `Helix.Factor.Client`.
  """
  defp set_resource(resource, params, block \\ nil) do
    quote do

      # Notify resource is being handled; will be used later at `before_compile`
      Module.put_attribute(__MODULE__, :handled_resources, unquote(resource))

      def calculate(unquote(resource), unquote(params), factors) do
        # Assigns variable `f` to caller's scope
        var!(f) = factors

        var!(f)  # Marks the variable as used

        unquote(block)
      end

    end
  end

  defmacro static(params, do: block),
    do: set_static(params, block)
  defmacro static(do: block),
    do: set_static(quote(do: _params), block)

  defp set_static(params, block) do
    quote do

      def static(unquote(params), factors) do
        # Assigns variable `f` to caller's scope
        var!(f) = factors

        var!(f)  # Mark as used

        unquote(block)
      end

    end
  end

  @doc """
  Set which resources the process may allocate dynamically on the remote server.
  """
  defmacro r_dynamic(params, do: block),
    do: set_r_dynamic(params, block)
  defmacro r_dynamic(do: block),
    do: set_r_dynamic(quote(do: _params), block)

  defp set_r_dynamic(params, block) do
    quote do

      def r_dynamic(unquote(params), factors) do
        # Assigns variable `f` to caller's scope
        var!(f) = factors

        var!(f)  # Mark as used

        unquote(block)
      end

    end
  end

  @doc """
  Set which resources the process may allocate dynamically on the local server.
  """
  defmacro dynamic(params, do: block),
    do: set_dynamic(params, block)
  defmacro dynamic(do: block),
    do: set_dynamic(quote(do: _params), block)

  defp set_dynamic(params, block) do
    quote do

      def l_dynamic(unquote(params), factors) do
        # Assigns variable `f` to caller's scope
        var!(f) = factors

        var!(f)  # Mark as used

        unquote(block)
      end

    end
  end
end
