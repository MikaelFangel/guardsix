# Polling for Search Results

The Logpoint search API is asynchronous — you submit a query with `Search.get_id/2`
and then poll with `Search.get_result/2` until results are ready. This library
doesn't include a polling helper on purpose, since the right strategy depends on
your application (GenServer, Task.async, simple loop, etc.).

Here's an example based on how v1's `run_search` worked:

```elixir
defmodule MyApp.SearchPoller do
  alias LogpointApi.Core.Search

  def run(client, query, opts \\ []) do
    interval = Keyword.get(opts, :interval, 1_000)
    max_attempts = Keyword.get(opts, :max_attempts, 60)

    with {:ok, %{"search_id" => search_id}} <- Search.get_id(client, query) do
      poll(client, query, search_id, interval, max_attempts, 1)
    end
  end

  defp poll(_client, _query, _search_id, _interval, max, attempt) when attempt > max do
    {:error, :timeout}
  end

  defp poll(client, query, search_id, interval, max, attempt) do
    case Search.get_result(client, search_id) do
      {:ok, %{"final" => true} = result} ->
        {:ok, result}

      {:ok, %{"final" => false}} ->
        Process.sleep(interval)
        poll(client, query, search_id, interval, max, attempt + 1)

      # The API can return success: false when the search expires.
      # Resubmit the original query to get a fresh search ID.
      {:ok, %{"success" => false}} ->
        case Search.get_id(client, query) do
          {:ok, %{"search_id" => new_id}} ->
            poll(client, query, new_id, interval, max, attempt + 1)

          error ->
            error
        end

      {:error, _} = error ->
        error
    end
  end
end
```

Usage:

```elixir
client = LogpointApi.client("https://logpoint.company.com", "admin", "secret")
query = LogpointApi.search_params("user=*", "Last 24 hours", 100, ["127.0.0.1:5504"])

{:ok, result} = MyApp.SearchPoller.run(client, query)
```

The key detail is the `success: false` handling — Logpoint can expire a search,
so the poller resubmits the original query to get a new search ID and keeps going.

Adapt the polling logic to fit your needs — add exponential backoff, wire it
into a GenServer, or use `Task.async` if you want to search in the background.
