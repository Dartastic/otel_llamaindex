// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';

import 'otel_llamaindex_suppression.dart';

const _tracerName = 'dartastic_otel_libs_llamaindex';

Tracer _tracer() => OTel.tracerProvider().getTracer(_tracerName);

class LlamaIndexResult {
  const LlamaIndexResult({
    this.stage,
    this.indexKind,
    this.indexId,
    this.docCount,
    this.chunkCount,
    this.tokensIngested,
    this.embeddingModel,
    this.llmProvider,
    this.llmModel,
    this.retrieverKind,
    this.similarityTopK,
    this.nodeCount,
    this.minSimilarityScore,
    this.maxSimilarityScore,
    this.synthesisMode,
    this.promptTokens,
    this.completionTokens,
    this.totalTokens,
    this.agentSteps,
    this.toolCalls,
    this.workflowName,
    this.workflowEvent,
    this.errorKind,
    this.errorMessage,
  });

  /// `ingestion`, `retrieval`, `synthesis`, `agent`, `workflow`, `eval`.
  final String? stage;

  /// `VectorStoreIndex`, `SummaryIndex`, `TreeIndex`, `KeywordTableIndex`,
  /// `KnowledgeGraphIndex`, `DocumentSummaryIndex`, `ComposableGraph`,
  /// `MultiModalVectorStoreIndex`.
  final String? indexKind;

  final String? indexId;

  final int? docCount;
  final int? chunkCount;
  final int? tokensIngested;

  /// `openai-text-embedding-3-small`, `cohere-embed-english-v3`, etc.
  final String? embeddingModel;

  /// `openai`, `anthropic`, `azure_openai`, `mistral`, `vertex_ai`,
  /// `aws_bedrock`, `together`, `ollama`, `groq`, `huggingface`.
  final String? llmProvider;

  /// Resolved model id (`gpt-4o-mini`, `claude-3-5-sonnet-20241022`, ...).
  final String? llmModel;

  /// `vector`, `bm25`, `hybrid`, `reranker`, `knowledge_graph`,
  /// `auto_merging`, `recursive`.
  final String? retrieverKind;

  final int? similarityTopK;

  final int? nodeCount;

  final double? minSimilarityScore;
  final double? maxSimilarityScore;

  /// `tree_summarize`, `compact`, `refine`, `accumulate`, `simple_summarize`,
  /// `no_text`.
  final String? synthesisMode;

  final int? promptTokens;
  final int? completionTokens;
  final int? totalTokens;

  final int? agentSteps;
  final int? toolCalls;

  /// LlamaIndex Workflow name + event ('started'/'completed'/'error').
  final String? workflowName;
  final String? workflowEvent;

  /// `prompt_too_long`, `embedding_failed`, `llm_failed`, `index_corrupt`,
  /// `vector_store_unavailable`, `tool_error`, `recursion_limit`.
  final String? errorKind;
  final String? errorMessage;
}

class LlamaIndexCallResult<T> {
  const LlamaIndexCallResult({required this.value, this.result});
  final T value;
  final LlamaIndexResult? result;
}

