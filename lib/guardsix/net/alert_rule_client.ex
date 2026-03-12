defmodule Guardsix.Net.AlertRuleClient do
  @moduledoc false

  alias Guardsix.Net.BaseClient

  defdelegate new(base_url, ssl_verify \\ true), to: BaseClient

  def get(req, path, token, params \\ %{}) do
    req = Req.merge(req, auth: {:bearer, token})

    BaseClient.decode_response(Req.get(req, url: path, params: params))
  end

  def post(req, path, token, body) do
    req = Req.merge(req, auth: {:bearer, token})

    BaseClient.decode_response(Req.post(req, url: path, json: body))
  end

  def post_form(req, path, token, body) do
    req = Req.merge(req, auth: {:bearer, token})

    BaseClient.decode_response(Req.post(req, url: path, form: body))
  end
end
