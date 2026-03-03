defmodule LogpointApi.Data.Credential do
  @moduledoc false
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
