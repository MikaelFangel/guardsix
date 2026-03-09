defmodule LogpointApi do
  @moduledoc """
  Elixir library for interacting with the Logpoint API.

  Build a client, then pass it to any domain module.

  ## Setup

      client = LogpointApi.client("https://logpoint.company.com", "admin", "secret")

  ## Search

      query = LogpointApi.search_params("user=*", "Last 24 hours", 100, ["127.0.0.1"])

      # Block until final results (polls automatically)
      {:ok, result} = LogpointApi.run_search(client, query)

      # Low-level primitives are still available
      alias LogpointApi.Core.Search

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
      {:ok, _}         = Incident.add_comments(client, [LogpointApi.comment("id1", "note")])
      {:ok, users}     = Incident.get_users(client)

  ## Alert Rules

      alias LogpointApi.Data.Rule
      alias LogpointApi.Core.AlertRule

      {:ok, rules} = AlertRule.list(client)
      {:ok, rule}  = AlertRule.get(client, "rule-id")
      {:ok, _}     = AlertRule.activate(client, ["id1", "id2"])
      {:ok, _}     = AlertRule.deactivate(client, ["id1"])
      {:ok, _}     = AlertRule.delete(client, ["id1"])

      # Builder-style alert rule creation
      rule =
        LogpointApi.rule("Brute Force Detection")
        |> Rule.description("Detects brute force login attempts")
        |> Rule.query("error_code=4625")
        |> Rule.time_range(1, :day)
        |> Rule.repos(["10.0.0.1"])
        |> Rule.limit(100)
        |> Rule.threshold(:greaterthan, 5)
        |> Rule.risk_level("high")
        |> Rule.aggregation_type("max")
        |> Rule.assignee("admin")

      {:ok, _} = AlertRule.create(client, rule)

      # Email notification
      alias LogpointApi.Data.EmailNotification

      notif =
        LogpointApi.email_notification(["rule-1"], "admin@example.com")
        |> EmailNotification.subject("Alert: {{ rule_name }}")
        |> EmailNotification.template("<p>Details</p>")

      {:ok, _} = AlertRule.create_email_notification(client, notif)

      # HTTP notification
      alias LogpointApi.Data.HttpNotification

      webhook =
        LogpointApi.http_notification(["rule-1"], "https://hooks.slack.com/abc", :post)
        |> HttpNotification.body(~s({"text": "{{ rule_name }}"}))
        |> HttpNotification.bearer_auth("my-token")

      {:ok, _} = AlertRule.create_http_notification(client, webhook)

  ## Logpoint Repos & User-Defined Lists

      alias LogpointApi.Core.LogpointRepo
      alias LogpointApi.Core.UserDefinedList

      {:ok, repos} = LogpointRepo.list(client)
      {:ok, lists} = UserDefinedList.list(client)

  ## SSL

      client = LogpointApi.client("https://192.168.1.100", "admin", "secret", ssl_verify: false)
  """

  alias LogpointApi.Core.SearchRunner
  alias LogpointApi.Data.Client
  alias LogpointApi.Data.Comment
  alias LogpointApi.Data.Credential
  alias LogpointApi.Data.EmailNotification
  alias LogpointApi.Data.HttpNotification
  alias LogpointApi.Data.Rule
  alias LogpointApi.Data.SearchParams

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

  @doc """
  Build a search query.
  """
  @spec search_params(String.t(), String.t() | [number()], non_neg_integer(), [String.t()]) ::
          SearchParams.t()
  def search_params(query, time_range, limit, repos) do
    SearchParams.new(query, time_range, limit, repos)
  end

  @doc """
  Build a search query with explicit start and end times.
  """
  @spec search_params(String.t(), number(), number(), non_neg_integer(), [String.t()]) ::
          SearchParams.t()
  def search_params(query, start_time, end_time, limit, repos) do
    SearchParams.new(query, start_time, end_time, limit, repos)
  end

  @doc """
  Run a search and block until final results arrive.

  Polls automatically, handling expired searches by resubmitting the query.

  ## Options

    * `:polling_interval` — milliseconds between polls (default: `1_000`)
    * `:max_attempts`     — maximum poll iterations (default: `30`)

  """
  @spec run_search(Client.t(), SearchParams.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run_search(%Client{} = client, %SearchParams{} = query, opts \\ []) do
    SearchRunner.run(client, query, opts)
  end

  @doc """
  Build an incident comment.
  """
  @spec comment(String.t(), String.t() | [String.t()]) :: Comment.t()
  def comment(incident_id, comments) do
    Comment.new(incident_id, comments)
  end

  @doc """
  Build an alert rule.
  """
  @spec rule(String.t()) :: Rule.t()
  def rule(name) do
    Rule.new(name)
  end

  @doc """
  Build an email notification for alert rules.
  """
  @spec email_notification([String.t()], String.t() | [String.t()]) :: EmailNotification.t()
  def email_notification(ids, emails) do
    EmailNotification.new(ids, emails)
  end

  @doc """
  Build an HTTP notification for alert rules.
  """
  @spec http_notification([String.t()], String.t(), atom()) :: HttpNotification.t()
  def http_notification(ids, url, request_type) do
    HttpNotification.new(ids, url, request_type)
  end
end
