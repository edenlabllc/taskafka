defmodule TestModule.Meta do
  @derive {Jason.Encoder, only: [:id, :params, :settings]}
  defstruct [:id, :params, :settings]
end

defmodule TestModule.Failed do
  @derive {Jason.Encoder, only: [:status_code, :response]}
  defstruct [:status_code, :response]
end
