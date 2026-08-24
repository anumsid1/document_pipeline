defmodule DocumentPipeline.AI.Extractor.MockAdapter do
  @behaviour DocumentPipeline.AI.Extractor

  @impl true
  def extract("invoice", _raw_text) do
    {:ok,
     %{
       "fields" => %{
         "vendor_name" => "ABC Construction",
         "invoice_number" => "INV-2024-001",
         "invoice_date" => "2024-03-15",
         "total_amount" => 45000.00
       },
       "line_items" => [
         %{"description" => "Concrete work", "amount" => 25000.00, "category" => "Materials"},
         %{"description" => "Labor", "amount" => 20000.00, "category" => "Labor"}
       ]
     }}
  end

  def extract("budget", _raw_text) do
    {:ok,
     %{
       "fields" => %{
         "project_name" => "123 Main Street Development",
         "total_budget" => 2_500_000.00
       },
       "line_items" => [
         %{"description" => "Foundation", "amount" => 350_000.00, "category" => "Hard Costs"},
         %{"description" => "Framing", "amount" => 500_000.00, "category" => "Hard Costs"},
         %{"description" => "Electrical", "amount" => 200_000.00, "category" => "Hard Costs"}
       ]
     }}
  end

  def extract("change_order", _raw_text) do
    {:ok,
     %{
       "fields" => %{
         "change_order_number" => "CO-001",
         "description" => "Additional foundation work",
         "amount" => 15000.00,
         "requested_by" => "Site Manager"
       },
       "line_items" => []
     }}
  end

  def extract("pay_application", _raw_text) do
    {:ok,
     %{
       "fields" => %{
         "contractor_name" => "Smith Builders LLC",
         "application_number" => "PA-003",
         "period_to" => "2024-03-31",
         "total_amount" => 125_000.00
       },
       "line_items" => [
         %{
           "description" => "Foundation complete",
           "amount" => 75000.00,
           "category" => "Hard Costs"
         },
         %{"description" => "Framing 50%", "amount" => 50000.00, "category" => "Hard Costs"}
       ]
     }}
  end
end
