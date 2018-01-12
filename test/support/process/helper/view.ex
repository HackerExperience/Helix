defmodule Helix.Test.Process.View.Helper do

  def pview_access_full do
    [
      :origin_ip,
      :priority,
      :usage,
      :connection_id,
      :target_connection_id,
      :file
    ]
    |> Enum.sort()
  end

  def pview_access_partial do
    [:connection_id, :target_connection_id]
    |> Enum.sort()
  end

  @doc """
  `assert_keys` will take the rendered process view and check both the `access`
  and the `data` fields, ensuring they have the expected values.

  `access` fields are always the same, regardless of the process type. They
  are defined by above functions `pview_access_[full|partial]`.

  `data`, on the other hand, is unique to each process, so the corresponding
  function must be passed. This function will receive the scope (full|partial)
  and it should return the expected fields/keys.

  If `data` is expected to be empty, simply omit its parameter.
  """
  def assert_keys(rendered, access),
    do: assert_keys(rendered, access, &empty_data_function/1)
  def assert_keys(rendered, :full, data_function),
    do: check_view(rendered, :full, &pview_access_full/0, data_function)
  def assert_keys(rendered, :partial, data_function),
    do: check_view(rendered, :partial, &pview_access_partial/0, data_function)

  defp check_view(rendered, access, access_function, data_function) do
    view_access =
      rendered.access
      |> Map.keys()
      |> Enum.sort()

    view_data =
      rendered.data
      |> Map.keys()
      |> Enum.sort()

    unless access_function.() == view_access do
      raise "#{inspect access_function.()} != #{inspect view_access}"
    end

    unless data_function.(access) == view_data do
      raise "#{inspect data_function.(access)} != #{inspect view_data}"
    end
  end

  defp empty_data_function(_),
    do: []
end
