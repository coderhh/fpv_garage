import Foundation

struct PromptBuilder {
    static let systemPromptVersion = "v1"

    static func buildMessages(from context: FleetContextDTO) -> [LLMMessage] {
        [
            LLMMessage(role: "system", content: systemPrompt(locale: context.deviceLocale)),
            LLMMessage(role: "user", content: userPrompt(from: context))
        ]
    }

    // MARK: - System Prompt

    static func systemPrompt(locale: String) -> String {
        let language = locale.hasPrefix("zh") ? "Chinese (简体中文)" : "English"
        return """
        You are an expert FPV drone technician and configuration advisor. \
        Analyze the aircraft configuration provided and give structured advice.

        Domain rules to consider:
        - Thrust-to-weight ratio (TWR) varies by flight style: freestyle needs 5-8:1, racing 8-10:1, cinematic 3-6:1, long-range 3-5:1, whoop 2-4:1
        - Motor KV × battery voltage should produce RPM appropriate for the frame size
        - ESC current rating must exceed motor peak draw
        - Battery C-rating × capacity (Ah) must support total motor draw

        Respond in \(language) with valid JSON matching this schema:
        {
          "configSummary": "brief summary of the build",
          "strengths": ["what works well"],
          "improvements": ["areas to optimize"],
          "twrComment": "optional comment on thrust-to-weight ratio, or null",
          "compatibilityNotes": ["restatement of any compatibility concerns"],
          "partSuggestions": [{"name": "part name", "reason": "why recommended", "priority": "high|medium|low"}] or null
        }

        Part suggestion rules:
        - Only suggest parts when improvements clearly warrant specific replacements or additions
        - Set partSuggestions to null if no specific part changes are needed
        - Each suggestion must include a name, reason, and priority (high/medium/low)
        - Prefer commonly available parts from well-known FPV brands
        - Part suggestions are recommendations requiring independent verification — state this in reasons when relevant
        - Consider the pilot's existing inventory (part counts) to avoid suggesting parts they may already have

        Guidelines:
        - Be specific and actionable
        - Reference actual component names when available
        - Adjust tone for the pilot's skill level
        - Flag any part suggestions as recommendations requiring independent verification
        - Prefer commonly available parts over niche products
        """
    }

    // MARK: - User Prompt

    static func userPrompt(from context: FleetContextDTO) -> String {
        var lines: [String] = []
        lines.append("Aircraft: \(context.aircraftName)")

        if let style = context.flightStyle {
            lines.append("Flight Style: \(style.rawValue)")
        }
        if let skill = context.pilotSkillLevel {
            lines.append("Pilot Skill: \(skill.rawValue)")
        }
        if let frame = context.frameSizeInch {
            lines.append("Frame Size: \(frame)\"")
        }
        if let motor = context.motorModel {
            lines.append("Motor: \(motor)")
        }
        if let kv = context.motorKv {
            lines.append("Motor KV: \(kv)")
        }
        if let prop = context.propSize {
            lines.append("Prop Size: \(prop)")
        }
        if let twr = context.twrRatio, let tier = context.twrTier {
            lines.append("TWR: \(String(format: "%.1f", twr)):1 (\(tier.rawValue))")
        }
        if let cells = context.batteryCells {
            lines.append("Battery: \(cells)S")
            if let cap = context.batteryCapacityMah {
                lines[lines.count - 1] += " \(cap)mAh"
            }
        }

        if !context.partCountsByCategory.isEmpty {
            let parts = context.partCountsByCategory
                .sorted { $0.key < $1.key }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: ", ")
            lines.append("Parts inventory: \(parts)")

            let lowStock = context.partCountsByCategory
                .filter { $0.value <= 1 }
                .map { $0.key }
                .sorted()
            if !lowStock.isEmpty {
                lines.append("Low stock categories: \(lowStock.joined(separator: ", "))")
            }
        }

        if !context.compatibilityWarningSummary.isEmpty {
            lines.append("Compatibility warnings:")
            for warning in context.compatibilityWarningSummary {
                lines.append("- \(warning)")
            }
        }

        return lines.joined(separator: "\n")
    }
}
