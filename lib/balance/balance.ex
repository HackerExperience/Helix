defmodule Helix.Balance do
  @moduledoc """
  `Helix.Balance` abstracts away implementation details of modules providing
  game balance values.

  Balance modules are meant to be as dumb and free of context as possible,
  receiving whichever data it needs (input) to calculate the output. It must not
  perform any side-effects, and it must always return a `float` (this
  requirement is ensured by the macro implementation, so it's OK if the DSL
  returns an integer).

  ## Sub-modules hierarchy

  - `Balance.Software` - Software and file-related values.

  ## DSL

  ### Values

  A value is a game balance element that builds upon other existing values or
  constants, or simply returns a meaningful value within its context.

  The value may or may not receive parameters.

  If a pattern match is desired (it usually is), use:

  ```
  get :time, %Process{type: :bruteforce}, file = %File{} do
    p_type_const = 400  # Some const

    file.software_type
    |> SoftwareConstant.ratio()
    |> mul(p_type_const)
  end

  get :time, %Process{type: :download}, file = %File{}, speed do
    file.size
    |> mul(speed)
  end
  ```

  ### Constants

  A constant is a fundamental piece of the game design that does not change.

  The constant may or may not receive parameters. If it doesn't, simply use:

  ```
  constant :answer_to_life_the_universe_and_everything, 42
  ```

  If a pattern match is desired, use:

  ```
  constant :gravity, :earth, 9.8
  constant :gravity, :moon, 1.62
  constant :gravity, :mars, 3.71
  ```

  All defined constants may be accessed through the constant's name (no suffix
  is added). Ex: `__MODULE__.gravity(:moon)`
  """

  @std_precision 3

  @doc false
  defmacro __using__(_env) do
    quote do

      import Helix.Balance

      alias Helix.Balance.Constant, as: GlobalConstant
      alias __MODULE__.Constant, as: Constant

    end
  end

  @doc """
  Top-level macro that should be used for by modules within `Helix.Balance`.
  Pure syntactic sugar.
  """
  defmacro balance(name, do: block) do
    quote do

      module_name =
        unquote(name)
        |> Module.split()
        |> List.insert_at(0, "Helix.Balance")
        |> Module.concat()

      defmodule module_name do

        use Helix.Balance

        unquote(block)
      end

    end
  end

  @doc """
  The `constant` macro creates the underlying function that will handle the
  input (if any) and return the constant value.

  Similar to `get/2`, calling `constant/2` expands into a zero-arity method, and
  `constant/3`, like `get/3`, results into an n-arity method. This is done to
  avoid silent errors.

  The returned value always goes through `format_result/1`, but given the output
  nature (constant, hard-coded number) it does not need to be rounded. Yet, if
  it's an integer, the output is automatically converted to float, which is the
  internal type used by `Helix.Balance`.
  """
  defmacro constant(name, value),
    do: expand_constant(name, value)
  defmacro constant(name, pattern, value),
    do: expand_constant(name, [pattern], value)
  defmacro constant(name, pattern1, pattern2, value),
    do: expand_constant(name, [pattern1, pattern2], value)

  @doc """
  The `get` macro creates the underlying function that will handle the input
  (if any) and return the requested value.

  Similar to `constant/2`, calling `get/2` expands into a zero-arity method, and
  `get/3`, like `constant/3`, results into an n-arity method. This is done to
  avoid silent errors.

  The returned value always goes through `format_result/1`, meaning it will be
  rounded within `@std_precision` and enforced a float type, which is the
  internal type used by `Helix.Balance`.
  """
  defmacro get(name, do: block),
    do: expand_get(name, block: block)
  defmacro get(name, pattern, do: block),
    do: expand_get(name, [pattern], block: block)
  defmacro get(name, pattern1, pattern2, do: block),
    do: expand_get(name, [pattern1, pattern2], block: block)

  @doc """
  Internal macro that will handle the result of all `get/2,3` and `constant/2,3`
  calls, ensuring it's a float and rounding it up or down within the precision
  set at `@std_precision`.
  """
  defmacro format_result(result) do
    quote do

      unquote(result)
      |> to_float()
      |> round_number()

    end
  end

  # Arithmetic helpers

  @doc """
  Syntactic sugar for a cleaner pipe version (use `mul` instead of `Kernel.*`).
  """
  defmacro mul(v1, v2) do
    quote do

      unquote(v1) * unquote(v2)

    end
  end

  @spec round_number(number, precision :: integer) ::
    float
  @doc """
  Rounds the `value` up or down, according to the given precision.

  `round_number/2` will perform an implicit conversion to float if the input is
  an integer.
  """
  def round_number(value, precision \\ @std_precision)
  def round_number(value, precision) when is_float(value),
    do: Float.round(value, precision)
  def round_number(value, precision) when is_integer(value) do
    value
    |> to_float()
    |> round_number(precision)
  end

  @spec to_float(number) ::
    float
  @doc """
  Converts the input to float (if needed).
  """
  def to_float(value) when is_float(value),
    do: value
  def to_float(value) when is_integer(value),
    do: value / 1.0

  defp expand_constant(name, value) do
    quote do

      def unquote(name)() do
        unquote(value)
        |> format_result()
      end

    end
  end

  defp expand_constant(name, patterns, value) do
    quote do

      def unquote(name)(unquote_splicing(patterns)) do
        unquote(value)
        |> format_result()
      end

    end
  end

  defp expand_get(name, block: block) do
    quote do

      def unquote(:"get_#{name}")() do
        unquote(block)
        |> format_result()
      end

    end
  end

  defp expand_get(name, patterns, block: block) do
    quote do

      def unquote(:"get_#{name}")(unquote_splicing(patterns)) do
        unquote(block)
        |> format_result()
      end

    end
  end
end