/// Wraps a LlamaIndex call in a CLIENT span. [operation] is one of
/// `index.fromDocuments`, `index.fromVectorStore`, `index.insert`,
/// `index.delete`, `index.refresh`, `index.persist`, `index.load`,
/// `asQueryEngine.query`, `asChatEngine.chat`, `asRetriever.retrieve`,
/// `serviceContext.embed`, `nodeParser.split`,
/// `documentSummaryIndex.query`, `knowledgeGraphIndex.query`,
/// `agent.run`, `agent.step`, `tool.invoke`, `workflow.run`,
/// `evaluator.evaluate`, `dataset.runBatch`.
Future<T> tracedLlamaIndex<T>({
  required String operation,
  required Future<LlamaIndexCallResult<T>> Function() invoke,
}) async {
  if (llamaIndexInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'llamaindex',
    'rpc.method': operation,
    'llamaindex.operation': operation,
  };

  final span = _tracer().startSpan(
    'llamaindex $operation',
    kind: SpanKind.client,
    attributes: OTel.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final res = r.result!;
      final extras = <Attribute<Object>>[];
      if (res.stage != null) {
        extras.add(OTel.attributeString('llamaindex.stage', res.stage!));
      }
      if (res.indexKind != null) {
        extras.add(OTel.attributeString(
          'llamaindex.index.kind',
          res.indexKind!,
        ));
      }
      if (res.indexId != null) {
        extras.add(OTel.attributeString(
          'llamaindex.index.id',
          res.indexId!,
        ));
      }
      if (res.docCount != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.ingestion.doc_count',
          res.docCount!,
        ));
      }
      if (res.chunkCount != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.ingestion.chunk_count',
          res.chunkCount!,
        ));
      }
      if (res.tokensIngested != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.ingestion.tokens',
          res.tokensIngested!,
        ));
      }
      if (res.embeddingModel != null) {
        extras.add(OTel.attributeString(
          'llamaindex.embedding.model',
          res.embeddingModel!,
        ));
      }
      if (res.llmProvider != null) {
        extras.add(OTel.attributeString(
          'llamaindex.llm.provider',
          res.llmProvider!,
        ));
      }
      if (res.llmModel != null) {
        extras.add(OTel.attributeString(
          'llamaindex.llm.model',
          res.llmModel!,
        ));
      }
      if (res.retrieverKind != null) {
        extras.add(OTel.attributeString(
          'llamaindex.retriever.kind',
          res.retrieverKind!,
        ));
      }
      if (res.similarityTopK != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.retriever.top_k',
          res.similarityTopK!,
        ));
      }
      if (res.nodeCount != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.retriever.node_count',
          res.nodeCount!,
        ));
      }
      if (res.minSimilarityScore != null) {
        extras.add(OTel.attributeDouble(
          'llamaindex.retriever.min_similarity',
          res.minSimilarityScore!,
        ));
      }
      if (res.maxSimilarityScore != null) {
        extras.add(OTel.attributeDouble(
          'llamaindex.retriever.max_similarity',
          res.maxSimilarityScore!,
        ));
      }
      if (res.synthesisMode != null) {
        extras.add(OTel.attributeString(
          'llamaindex.synthesis.mode',
          res.synthesisMode!,
        ));
      }
      if (res.promptTokens != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.usage.prompt_tokens',
          res.promptTokens!,
        ));
      }
      if (res.completionTokens != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.usage.completion_tokens',
          res.completionTokens!,
        ));
      }
      if (res.totalTokens != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.usage.total_tokens',
          res.totalTokens!,
        ));
      }
      if (res.agentSteps != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.agent.steps',
          res.agentSteps!,
        ));
      }
      if (res.toolCalls != null) {
        extras.add(OTel.attributeInt(
          'llamaindex.agent.tool_calls',
          res.toolCalls!,
        ));
      }
      if (res.workflowName != null) {
        extras.add(OTel.attributeString(
          'llamaindex.workflow.name',
          res.workflowName!,
        ));
      }
      if (res.workflowEvent != null) {
        extras.add(OTel.attributeString(
          'llamaindex.workflow.event',
          res.workflowEvent!,
        ));
        if (res.workflowEvent == 'error') {
          span.setStatus(SpanStatusCode.Error, 'LlamaIndex workflow error');
        }
      }
      if (res.errorKind != null) {
        extras.add(OTel.attributeString(
          'llamaindex.error.kind',
          res.errorKind!,
        ));
        span.setStatus(SpanStatusCode.Error, 'LlamaIndex ${res.errorKind}');
      }
      if (res.errorMessage != null) {
        extras.add(OTel.attributeString(
          'llamaindex.error.message',
          res.errorMessage!,
        ));
      }
      if (extras.isNotEmpty) span.addAttributes(OTel.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTel.attributes([
      OTel.attributeString(
        ErrorResource.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
