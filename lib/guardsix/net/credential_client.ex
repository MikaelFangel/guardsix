defmodule Guardsix.Net.CredentialClient do
  @moduledoc false

  alias Guardsix.Net.BaseClient

  defdelegate new(base_url, ssl_verify \\ true), to: BaseClient

  def get(req, path, credential, body \\ %{}) do
    body = body_with_credential(credential, body)

    BaseClient.decode_response(Req.get(req, url: path, json: body))
  end

  for {function_name, body_opt} <- [
        post_json: :json,
        post_form: :form
      ] do
    def unquote(function_name)(req, path, credential, body) do
      request_body = body_with_credential(credential, body)

      BaseClient.decode_response(Req.post(req, [{:url, path}, {unquote(body_opt), request_body}]))
    end
  end

  defp body_with_credential(%Guardsix.Data.Credential{username: username, secret_key: secret}, body) do
    Map.merge(%{username: username, secret_key: secret}, body)
  end
end
