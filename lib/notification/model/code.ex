defmodule Helix.Notification.Model.Code do

  import HELL.Macros

  alias HELL.Utils

  defmacro __using__(_) do
    quote do

      import unquote(__MODULE__)

      Module.register_attribute(
        __MODULE__,
        :codes,
        accumulate: true,
        persist: :false
      )

      @before_compile unquote(__MODULE__)

    end
  end

  defmacro __before_compile__(_env) do
    quote do

      import EctoEnum

      defenum CodeEnum, @codes

      def exists?(code) do
        Enum.any?(@codes, fn {valid_code, _} -> valid_code == code end)
      end

    end
  end

  @doc """
  Generates the underlying code module.
  """
  defmacro code(name, enum_id, do: block) do
    module_name =
      __CALLER__.module
      |> get_class()
      |> get_code_module(name)

    quote do

      Module.put_attribute(
        __MODULE__,
        :codes,
        {unquote(name), unquote(enum_id)}
      )

      defmodule unquote(module_name) do
        @moduledoc false

        unquote(block)
      end

    end
  end

  def generate_data(class, code, event) do
    class
    |> get_code_module(code)
    |> apply(:generate_data, [event])
  end

  def after_read_hook(class, code, data) do
    class
    |> get_code_module(code)
    |> apply(:after_read_hook, [data])
  end

  def render_data(class, code, data) do
    class
    |> get_code_module(code)
    |> apply(:render_data, [data])
  end

  @doc """
  Checks whether the given notification class and code exists.
  """
  def code_exists?(class, code) do
    class
    |> get_class_module()
    |> apply(:exists?, [code])
  end

  docp """
  Given the notification class, generate the target module name (class root).
  """
  defp get_class_module(class) do
    safe_class = Utils.capitalize_atom(class)

    __MODULE__
    |> Module.concat(safe_class)
  end

  docp """
  Given the notification class and code, generate the target module name.
  """
  defp get_code_module(class, name) do
    safe_class = Utils.capitalize_atom(class)
    safe_name = get_safe_name(name)

    __MODULE__
    |> Module.concat(safe_class)
    |> Module.concat(safe_name)
  end

  defp get_class(module) do
    module
    |> Module.split()
    |> List.pop_at(-1)
    |> elem(0)
    |> String.to_existing_atom()
  end

  defp get_safe_name(code) do
    code
    |> to_string()
    |> String.capitalize()
    |> String.replace("_", "")
  end
end
