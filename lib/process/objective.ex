defmodule Helix.Process.Objective do
  @moduledoc """
  `Process.Objective` is a DSL to calculate how many resources, for each type of
  hardware resource, a process should use.

  It builds upon `Helix.Factor` and its `FactorClient` API, which will
  efficiently retrieve all data you need to figure out the correct resource
  usage for that process.

  Once you have the factors, each resource will be called:

  - cpu (Processor usage)
  - ram (Memory usage)
  - dlk (Downlink usage)
  - ulk (Uplink usage)

  You must specify at least one resource. You can specify them with the namesake
  macros `cpu`, `ram`, `dlk` and `ulk`.

  These resource blocks should return either `nil` or an integer that represents
  how much the process should work - its objectives.

  The resource blocks argument is the `params` specified at Process's top-level
  `objective/n`. On top of that, within the block scope you have access to the
  `f` variable, which is a map containing all factors returned from the
  `get_factors` function you defined beforehand.

  ### Usage example

  ```
  process_objective do

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

  @resources [:dlk, :ulk, :cpu, :ram]

  @doc """
  We have to `use` `Helix.Process.Objective` so we can verify
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
    for resource <- unhandled_resources do
      quote do

        @doc false
        def calculate(unquote(resource), _, _),
          do: 0

      end
    end
  end

  @doc """
  Top-level macro for `Process.Objective`.

  Automatically imports `Helix.Factor.Client`; also defines the `calculate/2`
  flow which will be called from `Helix.Process`.
  """
  defmacro process_objective(do: block) do
    quote do
      defmodule Objective do

        use Helix.Process.Objective

        import Helix.Factor.Client

        @spec calculate(params, factors) ::
          objectives :: map
        def calculate(params, factors) do
          %{
            cpu: calculate(:cpu, params, factors) || 0,
            ram: calculate(:ram, params, factors) || 0,
            dlk: calculate(:dlk, params, factors) || 0,
            ulk: calculate(:ulk, params, factors) || 0
          }
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

  # Actually generate the resources' macros
  docp """
  Generates the macros for each resource.

  It returns a "global", unhygienic variable `f`, which contains the factors
  retrieved on the `get_factors/1` macro from `Helix.Factor.Client`.
  """
  defp set_resource(resource, params, block \\ nil) do
    quote do

      # Notify resource is being handled; will be used later on `before_compile`
      Module.put_attribute(__MODULE__, :handled_resources, unquote(resource))

      def calculate(unquote(resource), unquote(params), factors) do
        # Assigns variable `f` to caller's scope
        var!(f) = factors

        var!(f)  # Marks the variable as used

        unquote(block)
      end

    end
  end
end
