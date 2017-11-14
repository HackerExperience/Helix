# credo:disable-for-this-file Credo.Check.Refactor.LongQuoteBlocks
defmodule Helix.Software do
  @moduledoc """
  This module is a big big helper to defining new softwares. It removes most of
  the boilerplate and gives us leverage on enhancing the Software behavior.
  """

  @doc """
  By `using` this module, we are able to accumulate module attributes, which
  will be used as a temporary storage for `__before_compile__` macro.
  """
  defmacro __using__(_) do
    quote do

      import unquote(__MODULE__)

      Module.register_attribute(
        __MODULE__,
        :all_software,
        accumulate: true,
        persist: :false
      )
      Module.register_attribute(
        __MODULE__,
        :all_modules,
        accumulate: true,
        persist: :false
      )

      @before_compile unquote(__MODULE__)

      unquote(__MODULE__)
    end
  end

  @doc """
  `__before_compile__` is responsible for actually building the Software-related
  modules (Software.Module and Software.Type), as well as all helper functions
  generated through the accumulated attributes (`@all_software` and
  `@all_modules`).
  """
  defmacro __before_compile__(_env) do
    quote unquote: false do

      all_software = @all_software
      all_modules = @all_modules |> List.flatten()

      # Ensure there are no repeated entries for software types or modules
      ensure_unique_software(all_software)
      ensure_unique_modules(all_modules)

      @spec all ::
        [t]
      @doc """
      Returns a list of all valid software.
      """
      def all,
        do: @all_software

      defmodule Type do
        @moduledoc """
        Software.Type holds information about software types, as well as the
        underlying schema for the "software_types" table.
        """

        use Ecto.Schema

        import Ecto.Changeset

        alias Ecto.Changeset
        alias HELL.Constant
        alias Helix.Software.Model.Software

        @type t :: %__MODULE__{
          type: Software.type,
          extension: Software.extension
        }

        @type creation_params :: Software.t

        @type changeset :: %Changeset{data: %__MODULE__{}}

        @all_software all_software

        @primary_key false
        schema "software_types" do
          field :type, Constant,
            primary_key: true

          field :extension, Constant
        end

        @spec create_changeset(creation_params) ::
          changeset
        def create_changeset(params = %{}) do
          %__MODULE__{}
          |> cast(params, [:type, :extension])
          |> validate_inclusion(:type, all())
          |> validate_inclusion(:extension, all_extensions())
          |> validate_required([:type, :extension])
        end

        # Defines all possible software types that can be `get/1`ed
        Enum.each(all_software, fn software ->

          @doc false
          def get(unquote(software.type)) do
            %{
              type: unquote(software.type),
              extension: unquote(software.extension),
              modules: unquote(software.modules)
            }
          end

        end)

        @spec all ::
          [Software.type]
        @doc """
        Returns a list of all possible software.
        """
        def all do
          @all_software
          |> Enum.map(&(&1.type))
        end

        @spec all_extensions ::
          [Software.extension]
        @doc """
        Returns a list of all valid extensions.
        """
        def all_extensions do
          @all_software
          |> Enum.map(&(&1.extension))
          |> Enum.uniq()
        end
      end

      defmodule Module do
        @moduledoc """
        Software.Module contains information about Software Modules, as well as
        the underlying schema for the "software_modules" table.
        """

        use Ecto.Schema

        import Ecto.Changeset

        alias Ecto.Changeset
        alias HELL.Constant
        alias Helix.Software.Model.Software

        @type t :: %__MODULE__{
          module: Software.module_name,
          software_type: Software.type
        }

        @type creation_params :: %{
          module: Software.module_name,
          software_type: Software.type
        }

        @type changeset :: %Changeset{data: %__MODULE__{}}

        @primary_key false
        schema "software_modules" do
          field :module, Constant,
            primary_key: true

          field :software_type, Constant
        end

        @spec create_changeset(creation_params) ::
          changeset
        def create_changeset(params = %{}) do
          %__MODULE__{}
          |> cast(params, [:software_type, :module])
          |> validate_required([:software_type, :module])
          |> validate_inclusion(:module, all())
        end

        @spec exists?(Software.module_name) ::
          boolean
        @doc """
        Verifies whether the given module exists
        """
        def exists?(module),
          do: module in unquote(all_modules)

        @spec all ::
          [Software.module_name]
        @doc """
        Returns a list of all valid modules
        """
        def all,
          do: unquote(all_modules)
      end
    end

  end

  @doc """
  Ensures there are no repeated entries for software types
  """
  def ensure_unique_software(all_software) do
    uniq = Enum.uniq_by(all_software, &(&1.type))

    all_software == uniq || raise "\n\nrepeated software type definition\n"
  end

  @doc """
  Ensures there are no repeated entries for software modules
  """
  def ensure_unique_modules(all_modules) do
    uniq = Enum.uniq(all_modules)

    all_modules == uniq || raise "\n\nrepeated software modules definition\n"
  end

  @doc """
  Macro to register a new software.

  The registered software information is accumulated and will be used to build
  all software types/modules at the `__before_compile__` macro.
  """
  defmacro software(type: type, extension: extension, modules: modules) do
    quote do

      software = %{
        type: unquote(type),
        extension: unquote(extension),
        modules: unquote(modules)
      }

      # Accumulate the software
      Module.put_attribute(__MODULE__, :all_software, software)
      Module.put_attribute(__MODULE__, :all_modules, unquote(modules))

    end
  end

  defmacro software(type: type, extension: extension) do
    quote do
      software(type: unquote(type), extension: unquote(extension), modules: [])
    end
  end
end
