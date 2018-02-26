import Helix.Balance

balance Software do

  alias Helix.Software.Model.File

  @spec get_base(File.t) :: float

  @doc """
  `base` is the base multiplier for most file-related operations that are
  directly influenced by the file's modules, including but not limited to:

  - Total file size
  - Time needed for research
  - Cost needed for research

  It builds upon the `ratio` constant, which defines a normalized ratio for each
  module.
  """
  get :base, %File{software_type: :cracker, modules: modules} do
    bruteforce =
      :bruteforce
      |> Constant.ratio()
      |> mul(modules.bruteforce.version)

    overflow =
      :overflow
      |> Constant.ratio()
      |> mul(modules.overflow.version)

    bruteforce + overflow
  end
end
