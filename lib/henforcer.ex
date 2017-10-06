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

  In case of success, an Henforcer function must return:

  `{true, relay :: map}`

  In case of failure, an Henforcer function must return:

  `{false, reason, relay :: map}`

  Notice that the return type is a tuple, not a boolean, which one could think
  of, since it's an Elixir/Ruby convention for methods ending with a question
  mark. Keep this in mind.

  ## Legacy Henforcer

  Henforcer is relatively old, so you may find some methods/functions that do
  not follow this standard. If this happens,

  1) Do not panic.
  2) Mind the gap.
  3) If you are using the Legacy henforcer as a building block, fix it.
  4) Otherwise, you can ignore it.
  """

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
    quote do

      with {true, var!(relay)} <- unquote(function) do
        unquote(block)
      else
        not_found ->
          not_found
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
end
