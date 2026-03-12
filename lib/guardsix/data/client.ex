defmodule Guardsix.Data.Client do
  @moduledoc """
  Holds the base URL, credential, and SSL settings for API requests.

  Built via `Guardsix.client/3,4`.
  """

  alias Guardsix.Data.Credential

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
