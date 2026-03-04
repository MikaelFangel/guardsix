defmodule LogpointApi.Core.UserDefinedList do
  @moduledoc """
  Manage user-defined lists in Logpoint.

  Wraps the [User Defined Lists API](https://docs.logpoint.com/siem/product-docs/readme/siem_api_reference/user-defined-lists-api).
  """

  alias LogpointApi.Auth.JwtProvider
  alias LogpointApi.Data.Client
  alias LogpointApi.Net.AlertRuleClient

  @doc """
  List user defined lists.
  """
  @spec list(Client.t(), map()) :: {:ok, map()} | {:error, term()}
  def list(%Client{} = client, params \\ %{}) do
    with_read_token(client, fn token ->
      AlertRuleClient.get(req(client), "/UserDefinedList/lists_api", token, params)
    end)
  end

  @doc """
  Import a static list from CSV or TXT content.
  """
  @spec import_static(Client.t(), String.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def import_static(%Client{} = client, name, content)
      when is_binary(name) and is_binary(content) do
    body = %{package_import_name: name, package_import: content}

    with_write_token(client, fn token ->
      AlertRuleClient.post_form(req(client), "/UserDefinedList/import_api", token, body)
    end)
  end

  defp with_read_token(%Client{} = client, fun) do
    case JwtProvider.search_read_token(client.credential) do
      {:ok, token, _claims} -> fun.(token)
      {:error, _reason} = error -> error
    end
  end

  defp with_write_token(%Client{} = client, fun) do
    case JwtProvider.search_write_token(client.credential) do
      {:ok, token, _claims} -> fun.(token)
      {:error, _reason} = error -> error
    end
  end

  defp req(%Client{} = client) do
    AlertRuleClient.new(client.base_url, client.ssl_verify)
  end
end
