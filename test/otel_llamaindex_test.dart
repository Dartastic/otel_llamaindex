// Licensed under the Dartastic Pro Software License Agreement.
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_llamaindex/otel_llamaindex.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_llamaindex-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('asQueryEngine.query records retriever + LLM + tokens', () async {
    await tracedLlamaIndex<String>(
      operation: 'asQueryEngine.query',
      invoke: () async => const LlamaIndexCallResult(
        value: 'ok',
        result: LlamaIndexResult(
          stage: 'synthesis',
          indexKind: 'VectorStoreIndex',
          retrieverKind: 'hybrid',
          similarityTopK: 8,
          nodeCount: 8,
          maxSimilarityScore: 0.91,
          synthesisMode: 'compact',
          llmProvider: 'openai',
          llmModel: 'gpt-4o-mini',
          promptTokens: 1820,
          completionTokens: 312,
          totalTokens: 2132,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('llamaindex asQueryEngine.query')!);
    expect(a['llamaindex.retriever.kind'], 'hybrid');
    expect(a['llamaindex.synthesis.mode'], 'compact');
    expect(a['llamaindex.usage.total_tokens'], 2132);
  });

  test('agent.run records steps + tool calls', () async {
    await tracedLlamaIndex<String>(
      operation: 'agent.run',
      invoke: () async => const LlamaIndexCallResult(
        value: 'ok',
        result: LlamaIndexResult(
          stage: 'agent',
          agentSteps: 4,
          toolCalls: 6,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('llamaindex agent.run')!);
    expect(a['llamaindex.agent.steps'], 4);
    expect(a['llamaindex.agent.tool_calls'], 6);
  });

  test('workflow error sets span error', () async {
    await tracedLlamaIndex<String>(
      operation: 'workflow.run',
      invoke: () async => const LlamaIndexCallResult(
        value: 'ok',
        result: LlamaIndexResult(
          workflowName: 'rag_pipeline',
          workflowEvent: 'error',
        ),
      ),
    );
    expect(
      spans.findSpanByName('llamaindex workflow.run')!.status,
      SpanStatusCode.Error,
    );
  });

  test('recursion_limit error', () async {
    await tracedLlamaIndex<String>(
      operation: 'agent.run',
      invoke: () async => const LlamaIndexCallResult(
        value: 'ok',
        result: LlamaIndexResult(errorKind: 'recursion_limit'),
      ),
    );
    expect(
      spans.findSpanByName('llamaindex agent.run')!.status,
      SpanStatusCode.Error,
    );
  });

  test('suppression skips spans', () async {
    await runWithoutLlamaIndexInstrumentationAsync(() async {
      await tracedLlamaIndex<String>(
        operation: 'index.persist',
        invoke: () async => const LlamaIndexCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('llamaindex '), isEmpty);
  });
}
