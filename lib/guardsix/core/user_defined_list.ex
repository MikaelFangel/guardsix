defmodule Guardsix.Core.UserDefinedList do
  @moduledoc """
  Manage user-defined lists in Guardsix.

  Wraps the [User Defined Lists API](https://docs.guardsix.com/siem/product-docs/readme/siem_api_reference/user-defined-lists-api).

  Functions accepting a `Client` use JWT authentication and are stable.

  Functions accepting a `Session` (`extract`, `update_static`, `delete`) use
  session-based authentication by mimicking browser requests against internal
  LogPoint UI endpoints. These are **unstable** and may break if LogPoint
  changes its login flow, CSRF handling, or internal form fields.
  """

  alias Guardsix.Auth.JwtProvider
  alias Guardsix.Data.Client
  alias Guardsix.Data.Session
  alias Guardsix.Net.AlertRuleClient
  alias Guardsix.Net.BaseClient

  @doc """
  List user defined lists.

  Supported keys in `params`:

    * `:limit` - maximum number of lists to return
    * `:page` - page number for pagination
    * `:return_all_data` - when `true`, returns all list data

  ## Examples

      UserDefinedList.list(client)
      UserDefinedList.list(client, %{limit: 25, page: 2})

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
  def import_static(%Client{} = client, name, content) when is_binary(name) and is_binary(content) do
    body = %{
      package_import_name: name,
      package_import: {content, filename: "#{name}.csv", content_type: "text/csv"}
    }

    with_write_token(client, fn token ->
      AlertRuleClient.post_multipart(req(client), "/UserDefinedList/import_api", token, body)
    end)
  end

  @doc """
  Extract the contents of a user-defined list by ID.

  Requires a `Session` since this endpoint does not support JWT.

  ## Examples

      {:ok, session} = Guardsix.session("https://guardsix.example.com", "admin", "password")
      UserDefinedList.extract(session, "69c1119e549c866b966d0959")

  """
  @spec extract(Session.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def extract(%Session{} = session, id) when is_binary(id) do
    with :ok <- check_session(session) do
      BaseClient.decode_response(
        Req.post(session.req, url: "/UserDefinedList/extract", form: session_fields(session, %{id: id}))
      )
    end
  end

  @doc """
  Update a static list by ID.

  Fetches the current list state, replaces the values, and saves.
  Requires a `Session` since this endpoint does not support JWT.

  ## Examples

      {:ok, session} = Guardsix.session("https://guardsix.example.com", "admin", "password")
      UserDefinedList.update_static(session, "69c1...", ["val1", "val2"])

  """
  @spec update_static(Session.t(), String.t(), [String.t()]) :: {:ok, map()} | {:error, term()}
  def update_static(%Session{} = session, id, values) when is_binary(id) and is_list(values) do
    case extract(session, id) do
      {:ok, %{"data" => data}} ->
        body =
          session_fields(session, %{
            requestType: "formsubmit",
            launchType: "popup",
            id: id,
            list_type: data["list_type"] || "static_list",
            s_name: data["s_name"] || "",
            lists: Jason.encode!(values),
            lists_vendor: data["lists_vendor"] || "",
            d_name: data["d_name"] || "",
            source_type: data["source_type"] || "DynamicList",
            source_id: data["source_id"] || "",
            agelimit_day: data["agelimit_day"] || "0",
            agelimit_hour: data["agelimit_hour"] || "0",
            agelimit_minute: data["agelimit_minute"] || "30",
            agelimit_second: data["agelimit_second"] || "0"
          })

        BaseClient.decode_response(Req.post(session.req, url: "/UserDefinedList/create", form: body))

      {:ok, response} ->
        {:error, {:unexpected_response, response}}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Delete a user-defined list by ID.

  Requires a `Session` since this endpoint does not support JWT.

  ## Examples

      {:ok, session} = Guardsix.session("https://guardsix.example.com", "admin", "password")
      UserDefinedList.delete(session, "69c1119e549c866b966d0959")

  """
  @spec delete(Session.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def delete(%Session{} = session, id) when is_binary(id) do
    with :ok <- check_session(session) do
      # id is sent in both the query string and form body to match the LogPoint UI behavior
      BaseClient.decode_response(
        Req.post(session.req, url: "/UserDefinedList/delete?id=#{id}", form: session_fields(session, %{id: id}))
      )
    end
  end

  defp session_fields(%Session{} = session, extra) do
    Map.merge(extra, %{CSRFToken: session.csrf_token, LOGGEDINUSER: session.username})
  end

  defp check_session(%Session{} = session) do
    if Session.expired?(session), do: {:error, :session_expired}, else: :ok
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
