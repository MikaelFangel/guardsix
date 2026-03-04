# LogpointApi

A clean, stateless Elixir library for interacting with the [Logpoint API](https://docs.logpoint.com/docs/logpoint-api-reference/en/latest/index.html).

This library provides simple functions that make direct HTTP requests to the Logpoint API without any OTP overhead or persistent connections.

## Installation

```elixir
def deps do
  [
    {:logpoint_api, "~> 1.0.0"}
  ]
end
```

## Basic Usage

Create a client and pass it to any domain module:

```elixir
client = LogpointApi.client("https://logpoint.company.com", "admin", "your_secret_key")
```

### Search

```elixir
alias LogpointApi.Core.Search

query = LogpointApi.search_params(
  "user=*",
  "Last 24 hours",
  100,
  ["127.0.0.1:5504"]
)

{:ok, %{"search_id" => search_id}} = Search.get_id(client, query)
{:ok, result} = Search.get_result(client, search_id)
```

### Instance Information

```elixir
{:ok, user_prefs} = Search.user_preference(client)
{:ok, repos}      = Search.logpoint_repos(client)
{:ok, devices}    = Search.devices(client)
```

### Incident Management

```elixir
alias LogpointApi.Core.Incident

# List incidents within a time range
{:ok, incidents} = Incident.list(client, 1_714_986_600, 1_715_031_000)
{:ok, states}    = Incident.list_states(client, 1_714_986_600, 1_715_031_000)

# Get a specific incident
{:ok, incident} = Incident.get(client, "incident_obj_id", "incident_id")

# Add comments
comments = [LogpointApi.comment("incident_id_1", "This needs attention")]
{:ok, _} = Incident.add_comments(client, comments)

# Assign and update states
{:ok, _} = Incident.assign(client, ["incident_id_1"], "user_id")
{:ok, _} = Incident.resolve(client, ["incident_id_1"])
{:ok, _} = Incident.close(client, ["incident_id_2"])
{:ok, _} = Incident.reopen(client, ["incident_id_3"])

# Get users
{:ok, users} = Incident.get_users(client)
```

### Alert Rules

Alert rules handle JWT token generation internally:

```elixir
alias LogpointApi.Core.AlertRule

{:ok, rules} = AlertRule.list(client)
{:ok, rule}  = AlertRule.get(client, "rule-id")
{:ok, _}     = AlertRule.activate(client, ["id1", "id2"])
{:ok, _}     = AlertRule.deactivate(client, ["id1"])
{:ok, _}     = AlertRule.delete(client, ["id1"])
{:ok, notif} = AlertRule.get_notification(client, "rule-id", :email)
```

#### Alert Rule Builder

Build rules with a composable pipeline instead of raw maps:

```elixir
alias LogpointApi.Data.Rule

rule =
  LogpointApi.rule("Brute Force Detection")
  |> Rule.description("Detects brute force login attempts")
  |> Rule.query("error_code=4625")
  |> Rule.time_range("Last 24 hours")
  |> Rule.repos(["10.0.0.1"])
  |> Rule.limit(100)
  |> Rule.threshold(:above, 5)
  |> Rule.risk_level("high")
  |> Rule.mitre_tags(["T1110"])

{:ok, _} = AlertRule.create(client, rule)
```

#### Notification Builders

```elixir
alias LogpointApi.Data.EmailNotification
alias LogpointApi.Data.HttpNotification

# Email notification
notif =
  LogpointApi.email_notification(["rule-1"], "admin@example.com")
  |> EmailNotification.subject("Alert: {{ rule_name }}")
  |> EmailNotification.template("<p>Details</p>")

{:ok, _} = AlertRule.create_email_notification(client, notif)

# HTTP notification
webhook =
  LogpointApi.http_notification(["rule-1"], "https://hooks.slack.com/abc", :post)
  |> HttpNotification.body(~s({"text": "{{ rule_name }}"}))
  |> HttpNotification.bearer_auth("my-token")

{:ok, _} = AlertRule.create_http_notification(client, webhook)
```

### Logpoint Repos and User-Defined Lists

```elixir
alias LogpointApi.Core.LogpointRepo
alias LogpointApi.Core.UserDefinedList

{:ok, repos} = LogpointRepo.list(client)
{:ok, lists} = UserDefinedList.list(client)
```

## SSL Configuration

Pass `ssl_verify: false` to disable SSL verification (e.g. for self-signed certificates):

```elixir
client = LogpointApi.client("https://192.168.1.100", "admin", "your_secret_key", ssl_verify: false)
```

## Error Handling

All functions return `{:ok, result}` or `{:error, reason}` tuples:

```elixir
alias LogpointApi.Core.Search

case Search.get_id(client, query) do
  {:ok, %{"search_id" => search_id}} ->
    IO.puts("Search started: #{search_id}")

  {:error, reason} ->
    IO.puts("Search failed: #{inspect(reason)}")
end
```

## Contributing

Please refer to [CONTRIBUTING.md](CONTRIBUTING.md) for development guidelines.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
