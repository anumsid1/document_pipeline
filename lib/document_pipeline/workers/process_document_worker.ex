defmodule DocumentPipeline.Workers.ProcessDocumentWorker do
  use Oban.Worker,
    queue: :document_processing,
    max_attempts: 3,
    unique: [period: 300, fields: [:worker, :args]]

  alias DocumentPipeline.Documents
  require Logger

  @impl true
  def perform(%Oban.Job{args: args}) do
    document_id = args["document_id"]
    skip_classification = args["skip_classification"] || false

    with {:ok, document} <- Documents.get_document(document_id),
         {:ok, document} <- Documents.update_document_status(document, "processing"),
         {:ok, raw_text} <- extract_text(document),
         {:ok, document} <- Documents.save_raw_text(document, raw_text),
         {:ok, domain_type} <- maybe_classify(document, raw_text, skip_classification),
         type_source = if(skip_classification, do: "user", else: "system"),
         {:ok, document} <- Documents.update_document_type(document, domain_type, type_source),
         {:ok, extracted} <- DocumentPipeline.AI.Extractor.extract(domain_type, raw_text),
         {:ok, _} <- save_extracted(document, extracted) do
      Documents.update_document_status(document, "processed")

      # Broadcast completion
      Phoenix.PubSub.broadcast(
        DocumentPipeline.PubSub,
        "document#{document_id}",
        {:document_processed, document_id}
      )

      :ok
    else
      {:error, reason} ->
        Logger.error("Document processing failed: #{inspect(reason)}")

        with {:ok, document} <- Documents.get_document(document_id) do
          Documents.update_document_status(document, "failed", inspect(reason))
        end

        Phoenix.PubSub.broadcast(
          DocumentPipeline.PubSub,
          "document#{document_id}",
          {:document_processed, document_id}
        )

        {:error, reason}
    end
  end

  defp extract_text(%{content_type: "application/pdf"} = document) do
    case File.read(document.storage_path) do
      {:ok, _binary} ->
        {:ok, "Simulated PDF text for #{document.filename}"}

      {:error, reason} ->
        {:error, {:file_read_failed, reason}}
    end
  end

  defp extract_text(%{content_type: ct} = document)
       when ct in [
              "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
              "application/vnd.ms-excel"
            ] do
    case File.read(document.storage_path) do
      {:ok, _binary} ->
        {:ok, "Simulated Excel content for #{document.filename}"}

      {:error, reason} ->
        {:error, {:file_read_failed, reason}}
    end
  end

  defp extract_text(_document), do: {:error, :unsupported_content_type}

  defp maybe_classify(document, _raw_text, true) do
    # Skip classification — user already specified the type
    {:ok, document.domain_type}
  end

  defp maybe_classify(_document, raw_text, false) do
    DocumentPipeline.AI.Classifier.classify(raw_text)
  end

  defp save_extracted(document, %{"fields" => fields, "line_items" => items}) do
    Documents.save_extracted_fields(document, fields)
    Documents.save_line_items(document, items)
    {:ok, document}
  end

  defp save_extracted(document, %{"fields" => fields}) do
    Documents.save_extracted_fields(document, fields)
    {:ok, document}
  end
end
