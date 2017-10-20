defmodule Helix.Factor do
  @moduledoc """
  # Helix Factor

  The Helix Factor is a DSL for building blocks of fact-collecting methods. As
  a whole, a Factor is meant to gather facts from the object and context it is
  working on.

  Factor is very useful when you want to gather little pieces of information,
  potentially from several different contexts, in an efficient, maintainable,
  composable and readable way.

  Namely, the main two use-cases for Factors within Helix are:

  - Figuring out how long a process should take.
  - Calculating difficulties, rewards, penalties based on, well, game facts.

  One could split the implementation of a game design and balance in two parts:

  1. Gathering of all required variables to calculate the outcome.
  2. Calculate the outcome.

  In short, Factor is responsible for the first part. 

  Notice how splitting the game design implementation into two logical steps can
  benefit us: testing the outcome of a calculation, or experimenting with new
  equations is as simple as passing the raw data, which represents the facts.

  In doing so, we've essentially decoupled the collection of the data from the
  calculations of balance and design.

  ### The Factor DSL

  The Factor DSL was designed to be:

  - composable
  - efficient
  - readable
  - maintainable

  If we've failed on any of these topics, it is a bug!

  ### Efficient fact-gathering

  The first and most challenging aspect of overall game balance implementation
  is to find a way to gather whatever data you need in an efficient way. This is
  specially more important if your data is located on a Database server rather
  than your nearest memory.

  As such, we consider a mistake having to query the database for the same
  dataset more than once. To solve this problem, we've adopted a similar
  solution to `Helix.Henforcer`: relays.

  A relay is a map of all data that has been queried. It is accumulated over the
  lifecycle of a Factor, and is passed on to sub-Factors and to whoever called
  the Factor.

  The result is that, *if correctly implemented*[1], the method need not perform
  duplicate queries if the required data has already been queried.

  [1] - For more information on how to implement it correctly, see section
  `Handling relay data` below.

  ### Factor Hierarchy

  Let's start with an example. Suppose we want to gather facts about a server.
  Under this context, there may have multiple facts I'd like to check:

  - how much CPU power I have available?
  - do I have enough HD storage?
  - is this server a desktop or a mobile phone?
  - what is the distance from this server to that other server?
  - what is the uptime of the server?
  - how many processes are there on the server?

  That's just for starters! Now, one could shape the above data in an hierarchic
  fashion:

  ```
  %{
    resources: %{
      cpu: %{used: _, free: _, total: _}
      hdd: %{used: _, free: _, total: _}
    },
    type: :desktop | :mobile,
    uptime: _,
    processes: %{total: _}
    location: %{
      distance: _
    }
  }
  ```

  Nice, right? See the pattern? We can break down this fact-gathering into
  smaller pieces, like the `Server.ResourceFactor` and `Server.LocationFactor`.

  These smaller pieces are fully independent Factors, which are completely
  unaware of who is calling them - as long as the correct parameters are used.

  This enables a great deal of composability, but that's not the biggest benefit
  here (since these sub-Factors would likely only be used by Server). The main
  benefit is that testing those smaller Factors is a lot more doable!

  Anyway, back to the topic. On our Factor DSL, these sub-Factors are called
  `children`. On the other hand, facts that are defined by our Factor, like
  the server `uptime` or `type`, are called.... `facts`.

  You use the `child/1` macro to declare the former, and the `fact/4` macro for
  the later.

  ### Setting and getting facts

  When you are defining a fact (under the `fact/4` macro), you must return the
  value corresponding to the fact, alongside the accumulated `relay`.

  For this, use the `set_fact/2` macro. It allows you to accumulate the relay
  in a very readable way.

  If you want to get a fact, use the `get_fact/1` macro. This must happen within
  the `assembly/2` macro.

  ### Assembling everything together

  Don't we all love to assembly? The purpose of `assembly/2` is pretty
  straightforward: you need to guide the data flow from the first fact checking
  to the last one. On the meantime, you may want to modify the keys of a relay
  in order to avoid conflicts (see `Handling relay data` section).

  This all happens during the `assembly/2` macro.

  If there's no need to handle potentially conflicting relay keys, you'll end up
  with a simple interface like:

  ```
  assembly(params, relay) do
    get_fact :resources
    get_fact :type
    get_fact :uptime
    get_fact: processes
    get_fact :location
  end
  ```

  That's all there is to it!

  ### Types

  As big fans of Dialyzers, we would never let you implement a Factor without
  specifying the underlying functions specs!

  Here's our convention:

  - **params** - Specify which params the `assembly/2` function should receive.
    Must always be a map.
  - **factor** - Specify the Factor return. It's always the __MODULE__'s struct.
  - **relay** - Specify the relay passed as parameter for `assembly/2`. Defaults
    to an empty map when not specified.

  Typespecs for `fact_*` functions are TODO.

  ### Testing

  In order to test the return of a Factor, you may either use the client API
  defined at `Helix.Factor.Client`, or call directly `assembly/3`, where the
  last argument is the list of facts that should be retrieved. If omitted, all
  facts will be retrieved.

  ### Handling relay data

  #### For conflicts

  On Henforcer, it's quite common to have conflicting relay keys. This happens
  once you have a sub-Henforcer without context, and a parent-Henforcer with
  context. For example, imagine the `can_transfer?` Henforcer. Its context has
  two servers, `source` and `target`. Each one will be verified with the
  `server_exists?` henforcer, which will return a contextless `%{server: _}`
  relay. It's up to the parent Henforcer to shape the relay, otherwise the key
  `server` would be overwritten on the second verification.

  This is a lot less likely to happen on Factor, since we usually have only a
  single context per Factor. Still, it's useful to keep that in mind.

  (In fact, that's why relay handling is done under the hood on `Factor`, and
  explicitly on `Henforcer`.)

  So, if a conflict arises, it's possible to modify the `relay` variable
  directly on the `assembly` scope. Beware that, due to alternative flows that
  may be created on `Helix.Factor.Client`, that relay key may not exist some
  times, so an existence check should be made beforehand.

  #### For flexibility

  A sub-factor may be called from an arbitrarily large number of parents, and a
  fact may be called with a custom flow (specified by the `only` and `skip`
  options on `Helix.Factor.Client`).

  That's why, for greater flexibility, one must not assume a fact will always
  have the expected relay data. It should pattern match and, in case the data is
  missing, fetch and pass it upstream.

  This can get quite cumbersome to implement upfront, so as a rule of thumb:

  - Add a fact as usual, pattern-matching the required relay.
  - If, on some alternative execution flow, the fact is reached without the full
    relay, gather the required data and add a pattern-match for this subset.
  - Repeat

  ### Interfacing with Factors

  Yo dawg, we heard you like APIs so we've created an API that interacts with
  the Factor's API.

  Check out `Helix.Factor.Client`.

  ### Peculiarities, dangers, gotchas and bewares

  Using a DSL is a joy as long as you are fully aware of everything it does
  under the hood. There's (relatively) a lot we've abstracted from the surface,
  so here's a few things to keep in mind:

  ##### `relay` is a "special" variable

  Both `assembly/2` and `fact/3` definitions deal with the `relay` parameter.

  Take another look at this assembly block:

  ```
  assembly(params) do
    relay = %{}

    get_fact :resources
    get_fact :type
    get_fact :uptime
    get_fact: processes
    get_fact :location
  end
  ```

  You know that `relay` is accumulated, but how is that possible if it's not
  being passed to the facts below? Worse, how can this function accumulate
  anything at all?

  Yes, the `relay` variable is handled under the hood to be automatically passed
  on to the `get_fact` calls. It is also handled during the `set_fact`, so all
  `fact/4` definitions automatically return the underlying `relay`.

  This accumulation is done automatically for you. You need not worry about it.
  But it's always good to know how it works, hence this section.

  ##### There's an even more special variable called `facts`

  On the example above, you can now (hopefully) understand why `relay` is being
  accumulated. But how about the Factor result?

  Well, it is accumulated on an internal variable called `facts`. You need not
  worry with it, and theoretically there's no possibility of key conflicts like
  `relay`, since `facts` is a map which is accumulating the Factor struct's
  response.

  In other words, each fact result will populate the `facts` map under the key
  with the same name of the fact. Under the hood, `facts` is automatically
  accumulated on every `get_fact` call.

  On the last `get_fact` call, the `facts` is a map identical to the struct,
  except for the `__struct__` keyword! Then we simply add the `__struct__` key
  and voila, we have our final result, a valid Factor struct with all underlying
  facts and children (sub-Factors) queried in a fractal/hierarchical way.
  """

  import HELL.Macros

  @doc """
  We `use` this module so we can accumulate the attributes below and perform
  some compile-time checks.
  """
  defmacro __using__(_args) do
    quote do

      import unquote(__MODULE__)

      Module.register_attribute(
        __MODULE__,
        :facts,
        accumulate: false
      )

      Module.register_attribute(
        __MODULE__,
        :facts_called,
        accumulate: true
      )

      Module.register_attribute(
        __MODULE__,
        :exec_facts,
        accumulate: false
      )

      @before_compile unquote(__MODULE__)
    end
  end

  @doc """
  On this pre-compilation step we perform some verifications to make sure there
  were no mistakes, like a fact that went unhandled by `assembly/4`. We also
  create the `get_facts/0` function, which returns a list of all declared facts.
  """
  defmacro __before_compile__(_env) do
    keys = Module.get_attribute(__CALLER__.module, :facts)
    facts_called = Module.get_attribute(__CALLER__.module, :facts_called)

    # Emits an warning if there are facts not being handled by `assembly/4`.
    unless Enum.sort(keys) == Enum.sort(facts_called) do
      warn_str = \
        "One or more facts of module #{__CALLER__.module} are not being called"
      :elixir_errors.warn __CALLER__.line, __CALLER__.file, warn_str
    end

    # Infer factor name based on module name
    module_name =
      __CALLER__.module
      |> Module.split()
      |> List.last()
      |> String.downcase()
      |> String.to_atom()

    quote do

      @doc """
      Returns a list of all facts checked by this #{__MODULE__}.
      """
      def get_facts do
        @facts
      end

      @doc """
      Returns the name of the Factor.
      """
      def get_name do
        unquote(module_name)
      end

    end
  end

  @doc """
  Top-level macro for a Factor implementation. Pure syntactic sugar.
  """
  defmacro factor(name, do: block) do
    quote do

      defmodule unquote(name) do

        use Helix.Factor

        unquote(block)
      end

    end
  end

  @doc """
  Creates the Factor struct definition.
  """
  defmacro factor_struct(keys) do
    # Stores, at compile-time, the information about which facts are declared.
    Module.put_attribute(__CALLER__.module, :facts, keys)

    quote do
      @enforce_keys unquote(keys)
      defstruct unquote(keys)
    end
  end

  @doc """
  Declares a fact, as well as how it's supposed to retrieve that data.
  """
  defmacro fact(name, params, relay, do: block) do
    fname = :"fact_#{name}"
    quote do

      def unquote(fname)(unquote(params), var!(relay) = unquote(relay)) do
        unquote(block)
      end

    end
  end

  @doc """
  Declares a child, i.e. a sub-Factor. The child name must be the same as the
  child's module name.
  """
  defmacro child(name) when is_atom(name) do
    quote do
      child([unquote(name)])
    end
  end

  defmacro child(children) when is_list(children) do
    Enum.map(children, fn name ->
      child_module = __CALLER__.module |> get_child_module(name)

      quote do

        def unquote(:"fact_#{name}")(params, relay) do
          apply(unquote(child_module), :assembly, [params, relay, :all])
        end

      end
    end)
  end

  @doc """
  Generates the `assembly/3` function, which will guide the Factor data flow.
  """

  defmacro assembly(
    params \\ quote(do: var!(params)),
    relay \\ quote(do: _),
    do: block)
  do
    assemble(params, relay, block)
  end

  docp """
  Actual creation of the `assembly/3` function.
  """
  defp assemble(params, relay, block) do
    quote do

      @spec assembly(params, relay :: term, exec_facts :: [atom] | :all) ::
        {factor, relay}
      def assembly(var!(params) = unquote(params), var!(relay) = unquote(relay), exec) do
        var!(exec_facts) = exec
        var!(facts) = %{}

        unquote(block)

        # Puts `__struct__` info if all facts are being fetched, otherwise
        # simply return the accumulated facts (which is a subset of the struct).
        result =
          if exec == :all do
            Map.put(var!(facts), :__struct__, __MODULE__)
          else
            var!(facts)
          end

        {result, var!(relay)}
      end

    end
  end

  @doc """
  Formats the fetched fact into the format used by `assembly/2`, and passes the
  resulting `relay` upstream.
  """
  defmacro set_fact(fact) do
    quote do
      {unquote(fact), var!(relay)}
    end
  end

  defmacro set_fact(fact, relay) do
    quote do
      var!(relay)  # Marks variable as used
      {unquote(fact), unquote(relay)}
    end
  end

  @doc """
  Function used by `assembly/2` to call the Factor's facts and children.

  This is where most of the "under-the-hood" magic happens, by automatically
  accumulating the `relay` and `facts` variables.
  """
  defmacro get_fact(name) do
    quote do
      get_fact(unquote(name), var!(params), var!(relay))
    end
  end

  defmacro get_fact(name, params, relay) do
    # Accumulate the soon-to-be-called fact to @facts_called attr. Used only at
    # compile time for `assembly/4` macro verification
    Module.put_attribute(__CALLER__.module, :facts_called, name)

    # Define the name of the function we'll be calling
    fname = :"fact_#{name}"

    quote do

      {facts, relay} =
        if :all == var!(exec_facts) or unquote(name) in var!(exec_facts) do
          # Calls `fact_#{name}`
          {fact, next_relay} = unquote(fname)(unquote(params), unquote(relay))

          result = Map.put(%{}, unquote(name), fact)
          {result, next_relay}
        else
          {var!(facts), var!(relay)}
        end

      # Puts the result of `fact_#{name}` on the `facts` accumulators, under
      # the `#{name}` key. Also accumulates the returned relay. Both `facts`
      # and `relay` are unhygienic variables that will be used later, during
      # the final assembly steps.
      var!(facts) = Map.merge(var!(facts), facts)
      var!(relay) = Map.merge(var!(relay), relay)
    end
  end

  @spec get_child_module(parent :: atom, child_name :: atom) ::
    child_module :: atom
  docp """
  Helper to figure out the child's module based on the current Factor (parent).
  """
  defp get_child_module(parent_module, child_name) do
    child_module_name = child_name |> Atom.to_string() |> String.capitalize()

    parent_module
    |> Module.split()
    |> List.insert_at(-1, child_module_name)
    |> Module.concat()
  end
end
