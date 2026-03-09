# Rules for working with LogpointApi

## Architecture

LogpointApi is a stateless wrapper around the Logpoint SIEM API. There is no OTP process or connection pool — every function call makes a direct HTTP request.

All API calls require a `Client` struct. Always create it through the facade:

```elixir
client = LogpointApi.client("https://logpoint.company.com", "admin", "secret_key")
```

Never construct `Client`, `Credential`, or other data structs directly. Use the facade functions in `LogpointApi`:
- `LogpointApi.client/3,4` — client
- `LogpointApi.search_params/4,5` — search query parameters
- `LogpointApi.comment/2` — incident comment
- `LogpointApi.rule/1` — alert rule builder
- `LogpointApi.email_notification/2` — email notification builder
- `LogpointApi.http_notification/3` — HTTP notification builder

## Module layout

Domain logic lives under `LogpointApi.Core.*`:
- `Search` — search queries, results, instance info
- `Incident` — incident listing, state changes, comments
- `AlertRule` — alert rule CRUD, notifications (includes `update/3` and `get_notification/3`)
- `LogpointRepo` — searchable logpoint repos
- `UserDefinedList` — user-defined lists

Builder structs live under `LogpointApi.Data.*`:
- `Rule` — alert rule builder (pipe through setter functions, pass to `AlertRule.create/2`)
- `EmailNotification` — email notification builder
- `HttpNotification` — HTTP notification builder

Do not use `LogpointApi.Net.*` or `LogpointApi.Auth.*` directly. These are internal.

## Return values

All API functions return `{:ok, map()}` or `{:error, term()}`. The ok value is the decoded JSON response from the Logpoint API as a map with string keys.

## Search is asynchronous

Search requires two steps: submit the query, then poll for results. Use `run_search/3` for automatic polling:

```elixir
query = LogpointApi.search_params("user=*", "Last 24 hours", 100, ["127.0.0.1"])
{:ok, result} = LogpointApi.run_search(client, query)
```

Expired searches (`success: false`) are resubmitted automatically.

For custom polling, use the low-level primitives:

```elixir
{:ok, %{"search_id" => id}} = Search.get_id(client, query)
{:ok, result} = Search.get_result(client, id)
```

Poll `get_result/2` until `result["final"] == true`. Handle `result["success"] == false` by resubmitting with `get_id/2` to get a fresh search ID (the search expired server-side).

## Alert rule time ranges

`Rule.time_range/2,3` accepts a value and an optional unit (`:minute`, `:hour`, `:day`). Default unit is `:minute`. Only one time range field is sent to the API — the last call wins.

Limits: minutes 1–59, hours 1–720, days 1–30. Values outside these ranges raise `FunctionClauseError`. Minutes >= 60 auto-promote to hours, hours > 720 auto-promote to days.

```elixir
Rule.time_range(rule, 30)           # 30 minutes
Rule.time_range(rule, 12, :hour)    # 12 hours
Rule.time_range(rule, 1, :day)      # 1 day
Rule.time_range(rule, 120)          # auto-promotes to 2 hours
```

## Alert rule required fields

`Rule.validate/1` checks that these fields are set before API submission: `name`, `query`, `repos`, `threshold_option`, `threshold_value`, `risk_level`, `aggregation_type`, `assignee`, and at least one time range field.

`AlertRule.create/2` calls `validate/1` automatically.

## SSL verification

SSL verification is enabled by default. Pass `ssl_verify: false` only for self-signed certificates in isolated environments:

```elixir
client = LogpointApi.client("https://192.168.1.100", "admin", "secret", ssl_verify: false)
```

## Authentication

The library handles authentication internally. Search and incident endpoints send credentials in the request body. Alert rule, repo, and list endpoints use JWT bearer tokens generated from the same credentials. You do not need to manage tokens.
