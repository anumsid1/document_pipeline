defmodule DocumentPipeline.AI.Classifier do
  @callback classify(raw_text :: String.t()) ::
              {:ok, String.t()} | {:error, atom()}

  def classify(raw_text) do
    adapter().classify(raw_text)
  end

  def adapter do
    Application.get_env(
      :document_pipeline,
      :classifier_adapter,
      DocumentPipeline.AI.Classifier.DefaultAdapter
    )
  end
end
