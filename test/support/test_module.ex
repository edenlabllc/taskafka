defmodule TestModule.Failed do
  @derive {Jason.Encoder, only: [:status_code, :response]}
  defstruct [:status_code, :response]
end
