# [Feature] Multi-provider token and energy tracking
Labels: enhancement

## Summary

Add support for tracking token usage and environmental impact from multiple AI model providers, not just Anthropic/Claude.

## Motivation

Users often work with multiple AI providers (OpenAI, Google, Anthropic, local models, etc.). Having a unified view of token usage and energy consumption across all providers would provide:

- Complete picture of AI usage habits
- Consolidated environmental impact tracking
- Better cost awareness across providers
- Single dashboard for all AI interactions

## Potential Providers to Support

- **OpenAI** (GPT-4, GPT-3.5, etc.)
- **Google** (Gemini)
- **Anthropic** (Claude) - already supported
- **Local models** (Ollama, LM Studio)
- **Other cloud providers** (Cohere, Mistral, etc.)

## Implementation Considerations

1. **Data Sources**: Each provider has different logging formats and locations
2. **Energy Methodology**: May need provider-specific energy estimates based on model architecture and hosting
3. **UI Updates**: Aggregate view + per-provider breakdown
4. **Architecture**: Plugin/adapter pattern for adding new providers

## Open Questions

- Which providers should be prioritized first?
- How to handle providers without clear energy consumption data?
- Should local model tracking use different energy calculations (user's hardware vs cloud)?
