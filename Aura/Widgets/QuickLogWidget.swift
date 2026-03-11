import WidgetKit
import SwiftUI

struct QuickLogWidgetEntry: TimelineEntry {
    let date: Date
}

struct QuickLogWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLogWidgetEntry {
        QuickLogWidgetEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickLogWidgetEntry) -> Void) {
        completion(QuickLogWidgetEntry(date: Date()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogWidgetEntry>) -> Void) {
        let entry = QuickLogWidgetEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct QuickLogWidgetView: View {
    let entry: QuickLogWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "plus.circle.fill")
                .font(.system(size: 36))
                .foregroundStyle(Color(hex: "1ABC9C"))

            Text("Log Episode")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color(hex: "2C3E50"))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .containerBackground(.fill.tertiary, for: .widget)
        .widgetURL(URL(string: "aura://quicklog"))
    }
}

struct QuickLogWidget: Widget {
    let kind: String = "QuickLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLogWidgetProvider()) { entry in
            QuickLogWidgetView(entry: entry)
        }
        .configurationDisplayName("Log Episode")
        .description("Quickly log a pain episode with one tap.")
        .supportedFamilies([.systemSmall])
    }
}
