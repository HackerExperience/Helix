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
  - Calculating difficulties, rewards, penalties based on, well, game factors.

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
  get_fact :resources
  get_fact :type
  get_fact :uptime
  get_fact: processes
  get_fact :location
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

  Yeah right

  ### Handling relay data

  TODO

  ### Peculiarities, dangers, gotchas and bewares

  Using a DSL is a joy as long as you are fully aware of everything it does
  under the hood. There's (relatively) a lot we've abstract from the surface, so
  here's a few things to keep in mind:

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

  ##### There's an even more special variable called `factors`

  On the example above, you can now (hopefully) understand why `relay` is being
  accumulated. But how about the Factor result?

  Well, it is accumulated on an internal variable called `factors`. You need not
  worry with it, and theoretically there's no possibility of key conflicts like
  `relay`, since `factors` is a map which is accumulating the Factor struct's
  response.

  In other words, each fact result will populate the `factors` map under the key
  with the same name of the fact. Under the hood, `factors` is automatically
  accumulated on every `get_fact` call.

  On the last `get_fact` call, the `factors` is a map identical to the struct,
  except for the `__struct__` keyword! Then we simply add the `__struct__` key
  and voila, we have our final result, a valid Factor struct with all underlying
  facts and children (sub-Factors) queried in a fractal/hierarchical way.
  """

  import HELL.Macros

  @doc """
  Top-level macro for a Factor implementation. Pure syntactic sugar.
  """
  defmacro factor(name, do: block) do
    quote do

      defmodule unquote(name) do
        unquote(block)
      end

    end
  end

  @doc """
  Creates the Factor struct definition.
  """
  defmacro factor_struct(keys) do
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

        defdelegate unquote(:"fact_#{name}")(params, relay),
        to: unquote(child_module),
        as: :assembly

      end
    end)
  end

  @doc """
  Generates the `assembly/2` function, which will guide the Factor data flow.
  """
  defmacro assembly(params, relay \\ quote(do: %{}), do: block) do
    assembler =
      quote do
        struct =
          var!(factors)
          |> Map.put(:__struct__, __MODULE__)

        {struct, var!(relay)}
      end

    quote do

      @spec assembly(params, relay :: term) ::
        {factor, relay}
      def assembly(unquote(params), unquote(relay) \\ %{}) do
        var!(factors) = %{}
        unquote(block)
        unquote(assembler)
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
      {unquote(fact), unquote(relay)}
    end
  end

  @doc """
  Function used by `assembly/2` to call the Factor's facts and children.

  This is where most of the "under-the-hood" magic happens, by automatically
  accumulating the `relay` and `factors` variables.
  """
  defmacro get_fact(name) do
    quote do
      get_fact(unquote(name), var!(params), var!(relay))
    end
  end

  defmacro get_fact(name, params, relay) do
    fname = :"fact_#{name}"
    quote do
      # Calls `fact_#{name}`
      {fact, next_relay} = unquote(fname)(unquote(params), unquote(relay))

      result = Map.put(%{}, unquote(name), fact)

      # Puts the result of `fact_#{name}` on the `factors` accumulators, under
      # the `#{name}` key. Also accumulates the returned relay. Both `factors`
      # and `relay` are unhygienic variables that will be used later, during
      # the final assembly steps.
      var!(factors) = Map.merge(var!(factors), result)
      var!(relay) = Map.merge(var!(relay), next_relay)
    end
  end

  @spec get_child_module(parent :: atom, child_name :: String.t) ::
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
