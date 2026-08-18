defmodule Guardsix.Net.BaseClient do
  @moduledoc false

  alias Guardsix.Error

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

  # Guardsix uses success: false on their old API to tell you when there is an error.
  def decode_response({:ok, %Req.Response{status: status, body: body}}) when is_binary(body) do
    case Jason.decode(body) do
      {:ok, decoded} -> check_success(decoded, status)
      {:error, exception} -> {:error, %Error.Transport{cause: exception, status: status, body: body}}
    end
  end

  def decode_response({:ok, %Req.Response{status: status, body: body}}) when is_map(body),
    do: check_success(body, status)

  def decode_response({:error, exception}), do: {:error, %Error.Transport{cause: exception}}

  defp check_success(%{"success" => false} = body, status), do: {:error, Error.from_response(body, status)}
  defp check_success(body, _status), do: {:ok, body}
end
