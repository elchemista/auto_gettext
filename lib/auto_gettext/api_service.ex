defmodule AutoGettext.APIService do
  @moduledoc """
  Behaviour for modules in charge of contacting an external translation service
  (for example Google Gemini or OpenAI).

  Implementations receive the full prompt prepared by a translator and must
  return the raw text produced by the provider. Any error should raise so it can
  be logged by the caller.
  """

  @callback get(String.t()) :: String.t() | no_return()
end

defmodule AutoGettext.API do
  @moduledoc """
  Deprecated name for `AutoGettext.APIService`.

  This module is kept for backwards compatibility with existing integrations.
  New code should implement `AutoGettext.APIService` instead.
  """

  @callback get(String.t()) :: String.t() | no_return()
end
