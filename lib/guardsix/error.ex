defmodule Guardsix.Error do
  @moduledoc """
  The error types returned by this library.

  Every function that talks to a Guardsix instance answers `{:ok, term()}` or `{:error, t()}`, where
  `t()` is one of five exception structs. Match on the struct to tell them apart:

      alias Guardsix.Error

      case AlertRule.create(client, rule) do
        {:ok, created} -> created
        {:error, %Error.Validation{errors: fields}} -> report(fields)
        {:error, %Error.Transport{}} -> retry()
        {:error, error} -> Logger.error(Exception.message(error))
      end

  Each type carries only the fields that apply to it, so there are no `nil`s to guard against on the
  fields you match on. All five are exceptions, which means `Exception.message/1` works on any of
  them and the last clause above is a complete fallback — and any of them can be raised if you would
  rather let it crash.

    * `Guardsix.Error.Validation` — the request was invalid, rejected here or at the API
    * `Guardsix.Error.API` — Guardsix returned an error for the request
    * `Guardsix.Error.Auth` — login, token, or scope failure
    * `Guardsix.Error.Transport` — the request did not complete, or the response was unreadable
    * `Guardsix.Error.Timeout` — a search did not finish within the allowed attempts

  """

  alias Guardsix.Error.API
  alias Guardsix.Error.Auth
  alias Guardsix.Error.Timeout
  alias Guardsix.Error.Transport
  alias Guardsix.Error.Validation

  @type t ::
          API.t()
          | Auth.t()
          | Timeout.t()
          | Transport.t()
          | Validation.t()

  @doc false
  # Which type you get depends on where the reason landed in the body. Field-level detail
  # arrives under `validationErrors`; token failures say `error` where everything else says `message`.
  @spec from_response(map(), non_neg_integer() | nil) :: t()
  def from_response(body, status) when is_map(body) do
    errors = flatten(Map.get(body, "validationErrors"))

    cond do
      map_size(errors) > 0 ->
        %Validation{errors: errors, status: status(body, status), body: body}

      token_failure?(body) ->
        %Auth{message: Map.fetch!(body, "error"), status: status(body, status), body: body}

      true ->
        %API{
          message: message(body),
          status: status(body, status),
          error_code: Map.get(body, "error_code"),
          body: body
        }
    end
  end

  defp token_failure?(body), do: is_binary(Map.get(body, "error")) and not is_binary(Map.get(body, "message"))

  # Token failures report the status in the body as well as in the response.
  defp status(body, status), do: status || Map.get(body, "status_code")

  defp message(body), do: Map.get(body, "message") || Map.get(body, "error") || "the request failed"

  defp flatten(errors) when is_map(errors), do: errors |> Enum.flat_map(&entries/1) |> Map.new()
  defp flatten(_absent), do: %{}

  defp entries({field, nested}) when is_map(nested) do
    nested |> flatten() |> Enum.map(fn {inner, message} -> {"#{field}.#{inner}", message} end)
  end

  defp entries({field, message}), do: [{field, message}]
end
