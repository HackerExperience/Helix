defmodule Helix.Hardware.Controller.HardwareServiceTest do

  use ExUnit.Case, async: false

  alias HELF.Broker
  alias Helix.Hardware.Repo
  alias Helix.Hardware.Controller.Motherboard, as: MotherboardController
  alias Helix.Hardware.Model.ComponentSpec
  alias Helix.Hardware.Model.MotherboardSlot

  @moduletag :umbrella

  setup_all [:component_fixtures]

  defp component_fixtures(_context) do
    Repo.transaction fn ->
      mobo_params = %{
        component_type: "mobo",
        spec: %{
          spec_code: "MOBO01",
          spec_type: "mobo",
          slots: %{
            "0" => %{
              type: "cpu"
            },
            "1" => %{
              type: "ram"
            },
            "2" => %{
              type: "hdd"
            },
            "3" => %{
              type: "nic"
            }
          }
        }
      }

      cpu_params = %{
        component_type: "cpu",
        spec: %{
          spec_code: "CPU01",
          spec_type: "cpu",
        }
      }

      ram_params = %{
        component_type: "ram",
        spec: %{
          spec_code: "RAM01",
          spec_type: "ram"
        }
      }

      hdd_params = %{
        component_type: "hdd",
        spec: %{
          spec_code: "HDD01",
          spec_type: "hdd"
        }
      }

      nic_params = %{
        component_type: "nic",
        spec: %{
          spec_code: "NIC01",
          spec_type: "nic"
        }
      }

      spec_params = [
        mobo_params,
        cpu_params,
        ram_params,
        hdd_params,
        nic_params
      ]

      Enum.each(spec_params, fn params ->
        params
        |> ComponentSpec.create_changeset()
        |> Repo.insert(on_conflict: :nothing)
      end)
    end

    :ok
  end

  defp create_account do
    email = Burette.Internet.email()
    password = Burette.Internet.password()
    params = %{
      email: email,
      password_confirmation: password,
      password: password}

    case Broker.call("account:create", params) do
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
      :timer.sleep(100)

      assert {:ok, _} = motherboard_of_account(account.account_id)
    end

    test "motherboard slots are created" do
      {:ok, account} = create_account()

      # TODO: removing this sleep depends on T412
      :timer.sleep(100)

      {:ok, motherboard} = motherboard_of_account(account.account_id)
      slots = MotherboardController.get_slots(motherboard.motherboard_id)

      refute Enum.empty?(slots)
    end

    test "motherboard linked at least a single of each slot type" do
      {:ok, account} = create_account()

      # TODO: removing this sleep depends on T412
      :timer.sleep(100)

      {:ok, motherboard} = motherboard_of_account(account.account_id)
      slots = MotherboardController.get_slots(motherboard.motherboard_id)

       possible_types = MapSet.new(slots, &(&1.link_component_type))
       linked_types =
         slots
         |> Enum.filter(&MotherboardSlot.linked?/1)
         |> MapSet.new(&(&1.link_component_type))

       assert MapSet.equal?(possible_types, linked_types)
    end
  end
end