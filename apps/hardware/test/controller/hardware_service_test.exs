defmodule Helix.Hardware.Controller.HardwareServiceTest do

  use ExUnit.Case, async: false

  alias HELF.Broker
  alias HELL.TestHelper.Random
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Model.MotherboardSlot

  @moduletag :umbrella

  defp create_account do
    name = Random.username()
    email = Burette.Internet.email()
    password = Burette.Internet.password()

    params = %{
      username: name,
      email: email,
      password_confirmation: password,
      password: password
    }

    case Broker.call("account.create", params) do
      {_, {:ok, account}} ->
        {:ok, account}
      {_, {:error, error}} ->
        {:error, error}
    end
  end

  # HACK: this method is calling methods from another domain instead of Broker
  defp motherboard_of_account(account_id) do
    # entity has a list of servers
    with \
      [entity_server] <- Helix.Entity.Controller.EntityServer.find(account_id),
      {:ok, server} <- Helix.Server.Controller.Server.find(entity_server.server_id),
      {:ok, motherboard} <- Helix.Hardware.Controller.Motherboard.find(server.motherboard_id)
    do
      {:ok, motherboard}
    else
      _ ->
        {:error, :not_found}
    end
  end

  describe "after account creation" do
    test "motherboard is created" do
      {:ok, account} = create_account()

      # TODO: removing this sleep depends on T412
      :timer.sleep(200)

      assert {:ok, _} = motherboard_of_account(account.account_id)
    end

    test "motherboard slots are created" do
      {:ok, account} = create_account()

      # TODO: removing this sleep depends on T412
      :timer.sleep(200)

      {:ok, motherboard} = motherboard_of_account(account.account_id)
      slots = MotherboardController.get_slots(motherboard)

      refute Enum.empty?(slots)
    end

    test "motherboard linked at least a single of each slot type" do
      {:ok, account} = create_account()

      # TODO: removing this sleep depends on T412
      :timer.sleep(200)

      {:ok, motherboard} = motherboard_of_account(account.account_id)
      slots = MotherboardController.get_slots(motherboard)

       possible_types = MapSet.new(slots, &(&1.link_component_type))
       linked_types =
         slots
         |> Enum.filter(&MotherboardSlot.linked?/1)
         |> MapSet.new(&(&1.link_component_type))

       assert MapSet.equal?(possible_types, linked_types)
    end
  end
end