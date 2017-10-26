defmodule Helix.Process.Resources.Behaviour do

  # Would love to generate those automatically, based on resources that call
  # the `resource/2` macro...
  @type resource :: struct

  @type process :: term

  # Resource creation
  @callback build(term) :: resource
  @callback initial() :: resource

  # # Operations
  @callback sum(resource, resource) :: resource
  @callback sub(resource, resource) :: resource
  @callback mul(resource, resource) :: resource
  @callback div(resource, resource) :: resource

  # # Allocation logic
  @callback get_shares(process) :: shares :: resource
  @callback allocate_dynamic(
    shares :: resource,
    res_per_share :: resource,
    process)
  ::
    resource
  @callback allocate_static(process) :: resource
  @callback allocate(dynamic :: resource, static :: resource) :: resource

  # Flow checks / verifications
  @callback overflow?(resource, {process, allocations :: resource}) ::
    false
    | {true, heaviest :: process}
end
