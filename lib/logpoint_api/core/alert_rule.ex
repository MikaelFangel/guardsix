defmodule LogpointApi.Core.AlertRule do
  @moduledoc false

  alias LogpointApi.Auth.JwtProvider
  alias LogpointApi.Data.Client
  alias LogpointApi.Net.AlertRuleClient

  @doc """
  List alert rules.
  """
  @spec list(Client.t(), map()) :: {:ok, map()} | {:error, term()}
  def list(%Client{} = client, params \\ %{}) do
    with_read_token(client, fn token ->
      AlertRuleClient.get(req(client), "/AlertRules/lists_api", token, params)
    end)
  end

  @doc """
  Get an alert rule by ID.
  """
  @spec get(Client.t(), String.t()) :: {:ok, map()} | {:error, term()}
  def get(%Client{} = client, id) when is_binary(id) do
    with_read_token(client, fn token ->
      AlertRuleClient.get(req(client), "/AlertRules/read_api", token, %{id: id})
    end)
  end

  @doc """
  Create an alert rule.
  """
  @spec create(Client.t(), map()) :: no_return()
  def create(%Client{} = _client, _rule) do
    raise "not yet implemented"
  end

  @doc """
  Update an alert rule.
  """
  @spec update(Client.t(), String.t(), map()) :: no_return()
  def update(%Client{} = _client, _id, _rule) do
    raise "not yet implemented"
  end

  @doc """
  Delete alert rules by IDs.
  """
  @spec delete(Client.t(), [String.t()]) :: {:ok, map()} | {:error, term()}
  def delete(%Client{} = client, ids) when is_list(ids) do
    with_write_token(client, fn token ->
      AlertRuleClient.post(req(client), "/AlertRules/delete_api", token, %{ids: ids})
    end)
  end

  @doc """
  Activate alert rules by IDs.
  """
  @spec activate(Client.t(), [String.t()]) :: {:ok, map()} | {:error, term()}
  def activate(%Client{} = client, ids) when is_list(ids) do
    with_write_token(client, fn token ->
      AlertRuleClient.post(req(client), "/AlertRules/activate_api", token, %{ids: ids})
    end)
  end

  @doc """
  Deactivate alert rules by IDs.
  """
  @spec deactivate(Client.t(), [String.t()]) :: {:ok, map()} | {:error, term()}
  def deactivate(%Client{} = client, ids) when is_list(ids) do
    with_write_token(client, fn token ->
      AlertRuleClient.post(req(client), "/AlertRules/deactivate_api", token, %{ids: ids})
    end)
  end

  @doc """
  Get alert notification by alert ID and type.
  """
  @spec get_notification(Client.t(), String.t(), :email | :http) ::
          {:ok, map()} | {:error, term()}
  def get_notification(%Client{} = client, alert_id, type) when type in [:email, :http] do
    path =
      case type do
        :email -> "/pluggables/Notification/EmailNotification/read_api"
        :http -> "/pluggables/Notification/HTTPNotification/read_api"
      end

    with_read_token(client, fn token ->
      AlertRuleClient.get(req(client), path, token, %{id: alert_id})
    end)
  end

  @doc """
  Update alert notifications.
  """
  @spec update_notifications(Client.t(), [String.t()], map()) :: no_return()
  def update_notifications(%Client{} = _client, _ids, _notification) do
    raise "not yet implemented"
  end

  defp with_read_token(%Client{} = client, fun) do
    case JwtProvider.alert_rule_read_token(client.credential) do
      {:ok, token, _claims} -> fun.(token)
      {:error, _reason} = error -> error
    end
  end

  defp with_write_token(%Client{} = client, fun) do
    case JwtProvider.alert_rule_write_token(client.credential) do
      {:ok, token, _claims} -> fun.(token)
      {:error, _reason} = error -> error
    end
  end

  defp req(%Client{} = client) do
    AlertRuleClient.new(client.base_url, client.ssl_verify)
  end
end
