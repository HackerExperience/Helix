alias Helix.Network.Repo
alias Helix.Network.Model.Network

{:ok, internet_id} = Network.ID.cast("::")
internet = %Network{network_id: internet_id, name: "Internet"}
Repo.insert!(internet, on_conflict: :nothing)
