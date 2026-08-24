# test/doc_pipeline/ai/classifier_test.exs
defmodule DocumentPipeline.AI.ClassifierTest do
  use ExUnit.Case, async: true

  alias DocumentPipeline.AI.Classifier.MockAdapter

  test "classifies invoice text correctly" do
    assert {:ok, "invoice"} = MockAdapter.classify("This is an invoice")
  end

  test "classifies budget text correctly" do
    assert {:ok, "budget"} = MockAdapter.classify("This is a budget")
  end

  test "defaults to invoice for unknown text" do
    assert {:ok, "invoice"} = MockAdapter.classify("random text")
  end
end
