alias Helix.Hardware.Repo
alias Helix.Hardware.Model.ComponentType
alias Helix.Hardware.Model.ComponentSpec, warn: false

Repo.transaction fn ->
  Enum.each(ComponentType.possible_types, fn type ->
    Repo.insert!(%ComponentType{component_type: type}, on_conflict: :nothing)
  end)
end

################################################################################
# Fixtures for development
################################################################################
if Mix.env in [:dev, :test] do
  Repo.transaction fn ->
    mobo_params = %{
      component_type: :mobo,
      spec: %{
        "spec_code" => "MOBO01",
        "spec_type" => "MOBO",
        "name" => "Sample Motherboard 1",
        "slots" => %{
          "0" => %{"type" => "CPU"},
          "1" => %{"type" => "HDD", "limit" => 2000},
          "2" => %{"type" => "HDD", "limit" => 2000},
          "3" => %{"type" => "RAM", "limit" => 4096},
          "4" => %{"type" => "RAM", "limit" => 4096},
          "5" => %{"type" => "NIC", "limit" => 1000},
          "6" => %{"type" => "NIC", "limit" => 1000}
        },
        "display" => "xml-esque description of the mobo gateway"
      }
    }

    cpu_params = %{
      component_type: :cpu,
      spec: %{
        "spec_code" => "CPU01",
        "spec_type" => "CPU",
        "name" => "Sample CPU 1",
        "clock" => 3000,
        "cores" => 7
      }
    }

    ram_params = %{
      component_type: :ram,
      spec: %{
        "spec_code" => "RAM01",
        "spec_type" => "RAM",
        "name" => "Sample RAM 1",
        "clock" => 1666,
        "ram_size" => 2048
      }
    }

    hdd_params = %{
      component_type: :hdd,
      spec: %{
        "spec_code" => "HDD01",
        "spec_type" => "HDD",
        "name" => "Sample HDD 1",
        "hdd_size" => 2000
      }
    }

    nic_params = %{
      component_type: :nic,
      spec: %{
       "spec_code" => "NIC01",
        "spec_type" => "NIC",
        "name" => "Sample NIC 1",
        "link" => 1000
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
      |> Repo.insert!(on_conflict: :nothing)
    end)
  end
end
