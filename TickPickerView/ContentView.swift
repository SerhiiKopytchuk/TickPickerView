//
//  ContentView.swift
//  TickPickerView
//
//  Created by Serhii Kopytchuk on 24.12.2025.
//

import SwiftUI

struct ContentView: View {

    @State private var classicSelection: Int = 0
    @State private var glassSelection: Int = 0
    @State private var rangeGlassSelection = 0...100

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    sectionView(
                        title: "Classic Tick Picker",
                        selectionText: "Selection: \(classicSelection)"
                    ) {
                        TickPicker(count: 100, selection: $classicSelection)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .clipped()
                    }

                    sectionView(
                        title: "Glass Tick Picker",
                        selectionText: "Selection: \(glassSelection)"
                    ) {
                        GlassTickPicker(range: 0...100, selection: $glassSelection)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }


                    sectionView(
                        title: "Range Glass Tick Picker",
                        selectionText: "Selection: \(rangeGlassSelection)"
                    ) {
                        RangeGlassTickPicker(range: 0...100, selection: $rangeGlassSelection)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("Tick Picker")
            .background(Color(.systemGroupedBackground))
        }
    }

    @ViewBuilder
    private func sectionView<Content: View>(
        title: String,
        selectionText: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.horizontal, 4)

            VStack(alignment: .leading, spacing: 8) {
                content()

                Text(selectionText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
    }
}

#Preview {
    ContentView()
}
