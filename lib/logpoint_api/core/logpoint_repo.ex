defmodule LogpointApi.Core.LogpointRepo do
  @moduledoc false

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
