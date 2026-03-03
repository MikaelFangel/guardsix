defmodule LogpointApi.Net.AlertRuleClient do
  @moduledoc false
  def new(base_url, ssl_verify \\ true) do
    base_options = [base_url: base_url]

    options =
      if ssl_verify do
        base_options
      else
        base_options ++
          [
            connect_options: [
              transport_opts: [
                verify: :verify_none
              ]
            ]
          ]
      end

    Req.new(options)
  end

  def get(req, path, token, params \\ %{}) do
    req = Req.merge(req, auth: {:bearer, token})

    decode_response(Req.get(req, url: path, params: params))
  end

  def post(req, path, token, body) do
    req = Req.merge(req, auth: {:bearer, token})

    decode_response(Req.post(req, url: path, json: body))
  end

  defp decode_response({:ok, %Req.Response{body: body}}) when is_binary(body) do
    Jason.decode(body)
  end

  defp decode_response({:ok, %Req.Response{body: body}}) when is_map(body) do
    {:ok, body}
  end

  defp decode_response({:error, _} = error), do: error
end
