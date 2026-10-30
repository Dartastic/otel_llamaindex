// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_llamaindex/otel_llamaindex.dart';

/// Traces LlamaIndex calls with OpenTelemetry.
///
/// `otel_llamaindex` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each LlamaIndex call in
/// [tracedLlamaIndex]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'llamaindex-example');

  // Wraps a LlamaIndex call in a CLIENT span.
  final llamaIndexId = await tracedLlamaIndex<String>(
    operation: 'index.insert',
    invoke: () async {
      // Make the LlamaIndex call here, then report what it returned.
      const id = 'llamaindex_8f3a2c';
      return const LlamaIndexCallResult(
          value: id,
          result: LlamaIndexResult(
              stage: 'ingestion',
              indexKind: 'VectorStoreIndex',
              indexId: 'index_8f3a2c',
              docCount: 3,
              chunkCount: 3,
              tokensIngested: 128,
              embeddingModel: 'openai-text-embedding-3-small',
              llmProvider: 'openai',
              llmModel: 'gpt-4o-mini',
              retrieverKind: 'vector',
              similarityTopK: 1,
              nodeCount: 3,
              minSimilarityScore: 0.5,
              maxSimilarityScore: 0.5,
              synthesisMode: 'tree_summarize',
              promptTokens: 128,
              completionTokens: 128,
              totalTokens: 128,
              agentSteps: 1,
              toolCalls: 1,
              workflowName: 'example',
              workflowEvent: 'order.created',
              errorKind: 'prompt_too_long',
              errorMessage: 'example'));
    },
  );
  OTelLog.info('tracedLlamaIndex index.insert returned $llamaIndexId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutLlamaIndexInstrumentationAsync.
  await runWithoutLlamaIndexInstrumentationAsync(
    () => tracedLlamaIndex<String>(
      operation: 'index.insert',
      invoke: () async {
        const id = 'llamaindex_8f3a2c';
        return const LlamaIndexCallResult(
            value: id,
            result: LlamaIndexResult(
                stage: 'ingestion',
                indexKind: 'VectorStoreIndex',
                indexId: 'index_8f3a2c',
                docCount: 3,
                chunkCount: 3,
                tokensIngested: 128,
                embeddingModel: 'openai-text-embedding-3-small',
                llmProvider: 'openai',
                llmModel: 'gpt-4o-mini',
                retrieverKind: 'vector',
                similarityTopK: 1,
                nodeCount: 3,
                minSimilarityScore: 0.5,
                maxSimilarityScore: 0.5,
                synthesisMode: 'tree_summarize',
                promptTokens: 128,
                completionTokens: 128,
                totalTokens: 128,
                agentSteps: 1,
                toolCalls: 1,
                workflowName: 'example',
                workflowEvent: 'order.created',
                errorKind: 'prompt_too_long',
                errorMessage: 'example'));
      },
    ),
  );

  await OTel.shutdown();
}
