defmodule DocumentPipeline.AI.Classifier.DefaultAdapter do
  @behaviour DocumentPipeline.AI.Classifier

  @valid_types ~w(invoice budget change_order pay_application)

  @system_prompt """
  You are a construction loan document classifier.
  Classify this document as exactly one of:
  - invoice
  - budget
  - change_order
  - pay_application

  Return ONLY the classification word. No explanation.
  No punctuation. Just the type.
  """

  @impl true
  def classify(raw_text) do
    sample = String.slice(raw_text, 0, 2000)

    body = %{
      model: "claude-sonnet-4-6",
      max_tokens: 50,
      messages: [%{role: "user", content: "#{@system_prompt}\n\nDocument\n#{sample}"}]
    }

    case Req.post("https://api.anthropic.com/v1/messages",
           json: body,
           headers: [
             {"x-api-key", api_key()},
             {"anthropic-version", "2023-06-01"},
             {"content-type", "application/json"}
           ],
           receive_timeout: 10_000
         ) do
      {:ok, %Req.Response{status: 200, body: response}} ->
        type =
          response["content"]
          |> List.first()
          |> Map.get("text")
          |> String.trim()
          |> String.downcase()

        if type in @valid_types do
          {:ok, type}
        else
          {:error, :unknown_type}
        end

      {:ok, %Req.Response{status: status}} ->
        {:error, {:api_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  defp api_key, do: Application.get_env(:document_pipeline, :anthropic_api_key)
end
