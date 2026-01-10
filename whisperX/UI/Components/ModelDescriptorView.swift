import SwiftUI

/// Displays model characteristics (memory, speed, accuracy) in a compact format.
struct ModelDescriptorView: View {
    let model: WhisperModel

    var body: some View {
        HStack(spacing: 16) {
            // Memory
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f GB", model.memoryRequirementGB))
                    .font(.caption)
            }
            .help("Memory requirement")

            Divider()
                .frame(height: 12)

            // Speed
            HStack(spacing: 4) {
                Image(systemName: "hare")
                    .foregroundStyle(.secondary)
                StarRating(rating: model.speedRating, maxRating: 5)
            }
            .help("Speed rating (higher is faster)")

            Divider()
                .frame(height: 12)

            // Accuracy
            HStack(spacing: 4) {
                Image(systemName: "checkmark.seal")
                    .foregroundStyle(.secondary)
                StarRating(rating: model.accuracyRating, maxRating: 5)
            }
            .help("Accuracy rating (higher is better)")
        }
        .font(.caption)
    }
}

/// A simple star rating display.
private struct StarRating: View {
    let rating: Int
    let maxRating: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .font(.system(size: 8))
                    .foregroundStyle(index <= rating ? .yellow : .secondary.opacity(0.5))
            }
        }
    }
}

#Preview("All Models") {
    VStack(alignment: .leading, spacing: 12) {
        ForEach(WhisperModel.allCases, id: \.self) { model in
            VStack(alignment: .leading) {
                Text(model.displayName)
                    .font(.headline)
                ModelDescriptorView(model: model)
                Text(model.recommendedUseCase)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 4)
        }
    }
    .padding()
}

#Preview("Single Model") {
    ModelDescriptorView(model: .base)
        .padding()
}
