defmodule HELL.Macros.Utils do
  @moduledoc """
  Helpers for `HELL.Macros` and Helix modules that use `HELL.Macros`
  """

  import HELL.Macros

  @doc """
  Helper to remove the protocol namespace.

  Sometimes a macro wants to know its caller's module. If this happens inside
  a protocol's implementation, we would have the following result:

  `Helix.Event.Loggable.Helix.Network.Event.Connection.Started`

  This macro removes the protocol namespace, i.e. `Helix.Event.Loggable`
  """
  def remove_protocol_namespace(module, protocol_module) do
    protocol_size =
      protocol_module
      |> Module.split()
      |> length()

    module
    |> Module.split()
    |> Enum.drop(protocol_size)
    |> ensure_helix()
    |> Module.concat()
  end

  def atomize_module_name({_a, _s, [t]}),
    do: atomize_module_name(t)
  def atomize_module_name(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.downcase()
    |> String.to_atom()
  end

  def get_parent_module(module) do
    module
    |> Module.split()
    |> Enum.drop(-1)
    |> Module.concat()
  end

  docp """
  Small workaround for greater flexibility of `remove_protocol_namespace/2`.
  In some cases, the removal may happen at the protocol's flow instead of the
  protocol itself, which is one module "above" the protocol.

  With this helper, we can remove the protocol safely, regardless whether the
  caller is located at the protocol itself or at the protocol's flow.
  """
  defp ensure_helix(modules = ["Helix" | _]),
    do: modules
  defp ensure_helix(modules),
    do: List.insert_at(modules, 0, "Helix")
end
