defmodule Guardsix.Net.BaseClient do
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
    case Jason.decode(body) do
      {:ok, decoded} -> check_success(decoded)
      {:error, _} = error -> error
    end
  end

  # Guardsix uses success: false on their old API to tell you when there is an error.
  def decode_response({:ok, %Req.Response{body: %{"success" => false, "message" => message}}}), do: {:error, message}
  def decode_response({:ok, %Req.Response{body: body}}) when is_map(body), do: check_success(body)
  def decode_response({:error, _} = error), do: error

  defp check_success(%{"success" => false, "message" => message}), do: {:error, message}
  defp check_success(body), do: {:ok, body}
end
