//
//  TickPicker.swift
//  TickPickerView
//
//  Created by Serhii Kopytchuk on 24.12.2025.
//

import SwiftUI

struct TickPickerConfig {
    var tickWidth: CGFloat = 3
    var tickHeight: CGFloat = 30
    var tickHPadding: CGFloat = 3
    var inActiveHeightProgress: CGFloat = 0.55
    var interactionHeight: CGFloat = 60
    var activeTint: Color = .yellow
    var inActiveTint: Color = .primary
    var alignment: Alignment = .bottom
    var animation: Animation = .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)

    enum Alignment: String, CaseIterable {
        case top
        case bottom
        case center

        var value: SwiftUI.Alignment {
            switch self {
            case .top: .top
            case .bottom: .bottom
            case .center: .center
            }
        }
    }
}

struct TickPicker: View {
    var count: Int
    var config: TickPickerConfig = .init()
    @Binding var selection: Int
    /// View Properties

    @State private var scrollIndex: Int = 0
    @State private var scrollPosition: Int?
    @State private var scrollPhase: ScrollPhase = .idle
    @State private var animationRange: ClosedRange<Int> = 0...0
    @State private var isInitialSetupDone: Bool = false

    var body: some View {
        GeometryReader {
            let size = $0.size

            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { index in
                        TickView(index)
                    }
                }
                .frame(height: config.tickHeight)
                .frame(maxWidth: .infinity)
                .contentShape(.rect)
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned(limitBehavior: .alwaysByOne))
            .scrollPosition(id: $scrollPosition, anchor: .center)
            .safeAreaPadding(.horizontal, (size.width - width) / 2)
            .onScrollGeometryChange(for: CGFloat.self) {
                $0.contentOffset.x + $0.contentInsets.leading
            } action: { oldValue, newValue in
                guard scrollPhase != .idle else { return }
                let index = max(min(Int((newValue / width).rounded()), count), 0)
                let previousScrollIndex = scrollIndex
                scrollIndex = index

                let isGreater = scrollIndex > previousScrollIndex
                let leadingBound = isGreater ? previousScrollIndex : scrollIndex
                let trailingBound = !isGreater ? previousScrollIndex : scrollIndex

                animationRange = leadingBound...trailingBound
            }
            .onScrollPhaseChange { oldPhase, newPhase in
                scrollPhase = newPhase
                animationRange = scrollIndex...scrollIndex

                if newPhase == .idle && scrollPosition != scrollIndex {
                    withAnimation(config.animation) {
                        scrollPosition = scrollIndex
                    }
                }
            }

        }
        .frame(height: config.interactionHeight)
        .task {
            guard isInitialSetupDone == false else { return }
            updateScrollPosition(selection: selection)
            try? await Task.sleep(for: .seconds(0.05))
            isInitialSetupDone = true
        }
        .allowsHitTesting(isInitialSetupDone)
        .onChange(of: scrollIndex) { oldValue, newValue in
            Task {
                selection = newValue
            }
        }
        .onChange(of: selection) { oldValue, newValue in
            guard scrollIndex != newValue else { return }
            updateScrollPosition(selection: newValue)
        }
    }

    @ViewBuilder
    func TickView(_ index: Int) -> some View {
        let height = config.tickHeight
        let isInside = animationRange.contains(index)
        let fillColor = scrollIndex == index ? config.activeTint : config.inActiveTint.opacity(isInside ? 1 : 0.4)

        Rectangle()
            .fill(fillColor)
            .frame(
                width: config.tickWidth,
                height: height * (isInside ? 1 : config.inActiveHeightProgress)
            )
            .frame(width: width, height: height, alignment: config.alignment.value)
            .animation(isInside || !isInitialSetupDone ? .none : config.animation, value: isInside)
    }

    func updateScrollPosition(selection: Int) {
        let safeSelection = max(min(selection, count), 0)
        scrollPosition = safeSelection
        scrollIndex = safeSelection
        animationRange = safeSelection...safeSelection
    }

    var width: CGFloat {
        return config.tickWidth + (2 * config.tickHPadding)
    }


}


#Preview {
    ContentView()
}
