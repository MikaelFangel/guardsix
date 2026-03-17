defmodule Guardsix.Net.AlertRuleClient do
  @moduledoc false

  alias Guardsix.Net.BaseClient

  defdelegate new(base_url, ssl_verify \\ true), to: BaseClient

  def get(req, path, token, params \\ %{}) do
    req = Req.merge(req, auth: {:bearer, token})

    BaseClient.decode_response(Req.get(req, url: path, params: params))
  end

  for {function_name, body_opt} <- [
        post: :json,
        post_form: :form,
        post_multipart: :form_multipart
      ] do
    def unquote(function_name)(req, path, token, body) do
      req = Req.merge(req, auth: {:bearer, token})

      BaseClient.decode_response(Req.post(req, [{:url, path}, {unquote(body_opt), body}]))
    end
  end
end
