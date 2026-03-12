defmodule Guardsix.Data.Comment do
  @moduledoc """
  An incident comment linking a comment string to an incident ID.

  Built via `Guardsix.comment/2`.
  """
  @derive Jason.Encoder
  @enforce_keys :_id
  defstruct [:_id, comments: []]

  @type t :: %__MODULE__{
          _id: String.t(),
          comments: [String.t()]
        }

  def new(id, comments) when is_list(comments) do
    %__MODULE__{_id: id, comments: comments}
  end

  def new(id, comment) when is_binary(comment) do
    %__MODULE__{_id: id, comments: [comment]}
  end
end
