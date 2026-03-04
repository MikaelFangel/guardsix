defmodule LogpointApi.Core.LogpointRepo do
  @moduledoc """
  List searchable logpoints and their repos.

  Wraps the [Repos API](https://docs.logpoint.com/siem/product-docs/readme/siem_api_reference/repos_api).
  """

  alias LogpointApi.Auth.JwtProvider
  alias LogpointApi.Data.Client
  alias LogpointApi.Net.AlertRuleClient

  @doc """
  List all searchable logpoints with repos.
  """
  @spec list(Client.t()) :: {:ok, map()} | {:error, term()}
  def list(%Client{} = client) do
    case JwtProvider.logsource_read_token(client.credential) do
      {:ok, token, _claims} ->
        AlertRuleClient.post(req(client), "/Repo/get_all_searchable_logpoint", token, %{})

      {:error, _reason} = error ->
        error
    end
  end

  defp req(%Client{} = client) do
    AlertRuleClient.new(client.base_url, client.ssl_verify)
  end
end
