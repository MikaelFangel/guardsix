defmodule Guardsix.Core.Search do
  @moduledoc """
  Search logs and retrieve instance data from Guardsix.

  Wraps the [Search API](https://docs.guardsix.com/siem/product-docs/readme/siem_api_reference/search-api).
  Use `Guardsix.search_params/4` to build the query struct.
  """

  alias Guardsix.Data.Client
  alias Guardsix.Data.SearchParams
  alias Guardsix.Net.SearchIncidentClient

  @allowed_types [:user_preference, :loginspects, :logpoint_repos, :devices, :livesearches]

  @doc """
  Create a search and get its search ID.
  """
  @spec get_id(Client.t(), SearchParams.t()) :: {:ok, map()} | {:error, term()}
  def get_id(%Client{} = client, %SearchParams{} = query) do
    request_data = SearchParams.to_form_data(query)
    request = create_encoded_request(request_data)
    SearchIncidentClient.post_form(req(client), "/getsearchlogs", client.credential, request)
  end

  @doc """
  Retrieve the search result for a given search ID.
  """
  @spec get_result(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get_result(%Client{} = client, search_id) when is_binary(search_id) do
    request = create_encoded_request(%{search_id: search_id})
    SearchIncidentClient.post_form(req(client), "/getsearchlogs", client.credential, request)
  end

  @doc """
  Get user preferences from the Guardsix instance.
  """
  @spec user_preference(Client.t()) :: {:ok, map()} | {:error, term()}
  def user_preference(%Client{} = client) do
    get_allowed_data(client, :user_preference)
  end

  @doc """
  Get loginspects from the Guardsix instance.
  """
  @spec loginspects(Client.t()) :: {:ok, map()} | {:error, term()}
  def loginspects(%Client{} = client) do
    get_allowed_data(client, :loginspects)
  end

  @doc """
  Get repos from the Guardsix instance.
  """
  @spec repos(Client.t()) :: {:ok, map()} | {:error, term()}
  def repos(%Client{} = client) do
    get_allowed_data(client, :logpoint_repos)
  end

  @doc """
  Get devices from the Guardsix instance.
  """
  @spec devices(Client.t()) :: {:ok, map()} | {:error, term()}
  def devices(%Client{} = client) do
    get_allowed_data(client, :devices)
  end

  @doc """
  Get live searches from the Guardsix instance.
  """
  @spec livesearches(Client.t()) :: {:ok, map()} | {:error, term()}
  def livesearches(%Client{} = client) do
    get_allowed_data(client, :livesearches)
  end

  defp get_allowed_data(%Client{} = client, type) when type in @allowed_types do
    SearchIncidentClient.post_form(req(client), "/getalloweddata", client.credential, %{type: type})
  end

  defp req(%Client{} = client) do
    SearchIncidentClient.new(client.base_url, client.ssl_verify)
  end

  defp create_encoded_request(params) do
    %{requestData: Jason.encode!(params)}
  end
end
