defmodule LogpointApi.Data.Client do
  @moduledoc false

  alias LogpointApi.Data.Credential

  @derive {Inspect, except: [:credential]}
  @enforce_keys [:base_url, :credential]
  defstruct [:base_url, :credential, ssl_verify: true]

  @type t :: %__MODULE__{
          base_url: String.t(),
          credential: Credential.t(),
          ssl_verify: boolean()
        }

  @spec new(String.t(), Credential.t(), keyword()) :: t()
  def new(base_url, credential, opts \\ []) do
    %__MODULE__{
      base_url: base_url,
      credential: credential,
      ssl_verify: Keyword.get(opts, :ssl_verify, true)
    }
  end
end
