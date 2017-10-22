defmodule Helix.Factor.Client do
  @moduledoc """
  The Factor.Client is an API for fetching an arbitrary number of Factors.

  Surely you could call the Factor's `assembly/3` method directly, but this API
  provides some helpers :-).
  """

  alias Helix.Factor.Client.Utils, as: FactorClientUtils

  @doc """
  Generates a `get_factors/1` function which will call one or more factors.

  Each factor called is defined on the `do` block, using the `factor/3` macro.

  Just like it happens with the `Helix.Factor` macros, here we also accumulate
  the `relay` and `factors` vars automatically. This means that the returned
  `relay` of one Factor will be used as input to another one.

  Beware that, while this is good for most cases, you might want to shape/modify
  the relay before calling the next `factor`. Read more about this on the
  `Handling relay data` section of `Helix.Factor`.
  """
  defmacro get_factors(params, do: block) do
    quote do

      @spec get_factors(map) ::
        map
      def get_factors(unquote(params)) do
        var!(relay) = %{}
        var!(factors) = %{}

        unquote(block)

        var!(relay)  # Just to mark as used

        # Returns the accumulated factors
        Map.delete(var!(factors), :__struct__)
      end

    end
  end

  @doc """
  Calls the factor's `assembly/3` module. It passes the accumulated relay, which
  may contain relay data from upstream returns from `factor`.

  It accepts the `only` and `skip` options, which enables the user to execute
  (or avoid execution of) specific facts.
  """
  defmacro factor(module, params, opts \\ quote(do: [])) do
    all_facts = FactorClientUtils.get_all_facts(module, __CALLER__)
    factor_name = FactorClientUtils.get_factor_name(module, __CALLER__)
    executable = FactorClientUtils.build_executable(opts, all_facts)

    quote do
      # Call module's `assembly/3`
      condition = Keyword.get(unquote(opts), :if, true)

      {new_factors, new_relay} =
        if condition do
          {factor, next_relay} =
            unquote(module).assembly(
              unquote(params),
              var!(relay),
              unquote(executable)
            )

          factor_key = Keyword.get(unquote(opts), :as, unquote(factor_name))
          factor = Map.put(%{}, factor_key, factor)

          merged_factor = Map.merge(var!(factors), factor)
          merged_relay = Map.merge(var!(relay), next_relay)

          {merged_factor, merged_relay}
        else
          {var!(factors), var!(relay)}
        end

      var!(factors) = new_factors
      var!(relay) = new_relay
    end
  end

  defmodule Utils do
    @moduledoc """
    Utils for `Factor.Client`.
    """

    alias HELL.Utils

    @doc """
    Retrieve the Factor's name.
    """
    def get_factor_name(module, caller) do
      caller.module
      |> Module.eval_quoted(quote(do: unquote(module).get_name()))
      |> elem(0)
    end

    @doc """
    Helper to get all facts defined by `module`.

    It uses a trick from Module's `eval_quoted`. Shh!
    """
    def get_all_facts(module, caller) do
      caller.module
      |> Module.eval_quoted(quote(do: unquote(module).get_facts()))
      |> elem(0)
    end

    @doc """
    Based on all the facts declared on the module, and the given `only` and
    `skip` opts, figure out which facts should be executed.
    """
    def build_executable([], _),
      do: :all
    def build_executable(opts, facts) do
      only = opts[:only] || facts
      skip = opts[:skip]

      only = Utils.ensure_list(only)
      skip = Utils.ensure_list(skip)

      # Checks whether the user specified an invalid fact name
      Enum.any?(only, &(&1 not in facts)) && raise error_msg(:only)
      Enum.any?(skip, &(&1 not in facts)) && raise error_msg(:skip)
      skip == facts && raise error_msg(:wtf)

      executable =
        facts
        |> Enum.filter(&(&1 in only))
        |> Enum.reject(&(&1 in skip))

      if executable == facts do
        :all
      else
        executable
      end
    end

    defp error_msg(:wtf),
      do: "You are skipping literally ALL facts of the given Factor!"
    defp error_msg(field),
      do: "Undefined fact specified on `#{field}`"
  end
end
