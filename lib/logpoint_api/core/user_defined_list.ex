defmodule LogpointApi.Core.UserDefinedList do
  @moduledoc false

  alias LogpointApi.Auth.JwtProvider
  alias LogpointApi.Data.Client
  alias LogpointApi.Net.AlertRuleClient

  @doc """
  List user defined lists.
  """
  @spec list(Client.t(), map()) :: {:ok, map()} | {:error, term()}
  def list(%Client{} = client, params \\ %{}) do
    case JwtProvider.search_read_token(client.credential) do
      {:ok, token, _claims} ->
        AlertRuleClient.get(req(client), "/UserDefinedList/lists_api", token, params)

      {:error, _reason} = error ->
        error
    end
  end

  defp req(%Client{} = client) do
    AlertRuleClient.new(client.base_url, client.ssl_verify)
  end
end
