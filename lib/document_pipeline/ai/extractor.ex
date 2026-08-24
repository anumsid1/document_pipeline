defmodule DocumentPipeline.AI.Extractor do
  @callback extract(domain_type :: String.t(), raw_text :: String.t()) ::
              {:ok, map()} | {:error, atom()}

  def extract(domain_type, raw_text) do
    adapter().extract(domain_type, raw_text)
  end

  defp adapter do
    Application.get_env(
      :document_pipeline,
      :extractor_adapter,
      DocumentPipeline.AI.Extractor.DefaultAdapter
    )
  end
end
