defmodule Helix.Process.Query.Process.Macros do

  alias Helix.Process.Model.Process

  defmacro get_custom(meta, do: block) do
    quote do

      def get_custom(type, server_id, unquote(meta)) do
        server_id
        |> get_running_processes_of_type_on_server(type)
        |> Enum.filter(unquote(block))
        |> nilify_if_empty()
      end

    end
  end

  defmacro get_custom do
    quote do

      def get_custom(_, _, _),
        do: nil

    end
  end

  @spec nilify_if_empty([Process.t]) ::
    [Process.t]
    | nil
  def nilify_if_empty([]),
    do: nil
  def nilify_if_empty(list),
    do: list
end
