defmodule Guardsix.Data.Session do
  @moduledoc """
  Holds an authenticated session for UI endpoints that do not support JWT.

  Built via `Guardsix.session/4,5`.
  """

  @derive {Inspect, except: [:req]}
  @enforce_keys [:req, :csrf_token, :username, :expires_at]
  defstruct [:req, :csrf_token, :username, :expires_at]

  @type t :: %__MODULE__{
          req: Req.Request.t(),
          csrf_token: String.t(),
          username: String.t(),
          expires_at: DateTime.t()
        }

  @doc """
  Check if the session has expired.
  """
  @spec expired?(t()) :: boolean()
  def expired?(%__MODULE__{expires_at: expires_at}) do
    DateTime.compare(DateTime.utc_now(), expires_at) != :lt
  end
end
