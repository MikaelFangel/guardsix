defmodule Guardsix.Net.SearchIncidentClient do
  @moduledoc false

  alias Guardsix.Net.BaseClient

  defdelegate new(base_url, ssl_verify \\ true), to: BaseClient

  def get(req, path, credential, body \\ %{}) do
    body = body_with_credential(credential, body)

    BaseClient.decode_response(Req.get(req, url: path, json: body))
  end

  def post(req, path, credential, body, content_type) when content_type in [:json, :form] do
    request_body = body_with_credential(credential, body)

    result =
      case content_type do
        :json -> Req.post(req, url: path, json: request_body)
        :form -> Req.post(req, url: path, form: request_body)
      end

    BaseClient.decode_response(result)
  end

  def post_json(req, path, credential, body) do
    post(req, path, credential, body, :json)
  end

  def post_form(req, path, credential, body) do
    post(req, path, credential, body, :form)
  end

  defp body_with_credential(%Guardsix.Data.Credential{username: username, secret_key: secret}, body) do
    Map.merge(%{username: username, secret_key: secret}, body)
  end
end
