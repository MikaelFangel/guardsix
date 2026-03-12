defmodule Guardsix.Data.Credential do
  @moduledoc """
  Username and secret key used to authenticate with the Guardsix API.

  Created internally by `Guardsix.client/3,4`.
  """
  @derive {Inspect, except: [:secret_key]}
  @enforce_keys [:username, :secret_key]
  defstruct [:username, :secret_key]

  @type t :: %__MODULE__{
          username: String.t(),
          secret_key: String.t()
        }

  def new(username, secret_key) do
    %__MODULE__{
      username: username,
      secret_key: secret_key
    }
  end
end
