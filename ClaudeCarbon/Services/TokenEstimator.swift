import Foundation

/// Estimates token counts from prompt text using character-based approximation.
///
/// Provides a simple, dependency-free way to estimate input and output tokens
/// for AI prompts. Uses configurable character-to-token ratio and an output
/// multiplier to account for generation cost differences.
class TokenEstimator {
    private let methodology: Methodology

    /// Initialize with optional custom methodology.
    /// - Parameter methodology: Configuration for token estimation. Defaults to `Methodology.default`.
    init(methodology: Methodology = .default) {
        self.methodology = methodology
    }

    /// Estimate input tokens from prompt text.
    /// - Parameter text: The prompt text to estimate tokens for.
    /// - Returns: Estimated token count. Minimum 1 for any non-empty text, 0 for empty strings.
    func estimateInputTokens(from text: String) -> Int {
        guard !text.isEmpty else { return 0 }
        let charCount = text.count
        return max(1, charCount / methodology.charsPerToken)
    }

    /// Estimate output tokens based on input token count.
    ///
    /// Output tokens are estimated as more expensive than input tokens,
    /// using the methodology's output multiplier.
    /// - Parameter inputTokens: The number of input tokens.
    /// - Returns: Estimated output token count.
    func estimateOutputTokens(fromInputTokens inputTokens: Int) -> Int {
        return Int(Double(inputTokens) * methodology.outputMultiplier)
    }

    /// Estimate total tokens for a prompt.
    ///
    /// Combines input and output token estimates into a single calculation.
    /// - Parameter text: The prompt text to estimate tokens for.
    /// - Returns: A tuple containing input tokens, output tokens, and their sum.
    func estimateTotalTokens(from text: String) -> (input: Int, output: Int, total: Int) {
        let input = estimateInputTokens(from: text)
        let output = estimateOutputTokens(fromInputTokens: input)
        return (input, output, input + output)
    }
}
