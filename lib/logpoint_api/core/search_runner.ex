defmodule LogpointApi.Core.SearchRunner do
  @moduledoc """
  Blocking polling for Logpoint searches.

  The Logpoint search API is asynchronous — submit a query, then poll for
  results. `run/3` handles the polling loop, including resubmitting expired
  searches automatically.
  """

  alias LogpointApi.Core.Search
  alias LogpointApi.Data.Client
  alias LogpointApi.Data.SearchParams

  @default_polling_interval 1_000
  @default_max_attempts 30

  @doc """
  Run a search and block until final results arrive.

  Polls `Search.get_result/2` until the response contains `"final" => true`.
  When the API returns `"success" => false` (expired search), the original
  query is resubmitted automatically.

  ## Options

    * `:polling_interval` — milliseconds between polls (default: `#{@default_polling_interval}`)
    * `:max_attempts`     — maximum poll iterations (default: `#{@default_max_attempts}`)

  ## Examples

      {:ok, result} = SearchRunner.run(client, query)
      {:ok, result} = SearchRunner.run(client, query, polling_interval: 2_000, max_attempts: 30)

  """
  @spec run(Client.t(), SearchParams.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(%Client{} = client, %SearchParams{} = query, opts \\ []) do
    polling_interval = Keyword.get(opts, :polling_interval, @default_polling_interval)
    max_attempts = Keyword.get(opts, :max_attempts, @default_max_attempts)

    with {:ok, %{"search_id" => search_id}} <- Search.get_id(client, query) do
      poll(client, query, search_id, polling_interval, max_attempts)
    end
  end

  defp poll(client, query, search_id, polling_interval, max_attempts, attempt \\ 1)

  defp poll(_client, _query, _search_id, _polling_interval, max_attempts, attempt) when attempt > max_attempts do
    {:error, :max_attempts_exceeded}
  end

  defp poll(client, query, search_id, polling_interval, max_attempts, attempt) do
    case Search.get_result(client, search_id) do
      {:ok, %{"final" => true} = result} ->
        {:ok, result}

      {:ok, %{"final" => false}} ->
        Process.sleep(polling_interval)
        poll(client, query, search_id, polling_interval, max_attempts, attempt + 1)

      {:ok, %{"success" => false}} ->
        case Search.get_id(client, query) do
          {:ok, %{"search_id" => new_id}} ->
            poll(client, query, new_id, polling_interval, max_attempts, attempt + 1)

          error ->
            error
        end

      {:error, _} = error ->
        error
    end
  end
end
