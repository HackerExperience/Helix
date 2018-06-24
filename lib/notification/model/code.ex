defmodule Helix.Notification.Model.Code do
  @moduledoc """
  Top-level module used to generate all valid notification "codes".

  A notification "code" is an internal identifier used to specify the exact type
  of the notification. A notification code is unique within its `class`, but not
  necessarily unique among all classes.
  """

  import HELL.Macros

  alias HELL.Utils
  alias Helix.Event
  alias Helix.Notification.Model.Notification

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

      @spec exists?(Notification.code) ::
        boolean
      def exists?(code) do
        Enum.any?(@codes, fn {valid_code, _} -> valid_code == code end)
      end

    end
  end

  @doc """
  Generates the underlying code module.

  `enum_id` is used to map the internal EctoEnum to the given `name`. It must
  not be changed after being used, as this would royally fork everything up.
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

  @spec generate_data(Notification.class, Notification.code, Event.t) ::
    Notification.data
  @doc """
  Dispatches to the underlying code's `generate_data/1`.

  Returns the notification's `data`, a map of arbitrary data used to correctly
  notify the target user.
  """
  def generate_data(class, code, event) do
    class
    |> get_code_module(code)
    |> apply(:generate_data, [event])
  end

  @spec after_read_hook(
    Notification.class, Notification.code, Notification.data
  ) ::
    Notification.data
  @doc """
  Dispatches to the underlying code's `after_read_hook/1`.

  The input is the raw `data` returned from DB (stored in JSONB format), and the
  output is expected to comply to the internal Helix format.
  """
  def after_read_hook(class, code, data) do
    class
    |> get_code_module(code)
    |> apply(:after_read_hook, [data])
  end

  @spec render_data(
    Notification.class, Notification.code, Notification.data
  ) ::
    Notification.data
  @doc """
  Dispatches to the underlying code's `render_data/1`.

  Called right before the `NotificationAddedEvent` is published to the user. The
  underlying `render_data/1` method shall censor/hide/format the final data that
  will be published to the user.
  """
  def render_data(class, code, data) do
    class
    |> get_code_module(code)
    |> apply(:render_data, [data])
  end

  @doc """
  Checks whether the given notification class and code exists.
  """
  @spec code_exists?(Notification.class, Notification.code) ::
    boolean
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

  @spec get_class(module :: atom) ::
    Notification.class
  docp """
  Given the caller module, figure out which class it belongs to.
  """
  defp get_class(module) do
    module
    |> Module.split()
    |> List.pop_at(-1)
    |> elem(0)
    |> String.to_existing_atom()
  end

  docp """
  Generates a "safe name" for the notification code.

  This "safe name" is Capitalized and does not contain any un_der_scor_es.
  """
  defp get_safe_name(code) do
    code
    |> to_string()
    |> String.capitalize()
    |> String.replace("_", "")
  end
end
