defmodule Helix.Test.Notification.Helper do

  @classes [:account, :server]
  @code_map %{
    account: [:server_password_acquired],
    server: [:file_downloaded]
  }

  def expected_suffix(:account),
    do: 1
  def expected_suffix(:server),
    do: 2

  def get_suffix(%{id: {_, suffix, _, _, _, _, _, _}}),
    do: suffix

  def get_module(:account),
    do: Helix.Notification.Model.Notification.Account
  def get_module(:server),
    do: Helix.Notification.Model.Notification.Server

  @doc """
  Generates a valid random ID for the given (albeit optional) `class`.
  """
  def generate_id,
    do: generate_id(random_class())
  def generate_id(class) do
    class
    |> get_module()
    |> Module.concat("ID")
    |> apply(:generate, [])
  end

  @doc """
  Returns a valid random code for the given class.
  """
  def random_code,
    do: random_code(random_class())

  def random_code(class),
    do: {class, Enum.random(@code_map[class])}

  @doc """
  Returns a valid random class.
  """
  def random_class,
    do: Enum.random(@classes)
end
