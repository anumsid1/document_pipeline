defmodule DocumentPipeline.AI.Classifier.MockAdapter do
  @behaviour DocumentPipeline.AI.Classifier

  @impl true
  def classify(raw_text) do
    cond do
      String.contains?(raw_text, "invoice") -> {:ok, "invoice"}
      String.contains?(raw_text, "budget") -> {:ok, "budget"}
      String.contains?(raw_text, "change order") -> {:ok, "change_order"}
      String.contains?(raw_text, "pay application") -> {:ok, "pay_application"}
      true -> {:ok, "invoice"}
    end
  end
end
