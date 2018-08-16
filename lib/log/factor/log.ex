import Helix.Factor

factor Helix.Log.Factor.Log do

  alias Helix.Log.Model.Log
  alias __MODULE__.Revisions, as: RevisionsFactor

  @type factor ::
    %__MODULE__{
      revisions: RevisionsFactor.factor
    }

  @type params :: RevisionsFactor.params
  @type relay :: RevisionsFactor.relay

  @type fact_revisions :: RevisionsFactor.factor

  factor_struct [:revisions]

  child :revisions

  assembly do
    get_fact :revisions
  end

  factor Revisions do

    alias Helix.Entity.Model.Entity
    alias Helix.Log.Model.Log
    alias Helix.Log.Query.Log, as: LogQuery

    @type factor ::
      %__MODULE__{
        total: fact_total,
        from_entity: fact_from_entity,
        extra: fact_extra
      }

    @type params ::
      %{log: Log.t, entity_id: Entity.id}
      | %{log: Log.t}

    @type relay ::
      %{revisions: pos_integer}
      | %{}

    @type fact_total :: pos_integer
    @type fact_from_entity :: non_neg_integer
    @type fact_extra :: non_neg_integer

    factor_struct [:from_entity, :total, :extra]

    fact(:total, _, %{revisions: revisions}) do
      set_fact length(revisions)
    end

    fact(:total, params = %{log: log}, relay) do
      set_relay params, relay, %{revisions: get_revisions(log)}
    end

    fact(:from_entity, %{entity_id: entity_id}, %{revisions: revs}) do
      set_fact Enum.count(revs, &(&1.entity_id == entity_id))
    end

    fact(:from_entity, params = %{log: log, entity_id: _}, relay) do
      set_relay params, relay, %{revisions: get_revisions(log)}
    end

    @doc """
    Counts how many additional revisions are there on top of the original one.

    See docs at `Log.count_extra_revisions/1` for more details.
    """
    fact(:extra, %{log: log = %Log{}}, _) do
      set_fact Log.count_extra_revisions(log)
    end

    assembly do
      get_fact :total
      get_fact :from_entity
      get_fact :extra
    end

    defp get_revisions(log = %Log{}),
      do: LogQuery.fetch_revisions(log)
  end
end
