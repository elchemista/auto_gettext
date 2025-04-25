defmodule AutoGettext.API do
  @moduledoc """
  Behaviour for a module that actually talks to an LLM or external service.
  """
  @callback get(String.t()) :: String.t() | no_return()
end
