defmodule LogpointApi.Net.BaseClient do
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

  def decode_response({:ok, %Req.Response{body: body}}) when is_binary(body) do
    Jason.decode(body)
  end

  def decode_response({:ok, %Req.Response{body: body}}) when is_map(body) do
    {:ok, body}
  end

  def decode_response({:error, _} = error), do: error
end
