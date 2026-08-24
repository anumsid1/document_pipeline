defmodule DocumentPipeline.AI.Extractor.DefaultAdapter do
  @behaviour DocumentPipeline.AI.Extractor

  @prompts %{
    "invoice" => """
    Extract from this invoice. Return ONLY valid JSON:
    {
      "fields": {
        "vendor_name": "string",
        "invoice_number": "string",
        "invoice_date": "YYYY-MM-DD",
        "total_amount": number
      },
      "line_items": [
        {"description": "string", "amount": number, "category": "string or null"}
      ]
    }
    """,
    "budget" => """
    Extract from this budget. Return ONLY valid JSON:
    {
      "fields": {
        "project_name": "string",
        "total_budget": number
      },
      "line_items": [
        {"description": "string", "amount": number, "category": "string or null"}
      ]
    }
    """,
    "change_order" => """
    Extract from this change order. Return ONLY valid JSON:
    {
      "fields": {
        "change_order_number": "string",
        "description": "string",
        "amount": number,
        "requested_by": "string"
      },
      "line_items": []
    }
    """,
    "pay_application" => """
    Extract from this pay application. Return ONLY valid JSON:
    {
      "fields": {
        "contractor_name": "string",
        "application_number": "string",
        "period_to": "YYYY-MM-DD",
        "total_amount": number
      },
      "line_items": [
        {"description": "string", "amount": number, "category": "string or null"}
      ]
    }
    """
  }

  @impl true
  def extract(domain_type, raw_text) do
    prompt = Map.get(@prompts, domain_type)

    body = %{
      model: "claude-sonnet-4-6",
      max_tokens: 2000,
      messages: [
        %{role: "user", content: "#{prompt}\n\nDocument:\n#{raw_text}"}
      ]
    }

    case Req.post("https://api.anthropic.com/v1/messages",
           json: body,
           headers: [
             {"x-api-key", api_key()},
             {"anthropic-version", "2023-06-01"},
             {"content-type", "application/json"}
           ],
           receive_timeout: 15_000
         ) do
      {:ok, %Req.Response{status: 200, body: response}} ->
        text =
          response["content"]
          |> List.first()
          |> Map.get("text")
          |> String.trim()

        parse_extraction(text)

      {:ok, %Req.Response{status: status}} ->
        {:error, {:api_error, status}}

      {:error, reason} ->
        {:error, {:request_failed, reason}}
    end
  end

  defp parse_extraction(text) do
    cleaned =
      text
      |> String.replace(~r/```json\n?/, "")
      |> String.replace(~r/```\n?/, "")
      |> String.trim()

    case Jason.decode(cleaned) do
      {:ok, data} -> {:ok, data}
      {:error, _} -> {:error, :invalid_json}
    end
  end

  defp api_key, do: Application.get_env(:document_pipeline, :anthropic_api_key)
end
