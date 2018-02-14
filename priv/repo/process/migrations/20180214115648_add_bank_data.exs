defmodule Helix.Process.Repo.Migrations.AddBankData do
  use Ecto.Migration

  def change do
    alter table(:processes, primary_key: false) do
      add :src_atm_id, :inet
      add :src_acc_number, :integer

      add :tgt_atm_id, :inet
      add :tgt_acc_number, :integer
    end

    # Add partial indexes on {atm_id, acc_number} for both src_ and tgt_ fields
    create index(
      :processes,
      [:src_atm_id, :src_acc_number],
      where: "src_atm_id IS NOT NULL AND src_acc_number IS NOT NULL"
    )

    create index(
      :processes,
      [:tgt_atm_id, :tgt_acc_number],
      where: "tgt_atm_id IS NOT NULL AND tgt_acc_number IS NOT NULL"
    )

    # Makes sure that either BOTH {atm_id, acc_number} are set or NEITHER
    create constraint(
      :processes,
      :valid_src_bank_acc,
      check: "
        (src_atm_id IS NULL AND src_acc_number IS NULL) OR
        (src_atm_id IS NOT NULL AND src_acc_number IS NOT NULL)
      "
    )

    create constraint(
      :processes,
      :valid_tgt_bank_acc,
      check: "
        (tgt_atm_id IS NULL AND tgt_acc_number IS NULL) OR
        (tgt_atm_id IS NOT NULL AND tgt_acc_number IS NOT NULL)
      "
    )
  end
end
