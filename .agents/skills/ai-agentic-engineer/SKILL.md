---
name: ai-agentic-engineer
description: Architect and deploy production-grade LLM applications, autonomous AI agents, multi-step tool-calling workflows, RAG (Retrieval-Augmented Generation), prompt engineering, and API integrations with Claude, Gemini, OpenAI, and OpenRouter. Use when building AI features, chatbots, agent systems, and automated cognitive pipelines.
---

# Agentic AI & LLM Systems Engineering (`ai-agentic-engineer`)

Guidelines for building reliable, deterministic, and high-performance AI agent architectures, RAG pipelines, and tool-calling agents.

---

## 1. When to Use & Triggers
- Designing multi-agent workflows, autonomous assistants, or conversational systems.
- Implementing RAG pipelines (chunking, embeddings, vector search, reranking).
- Creating reliable Tool / Function Calling schemas with strict schema validation.
- Integrating LLMs via APIs (Anthropic Claude, Google Gemini, OpenAI, OpenRouter).
- Optimizing token usage, latency, prompt caching, and cost.

---

## 2. Core Architectural Principles

### 2.1 Tool / Function Calling Reliability
- Use Pydantic / JSON Schema for exact argument validation.
- Provide descriptive, self-contained docstrings and descriptions for every tool.
- Always include error recovery: when a tool fails, pass the error back to the model for self-correction.

### 2.2 RAG (Retrieval-Augmented Generation)
- **Chunking:** Chunk documents by semantic boundaries (headers, markdown sections, functions) rather than raw arbitrary character counts.
- **Hybrid Search:** Combine keyword search (BM25) with dense vector search (embeddings) for maximum recall and precision.
- **Context Injection:** Include source citations and metadata with each retrieved chunk.

### 2.3 Prompt Engineering Standards
- Use XML tags (`<context>`, `<instructions>`, `<constraints>`, `<output_format>`) to structure prompts.
- Give concrete few-shot examples for complex output schemas.
- Instruct models to "think step-by-step" in chain-of-thought before generating final JSON/code.

---

## 3. What NOT To Do
- ❌ Do NOT allow unvalidated LLM output to directly execute shell commands or database writes without human-in-the-loop or sandboxing.
- ❌ Do NOT stuff entire uncontrolled documents into the context window without preprocessing or chunking.
- ❌ Do NOT rely on prompt phrasing alone for JSON compliance; use structured output modes / tool calling.

---

## 4. Verification Checklist
- [ ] Are prompt schemas structured with clear XML tags and constraints?
- [ ] Does the agent gracefully handle tool execution errors and retry?
- [ ] Is token streaming implemented for responsive user experiences?
- [ ] Are API keys stored securely in environment variables and never logged?
