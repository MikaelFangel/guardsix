defmodule LogpointApi do
  @moduledoc """
  Elixir library for interacting with the Logpoint API.

  Build a client, then pass it to any domain module.

  ## Setup

      client = LogpointApi.client("https://logpoint.company.com", "admin", "secret")

  ## Search

      alias LogpointApi.Core.Search

      query = LogpointApi.Data.SearchParams.new("user=*", "Last 24 hours", 100, ["127.0.0.1"])

      {:ok, %{"search_id" => id}} = Search.get_id(client, query)
      {:ok, result}               = Search.get_result(client, id)
      {:ok, prefs}                = Search.user_preference(client)
      {:ok, repos}                = Search.logpoint_repos(client)

  ## Incidents

      alias LogpointApi.Core.Incident

      {:ok, incidents} = Incident.list(client, start_time, end_time)
      {:ok, states}    = Incident.list_states(client, start_time, end_time)
      {:ok, _}         = Incident.resolve(client, ["id1"])
      {:ok, _}         = Incident.close(client, ["id2"])
      {:ok, _}         = Incident.reopen(client, ["id3"])
      {:ok, _}         = Incident.assign(client, ["id1"], "user_id")
      {:ok, _}         = Incident.add_comments(client, comments)
      {:ok, users}     = Incident.get_users(client)

  ## Alert Rules

      alias LogpointApi.Core.AlertRule

      {:ok, rules} = AlertRule.list(client)
      {:ok, rule}  = AlertRule.get(client, "rule-id")
      {:ok, _}     = AlertRule.activate(client, ["id1", "id2"])
      {:ok, _}     = AlertRule.deactivate(client, ["id1"])
      {:ok, _}     = AlertRule.delete(client, ["id1"])

  ## Logpoint Repos & User-Defined Lists

      alias LogpointApi.Core.LogpointRepo
      alias LogpointApi.Core.UserDefinedList

      {:ok, repos} = LogpointRepo.list(client)
      {:ok, lists} = UserDefinedList.list(client)

  ## SSL

      client = LogpointApi.client("https://192.168.1.100", "admin", "secret", ssl_verify: false)
  """

  alias LogpointApi.Data.Client
  alias LogpointApi.Data.Credential

  @doc """
  Create a client for the Logpoint API.

  ## Options

    * `:ssl_verify` - verify SSL certificates (default: `true`)

  """
  @spec client(String.t(), String.t(), String.t(), keyword()) :: Client.t()
  def client(base_url, username, secret_key, opts \\ []) do
    credential = Credential.new(username, secret_key)
    Client.new(base_url, credential, opts)
  end
end
