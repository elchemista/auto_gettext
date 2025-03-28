# behaviour
defmodule AutoGettext.Api do
  @moduledoc """
  Documentation for `AutoGettext.Api`.
  """

  @callback get(String.t()) :: String.t()
end
