defmodule Helix.Log.Model.LogType.Macros do

  import HELL.Macros

  alias HELL.Utils
  alias Helix.Network.Model.Network

  defmacro __using__(_) do
    quote do

      import unquote(__MODULE__)

      Module.register_attribute(
        __MODULE__,
        :logs,
        accumulate: true, persist: :false
      )

      @before_compile unquote(__MODULE__)

    end
  end

  defmacro __before_compile__(_env) do
    quote do

      import EctoEnum

      defenum LogEnum, @logs

      @spec exists?(atom) ::
        boolean
      def exists?(log_type),
        do: Enum.any?(@logs, fn {valid_type, _} -> valid_type == log_type end)

      @spec new(type, map) ::
        struct
      @doc """
      Creates a new struct for the given log `type`.
      """
      def new(type, data_params),
        do: dispatch(type, :new, data_params)

      @spec parse(type, map) ::
        {:ok, struct}
        | :error
      @doc """
      Attempts to parse the potentially unsafe input into a valid LogData.
      """
      def parse(type, unsafe_data_params),
        do: dispatch(type, :parse, unsafe_data_params)

      @spec dispatch(type, atom, term) ::
        term
      defp dispatch(type, method, param) when not is_list(param),
        do: dispatch(type, method, [param])
      defp dispatch(type, method, params) do
        type
        |> get_type_module()
        |> apply(method, params)
      end

    end
  end

  @doc """
  Top-level macro used to define a LogType and its underlying LogData.
  """
  defmacro log(name, enum_id, do: block) do
    module_name =
      __CALLER__.module
      |> Module.concat(get_safe_name(name))

    quote do

      Module.put_attribute(
        __MODULE__,
        :logs,
        {unquote(name), unquote(enum_id)}
      )

      defmodule unquote(module_name) do
        @moduledoc false

        @log_type unquote(name)

        unquote(block)
      end

    end
  end

  @doc """
  Converts the module into a LogData struct.
  """
  defmacro data_struct(keys) do
    quote do

      @enforce_keys unquote(keys)
      defstruct unquote(keys)

    end
  end

  @doc """
  Creates a new LogData from the given `data` map.
  """
  defmacro new(data, do: block) do
    quote do

      @doc false
      def new(unquote(data)) do
        unquote(block)
      end

    end
  end

  @doc """
  Attempts to parse the given unsafe input into a valid LogData.
  """
  defmacro parse(data, do: block) do
    quote do

      @spec parse(term) ::
        {:ok, data :: struct}
        | :error
      @doc false
      def parse(map = unquote(data)) when is_map(map) do
        try do
          {:ok, unquote(block)}
        rescue
          RuntimeError ->
            :error

          KeyError ->
            :error
        end
      end

      def parse(not_map) when not is_map(not_map),
        do: :error

    end
  end

  @doc """
  Generates the boilerplate for a n-field log type.

  The `data_struct` construct is skipped on purpose; you have to explicitly
  define it for documentation purposes.

  Example for n=2, i.e. `gen2({:network_id, :network}, {:ip, :ip})`:

    new(%{network_id: network_id, ip: ip}) do
      %__MODULE__{
        network_id: network_id,
        ip: ip
      }
    end

    parse(unsafe) do
      %__MODULE__{
        network_id: validate(:network, unsafe["network_id"]),
        ip: validate(:ip, unsafe["ip"])
      }
    end
  """
  defmacro gen0,
    do: do_gen0()
  defmacro gen2(p1, p2),
    do: do_gen2(p1, p2)
  defmacro gen3(p1, p2, p3),
    do: do_gen3(p1, p2, p3)

  def validate(field_type, field_value) when is_atom(field_type) do
    fun = Utils.concat_atom(:validate_, field_type)

    __MODULE__
    |> apply(fun, [field_value])
    |> handle_validate()
  end

  def validate(validator, field_value) when is_function(validator) do
    field_value
    |> validator.()
    |> handle_validate()
  end

  defp handle_validate({:error, _}),
    do: raise "bad"
  defp handle_validate(:error),
    do: raise "bad"
  defp handle_validate({:ok, value}),
    do: value
  defp handle_validate(value),
    do: value

  def validate_network(entry) when not is_binary(entry),
    do: :error
  def validate_network(entry),
    do: Network.ID.cast(entry)

  def validate_file_name(entry) when not is_binary(entry),
    do: :error
  def validate_file_name(entry),
    do: entry

  def validate_ip(ip) do
    ip
  end

  def get_type_module(type) do
    __MODULE__
    |> Module.split()
    |> List.replace_at(-1, get_safe_name(type))
    |> Module.concat()
  end

  docp """
  Generates a "safe name" for the log type.

  This "safe name" is Capitalized and does not contain any un_der_scor_es.
  """
  defp get_safe_name(type) do
    type
    |> to_string()
    |> String.capitalize()
    |> String.replace("_", "")
  end

  ##############################################################################
  # N-field generators
  ##############################################################################

  defp do_gen0 do
    quote do

      new(%{}) do
        %__MODULE__{}
      end

      parse(_) do
        %__MODULE__{}
      end

    end
  end

  defp do_gen2({f1, v_f1}, {f2, v_f2}) do
    str_f1 = to_string(f1)
    str_f2 = to_string(f2)

    quote do

      new(%{unquote(f1) => local_f1, unquote(f2) => local_f2}) do
        %__MODULE__{
          unquote(f1) => local_f1,
          unquote(f2) => local_f2
        }
      end

      parse(unsafe) do
        %__MODULE__{
          unquote(f1) =>
            validate(unquote(v_f1), Map.fetch!(unsafe, unquote(str_f1))),
          unquote(f2) =>
            validate(unquote(v_f2), Map.fetch!(unsafe, unquote(str_f2)))
        }
      end

    end
  end

  defp do_gen3({f1, v_f1}, {f2, v_f2}, {f3, v_f3}) do
    str_f1 = to_string(f1)
    str_f2 = to_string(f2)
    str_f3 = to_string(f3)

    quote do

      new(%{unquote(f1) => l_f1, unquote(f2) => l_f2, unquote(f3) => l_f3}) do
        %__MODULE__{
          unquote(f1) => l_f1,
          unquote(f2) => l_f2,
          unquote(f3) => l_f3
        }
      end

      parse(unsafe) do
        %__MODULE__{
          unquote(f1) =>
            validate(unquote(v_f1), Map.fetch!(unsafe, unquote(str_f1))),
          unquote(f2) =>
            validate(unquote(v_f2), Map.fetch!(unsafe, unquote(str_f2))),
          unquote(f3) =>
            validate(unquote(v_f3), Map.fetch!(unsafe, unquote(str_f3)))
        }
      end

    end
  end
end
