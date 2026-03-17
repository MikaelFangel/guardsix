defmodule Guardsix.Core.Search do
  @moduledoc """
  Search logs and retrieve instance data from Guardsix.

  Wraps the [Search API](https://docs.guardsix.com/siem/product-docs/readme/siem_api_reference/search-api).
  Use `Guardsix.search_params/4` to build the query struct.
  """

  alias Guardsix.Data.Client
  alias Guardsix.Data.SearchParams
  alias Guardsix.Net.SearchIncidentClient

  @allowed_types [
    user_preference: :user_preference,
    loginspects: :loginspects,
    repos: :logpoint_repos,
    devices: :devices,
    livesearches: :livesearches
  ]

  @allowed_type_values Keyword.values(@allowed_types)

  @doc """
  Create a search and get its search ID.
  """
  @spec get_id(Client.t(), SearchParams.t()) :: {:ok, map()} | {:error, term()}
  def get_id(%Client{} = client, %SearchParams{} = query) do
    request =
      query
      |> SearchParams.to_form_data()
      |> create_encoded_request()

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

  for {function_name, type} <- @allowed_types do
    name = function_name |> to_string() |> String.replace("_", " ")

    @doc """
    Get #{name} from the Guardsix instance.
    """
    @spec unquote(function_name)(Client.t()) :: {:ok, map()} | {:error, term()}
    def unquote(function_name)(%Client{} = client) do
      get_allowed_data(client, unquote(type))
    end
  end

  defp get_allowed_data(%Client{} = client, type) when type in @allowed_type_values do
    SearchIncidentClient.post_form(req(client), "/getalloweddata", client.credential, %{type: type})
  end

  defp req(%Client{} = client) do
    SearchIncidentClient.new(client.base_url, client.ssl_verify)
  end

  defp create_encoded_request(params) do
    %{requestData: Jason.encode!(params)}
  end
end
