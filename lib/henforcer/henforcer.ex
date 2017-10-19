defmodule Helix.Henforcer do
  @moduledoc """
  # The Henforcer Architecture & Standard

  Henforcer modules follow a custom standard. The purpose of an Henforcer is to
  verify whether the assumptions about the given object/element are valid. In
  order to do so in a maintainable way, we must follow a standard.

  First, keep in mind that Henforcer functions are meant to serve as building
  blocks of different Henforcer functions of possibly different modules.

  Hence, one Henforcer function must commit to verify what it's supposed to and
  absolutely nothing else. If a different verification must be done, it should
  delegate to a more specific Henforcer.

  For instance, suppose we want to check a storage has enough unused space to
  have a file copied to it. First, we make sure both the storage and the file
  exists. Then, we get the free space of the storage and check whether it is
  less than or equal to the file size.

  Now let's say we want to check whether a file can be downloaded. Among other
  things, it must henforce the storage has enough space, in which case the
  previous function would be called, creating the "building blocks" mentioned.

  If we naively fetch the related object from the database during every check,
  it's easy to see we would have a huge and needless overhead very soon. The
  solution to this problem, within the Henforcer scope, is to:

  1) When an Henforcer receives a parameter representing an object, it may be
  either the object ID (type `Object.ID`) or the object itself (type `Object.t`)
  If it's an ID, the Henforcer can assume this object hasn't been verified yet,
  and should check for its existence. Otherwise, if the received param is
  already the object that lives in the database, the Henforcer can proceed to
  verify the object assuming it has already been verified on a prior moment.

  2) Every time an Henforcer fetches some related data from the DB, it must
  pass it upstream (i.e. to the caller), by setting an extra argument on the
  method return. We call this extra argument `relay`, as if the Henforcer was
  relaying this related information to the caller, all the way to the top,
  reaching the very first Henforce-block that was called.

  If the described standard described here is followed, we'll be able to have
  an Henforcer system that is:

  - Maintainable
  - Extensible
  - Efficient
  - Reliable

  So pay close attention any time you are working with Henforcer :)

  ## Method names

  Henforcer methods must have an intuitive name, which make it clear what is
  being verified. Any Henforcer method may make several other implicit
  checks. This is not a problem as long as the above architecture is followed
  correctly.

  Henforcer names must finish with a question mark, like `can_download?` or
  `exists?`. Make sure to read the "Return types" section

  ## Return types

  In case of success, an Henforcer must return:

  `{true, relay :: map}`

  In case of failure, an Henforcer must return:

  `{false, reason, relay :: map}`

  Notice that the return type is a tuple, not a boolean, which one could think
  of, since it's an Elixir/Ruby convention for methods ending with a question
  mark. Keep this in mind.

  ## Composable types

  Since one Henforcer may rely on implicit checking of an arbitrarily large
  number of other Henforcers, it would become a nightmare having to maintain
  all possible types of return for errors and relays. As such, we've devised
  a pattern to make typespecs readable, composable and manageable.

  Each Henforcer has a type `<henforcer_name>_error`, which lists all possible
  error returns. Its typespec must include each sub-henforcer error type,
  accumulating it in a fractal way.

  Likewise, each Henforcer has a type `<henforcer_name>_relay` and
  `<henforcer_name>_relay_partial`, which point to the returned relay in case of
  success, and any possible partial relay in case of failure, respectively.

  Here's an example:

  ```

  @type is_a_relay :: %{foo: :bar, relay: :b}
  @type is_a_relay_partial :: %{}

  @type is_a_error ::
    {false, {:not, :a}, is_a_relay_partial}
    | is_b_error
    | is_c_error

  @spec is_a?(x, y) ::
    {true, is_a_relay}
    | is_a_error
  def is_a?(x, y) do
    with \
      {true, r1} <- is_b?(x),
      {true, r2} <- is_c?(y)
    do
      reply_ok(relay([r1, r2, %{foo: :bar}]))
    _ ->
      reply_error({:not, :a})
    end
  end

  @type is_b_relay :: %{relay: :b}
  @type is_b_relay_partial :: %{}
  @type is_b_error ::
    {false, {:not, :b}, is_b_relay_partial}
    | can_d_error

  @spec is_b?(x) ::
    {true, is_b_relay}
    | is_b_error
    | can_d_error
  def is_b?(x)

  def is_c?(y)

  def can_d?(z)

  ```

  Notice on the example above we have the top-level henforcer `is_a?`, which
  checks for `is_b?` and `is_c?`. Implicitly, `is_b?` also checks for `can_d?`.
  Now, analyze the types and typespec of `is_a`. Notice it:

  - accumulates all previous relays
  - accumulates all previous errors returns
  - without having knowledge of the implementation of the sub-henforcers.

  This can be achieved as long as each Henforcer typespec covers all possible
  return errors.

  One Henforcer may add at most ONE additional error (the `{false, {:a, :b}, _}`
  line). If it defines two or more errors, the Henforcer is performing two
  checks, and as mentioned on the beginning of this documentation, one Henforcer
  is supposed to check one thing and only one thing.

  On the other hand, one henforcer may call n sub-henforcers, in which case each
  henforcer called must have its corresponding `_error` type added to the
  caller's `_error` type.

  Unfortunately, the accumulation of `_relay` and `_relay_partial` must be done
  manually, i.e. checking each called henforcer and making sure the relayed
  value is passed upstream.

  Notice that Henforcers may shape the relay field as they like. For instance,
  the `server_exists?` verification returns a %{server: Server.t} relay,
  while the `can_transfer?` returns %{gateway: Server.t, target: Server.t}
  relay. This is required because `can_transfer?` has a context in which the
  key `server` is ambiguous.

  ## Legacy Henforcer

  Henforcer is relatively old, so you may find some methods/functions that do
  not follow this standard. If this happens,

  1) Do not panic.
  2) Mind the gap.
  3) If you are using the Legacy henforcer as a building block, fix it.
  4) Otherwise, you can ignore it.
  """

  # Note to self: We are currently using `generated: true` on quotes to avoid
  # elixir-lang bug #6426; the `generated: true` is a trick suggested by Valim
  # here: https://github.com/elixir-lang/elixir/pull/6577.
  # It is, however, a band-aid solution, and should be removed once the bug gets
  # fixed.

  @doc """
  The `henforce` macro is a shorthand to:

  ```
  with {true, relay} <- henforce_something() do
    henforce_something_else()
  else
    error ->
      error
  end

  ```

  It can be used to easily create building blocks on top of other henforcers.

  The generated `relay` variable is accessible outside the macro scope, i.e.
  within the caller's body
  """
  defmacro henforce(function, do: block) do
    quote generated: true do

      with {true, var!(relay)} <- unquote(function) do
        wrap_relay unquote(block), var!(relay)
      else
        not_found ->
          not_found
      end

    end
  end

  @doc """
  Negates the sub-henforcer result.
  """
  defmacro henforce_not(function, reason) when is_tuple(reason) do
    quote generated: true do
      case unquote(function) do
        {true, relay} ->
          {false, unquote(reason), relay}
        {false, _reason, relay} ->
          {true, relay}
      end
    end
  end

  @doc """
  `henforce_else/2` is useful when you want to delegate the henforcer check to
  an already existing henforcer, but you want to customize the error returned.

  ### Example:

  ```
  # Returns {:cant, :x} if `can_Y` verification fails.
  def can_X?(a) do
    henforce_else(can_Y, {:cant, :x})
  end

  def can_Y(b) do
    if something() do
      reply_ok()
    else
      reply_error({:cant, :y})
    end
  end

  ```
  """
  defmacro henforce_else(function, reason) when is_tuple(reason) do
    quote generated: true do
      case unquote(function) do
        result = {true, _} ->
          result

        {false, _, relay} ->
          {false, unquote(reason), relay}
      end
    end
  end

  @doc """
  Helper to format the return data in case of success
  """
  defmacro reply_ok(relay \\ quote(do: %{})) do
    quote do
      {true, unquote(relay)}
    end
  end

  @doc """
  Helper to format the return data in case of failure
  """
  defmacro reply_error(reason, relay \\ quote(do: %{})) do
    quote do
      {false, unquote(reason), unquote(relay)}
    end
  end

  @doc """
  `relay/1` and `relay/2` are simple utilities to generating a new relay map
  from existing ones. Notice it does not set an externally accessible `relay`
  variable, like `henforce/2` does. It simply generates (returns) the new relay
  map.
  """
  defmacro relay(list_m) when is_list(list_m) do
    quote do
      Enum.reduce(unquote(list_m), %{}, fn m, acc ->
        Map.merge(acc, m)
      end)
    end
  end
  defmacro relay(m1) do
    quote do
      unquote(m1)
    end
  end

  defmacro relay(m1, m2) do
    quote do
      Map.merge(unquote(m1), unquote(m2))
    end
  end

  @doc """
  "Wraps" the sub-henforcer relay into our current relay. In other words, it
  accumulates the relay.
  """
  defmacro wrap_relay(henforcer, relay) do
    quote generated: true do
      case unquote(henforcer) do
        {true, sub_relay} ->
          {true, relay(unquote(relay), sub_relay)}
        {false, reason, sub_relay} ->
          {false, reason, relay(unquote(relay), sub_relay)}
      end
    end
  end

  @doc """
  Helper for when a sub-relay may have conflicting keys, in which case the
  current henforcer must

  1. Temporarily store the value
  2. Remove the "conflictable" key
  3. Assign the value to a new, conflict-less key.

  This function makes all 3 steps in a single line (for the macro caller).

  For a function that only performs the first two, check out `get_and_drop/2`.
  """
  defmacro replace(relay, cur_key, next_key) do
    quote do
      {new_relay, value} = get_and_drop(unquote(relay), unquote(cur_key))

      Map.put(new_relay, unquote(next_key), value)
    end
  end

  @doc """
  Gets the relay value on `key` and removes it from the relay.

  Returns the new relay (without the key) and the value that was inside the key.

  Useful for when you have conflicting keys on a higher-level context. For an
  example, check `FileHenforcer.Transfer.can_transfer?`
  """
  defmacro get_and_drop(relay, key) do
    quote do
      value = Map.get(unquote(relay), unquote(key))

      {Map.delete(unquote(relay), unquote(key)), value}
    end
  end

  @doc """
  Same as `replace/3`, but also returns the value that was on `cur_key`.
  """
  defmacro get_and_replace(relay, cur_key, next_key) do
    quote do
      {new_relay, value} = get_and_drop(unquote(relay), unquote(cur_key))

      {Map.put(new_relay, unquote(next_key), value), value}
    end
  end
end
