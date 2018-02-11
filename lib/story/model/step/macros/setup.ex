defmodule Helix.Story.Model.Step.Macros.Setup do

  @doc """
  The `find` macro will generate the standard `find_{item}` method. It's mostly
  a syntactic sugar that:

  - Automatically returns `nil` if the `identifier` is `nil`
  - Automatically handles identifiers that may be `id` or `t`, fetching the
    requested field (defined on `get`)
  - Automatically converts the result to `nil` from equivalent results (e.g.
    `false` is considered to be `nil` here). This is useful because the macro
    that uses `StoryQuery.Setup` only accepts `nil` as a valid negative result.

  Other than that, feel free to bypass the macro and write the function directly

  It only has to:

  - have `find_{item}` name
  - accept `identifier` and `opts`
  - return `nil` in case of failure
  - return the expected format ({:ok, $object, $related, $events}) if found
  """
  defmacro find(item, identifier, get: field),
    do: do_find(item, identifier, quote(do: []), field: field)
  defmacro find(item, identifier, do: block),
    do: do_find(item, identifier, quote(do: []), block: block)
  defmacro find(item, identifier, opts, get: field),
    do: do_find(item, identifier, opts, field: field)
  defmacro find(item, identifier, opts, do: block),
    do: do_find(item, identifier, opts, block: block)

  defp do_find(item, identifier, opts, field: field) do
    quote do

      def unquote(:"find_#{item}")(id = unquote(identifier), opts = unquote(opts)) do
        value = Map.fetch!(id, unquote(field))

        apply(__MODULE__, unquote(:"find_#{item}"), [value, opts])
      end

    end
  end

  defp do_find(item, identifier, opts, block: block) do
    quote generated: true do

      @spec unquote(:"find_#{item}")(nil, list) :: nil

      def unquote(:"find_#{item}")(nil, _),
        do: nil
      def unquote(:"find_#{item}")(unquote(identifier), unquote(opts)) do
        result = unquote(block)

        case result do
          {:ok, _, _, _} ->
            result

          nil ->
            nil

          false ->
            nil

          [] ->
            nil
        end
      end

    end
  end
end
