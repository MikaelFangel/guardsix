defmodule Guardsix.Auth.SessionProvider do
  @moduledoc """
  Establishes an authenticated browser session with a Guardsix instance.

  Used for UI endpoints that do not support JWT authentication. This works by
  scraping the landing page for CSRF tokens and session cookies, then logging
  in via the same form the browser uses. This approach is **unstable** and may
  break if LogPoint changes its login flow or page structure.
  """

  alias Guardsix.Data.Session
  alias Guardsix.Net.BaseClient

  @csrf_pattern ~r/CSRFToken\s*=\s*"([^"]+)"/
  @auth_pattern ~r/DEFAULT_AUTH\s*=\s*"([^"]+)"/
  @session_pattern ~r/session=([^;]+)/
  @expires_pattern ~r/Expires=([^;]+)/
  @session_ttl_seconds 24 * 60 * 60

  @spec login(String.t(), String.t(), String.t(), keyword()) ::
          {:ok, Session.t()} | {:error, term()}
  def login(base_url, username, password, opts \\ []) do
    ssl_verify = Keyword.get(opts, :ssl_verify, true)
    base_req = BaseClient.new(base_url, ssl_verify)

    with {:ok, pre_session, csrf_token, auth_method} <- fetch_landing_page(base_req),
         pre_req = Req.merge(base_req, headers: [{"cookie", "session=#{pre_session}"}]),
         {:ok, expires_at} <- do_login(pre_req, username, password, csrf_token, auth_method),
         {:ok, post_login_csrf} <- fetch_csrf_token(pre_req) do
      {:ok,
       %Session{
         req: pre_req,
         csrf_token: post_login_csrf,
         username: username,
         expires_at: expires_at
       }}
    end
  end

  defp fetch_landing_page(req) do
    case Req.get(req) do
      {:ok, %{status: 200, body: body, headers: headers}} ->
        with [_, csrf] <- Regex.run(@csrf_pattern, body),
             [_, auth] <- Regex.run(@auth_pattern, body),
             {:ok, session} <- extract_session_cookie(headers) do
          {:ok, session, csrf, auth}
        else
          nil -> {:error, "failed to extract CSRF token or auth method from landing page"}
          {:error, _} = error -> error
        end

      {:ok, %{status: status}} ->
        {:error, "expected HTTP 200, got #{status}"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp fetch_csrf_token(req) do
    case Req.get(req) do
      {:ok, %{status: 200, body: body}} ->
        case Regex.run(@csrf_pattern, body) do
          [_, token] -> {:ok, token}
          nil -> {:error, "CSRF token not found"}
        end

      {:ok, %{status: status}} ->
        {:error, "expected HTTP 200, got #{status}"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp do_login(req, username, password, csrf_token, auth_method) do
    body = %{
      requestType: "formsubmit",
      id: "",
      username: username,
      password: password,
      url_hash: "",
      CSRFToken: csrf_token
    }

    login_path = "/pluggables/Authentication/#{auth_method}/login"

    case Req.post(req, url: login_path, form: body, redirect: false) do
      {:ok, %{status: 200, body: resp_body, headers: headers}} ->
        case Jason.decode(resp_body) do
          {:ok, %{"success" => true}} ->
            {:ok, parse_expires(headers)}

          {:ok, %{"success" => false, "message" => msg}} when msg in ["", nil] ->
            {:error, "login failed: invalid credentials"}

          {:ok, %{"message" => message}} ->
            {:error, message}

          {:error, _} ->
            {:error, "failed to parse login response"}
        end

      {:ok, %{status: status}} ->
        {:error, "login failed with status #{status}"}

      {:error, error} ->
        {:error, error}
    end
  end

  defp parse_expires(headers) do
    Enum.find_value(collect_cookies(headers), default_expires(), fn cookie ->
      case Regex.run(@expires_pattern, cookie) do
        [_, expires_str] -> parse_http_date(expires_str)
        nil -> nil
      end
    end)
  end

  # Parses RFC 7231 IMF-fixdate format: "Tue, 24 Mar 2026 10:31:04 GMT"
  defp parse_http_date(date_string) do
    case Regex.run(
           ~r/\w+,\s+(\d+)\s+(\w+)\s+(\d+)\s+(\d+):(\d+):(\d+)\s+GMT/,
           String.trim(date_string)
         ) do
      [_, day, month, year, hour, min, sec] ->
        case NaiveDateTime.new(
               String.to_integer(year),
               month_to_number(month),
               String.to_integer(day),
               String.to_integer(hour),
               String.to_integer(min),
               String.to_integer(sec)
             ) do
          {:ok, ndt} -> DateTime.from_naive!(ndt, "Etc/UTC")
          _ -> nil
        end

      _ ->
        nil
    end
  end

  @months [
    {"Jan", 1},
    {"Feb", 2},
    {"Mar", 3},
    {"Apr", 4},
    {"May", 5},
    {"Jun", 6},
    {"Jul", 7},
    {"Aug", 8},
    {"Sep", 9},
    {"Oct", 10},
    {"Nov", 11},
    {"Dec", 12}
  ]
  for {month, number} <- @months do
    defp month_to_number(unquote(month)), do: unquote(number)
  end

  defp default_expires, do: DateTime.add(DateTime.utc_now(), @session_ttl_seconds)

  defp extract_session_cookie(headers) do
    case Enum.find_value(collect_cookies(headers), fn cookie ->
           case Regex.run(@session_pattern, cookie) do
             [_, session] -> session
             nil -> nil
           end
         end) do
      nil -> {:error, "no session cookie in response"}
      session -> {:ok, session}
    end
  end

  defp collect_cookies(headers) do
    for {"set-cookie", values} <- headers,
        cookie <- List.wrap(values),
        do: cookie
  end
end
