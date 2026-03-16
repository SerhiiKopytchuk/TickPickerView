//
//  TickPicker.swift
//  TickPickerView
//
//  Created by Serhii Kopytchuk on 24.12.2025.
//

import SwiftUI
#if os(iOS)
import UIKit
#endif

struct RangeGlassTickPickerConfig {
    var tickWidth: CGFloat = 2
    var tickHeight: CGFloat = 20
    var tickHPadding: CGFloat = 3
    var inActiveHeightProgress: CGFloat = 0.55
    var interactionHeight: CGFloat = 60
    var knobWidth: CGFloat = 40
    var activeTint: Color = .blue
    var inActiveTint: Color = .primary
    var knobColor: Color = .white
    var hapticsEnabled: Bool = true
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

struct RangeGlassTickPicker: View {
    var range: ClosedRange<Int>
    var config: RangeGlassTickPickerConfig = .init()
    @Binding var selection: ClosedRange<Int>

    // MARK: View Properties
    @State private var isInitialSetupDone: Bool = false

    @State private var lowerIndex: Int = 0
    @State private var upperIndex: Int = 0
    @State private var lowerOffset: CGFloat = 0
    @State private var upperOffset: CGFloat = 0
    @State private var lowerStartOffset: CGFloat = 0
    @State private var upperStartOffset: CGFloat = 0
    @State private var isDraggingLower: Bool = false
    @State private var isDraggingUpper: Bool = false
    @State private var containerWidth: CGFloat = 1
    @State private var tickCount: Int = 1

    var body: some View {
        GeometryReader {
            let size = $0.size
            let count = adaptiveTickCount(width: size.width)

            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    ForEach(0..<count, id: \.self) { index in
                        TickView(index)
                    }
                }
                .frame(height: config.tickHeight)

                KnobView(kind: .lower, containerSize: size, numberOfTics: count)
                KnobView(kind: .upper, containerSize: size, numberOfTics: count)
            }
            .onAppear {
                containerWidth = max(size.width, 1)
                tickCount = max(count, 1)
                updatePosition(selection: selection)
            }
            .onChange(of: size.width) { _, newValue in
                containerWidth = max(newValue, 1)
                tickCount = max(adaptiveTickCount(width: newValue), 1)
                updatePosition(selection: selection)
            }
        }
        .padding(.horizontal, config.knobWidth / 2)
        .frame(height: config.interactionHeight)
        .task {
            guard isInitialSetupDone == false else { return }
            updatePosition(selection: selection)
            try? await Task.sleep(for: .seconds(0.05))
            isInitialSetupDone = true
        }
        .allowsHitTesting(isInitialSetupDone)
        .onChange(of: selection) { oldValue, newValue in
            let current = selectionForIndex(lowerIndex, count: tickCount)...selectionForIndex(upperIndex, count: tickCount)
            guard current != newValue else { return }
            updatePosition(selection: newValue)
        }
    }

    // MARK: Views
    @ViewBuilder
    func TickView(_ index: Int) -> some View {
        let height = config.tickHeight
        let isInside = (lowerIndex...upperIndex).contains(index)
        let fillColor = isInside ? config.activeTint : config.inActiveTint.opacity(0.4)

        Rectangle()
            .fill(fillColor)
            .frame(
                width: config.tickWidth,
                height: height * (isInside ? 1 : config.inActiveHeightProgress)
            )
            .frame(width: width, height: height, alignment: .center)
            .animation(!isInitialSetupDone ? .none : config.animation, value: isInside)
    }

    enum KnobKind {
        case lower
        case upper
    }

    @ViewBuilder
    func KnobView(kind: KnobKind, containerSize size: CGSize, numberOfTics count: Int) -> some View {
        let isDraggingKnob = kind == .lower ? isDraggingLower : isDraggingUpper

        Capsule()
            .fill(
                isDraggingKnob
                  ? isGlassAvailable()
                    ? config.knobColor.opacity(0.001)
                    : config.knobColor
                  : config.knobColor
            )
            .opacity(
                isGlassAvailable()
                ? (isDraggingKnob ? 0.01 : 1)
                : 1
            )
            .if(isGlassAvailable() == false, then: { view in
                view.scaleEffect(isDraggingKnob ? 1.3 : 1)
            })
            .clearGlassEffect(isInteractive: true)
            .shadow(color: .black.opacity(isDraggingKnob ? 0.3 : 0.1), radius: 4)
            .frame(width: config.knobWidth, height: config.interactionHeight / 2)
            .padding(.horizontal, -config.knobWidth / 2)
            .offset(x: kind == .lower ? lowerOffset : upperOffset)
            .animation(.spring(duration: 0.3), value: isDraggingLower || isDraggingUpper)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let safeWidth = max(size.width, 1)

                        if kind == .lower {
                            isDraggingLower = true
                            let rawOffset = lowerStartOffset + value.translation.width
                            let clampedOffset = min(max(rawOffset, 0), upperOffset)
                            lowerOffset = clampedOffset
                            let newLowerIndex = indexForOffset(clampedOffset, count: count, width: safeWidth)
                            if newLowerIndex != lowerIndex {
                                triggerSelectionHaptic()
                            }
                            lowerIndex = newLowerIndex
                        } else {
                            isDraggingUpper = true
                            let rawOffset = upperStartOffset + value.translation.width
                            let clampedOffset = max(min(rawOffset, safeWidth), lowerOffset)
                            upperOffset = clampedOffset
                            let newUpperIndex = indexForOffset(clampedOffset, count: count, width: safeWidth)
                            if newUpperIndex != upperIndex {
                                triggerSelectionHaptic()
                            }
                            upperIndex = newUpperIndex
                        }

                        selection = selectionForIndex(lowerIndex, count: count)...selectionForIndex(upperIndex, count: count)
                    }
                    .onEnded { _ in
                        if kind == .lower {
                            isDraggingLower = false
                            lowerStartOffset = lowerOffset
                        } else {
                            isDraggingUpper = false
                            upperStartOffset = upperOffset
                        }
                    }
            )
    }

    // MARK: Helpers
    private func updatePosition(selection: ClosedRange<Int>) {
        guard isDraggingLower == false, isDraggingUpper == false else { return }

        let lower = max(min(selection.lowerBound, range.upperBound), range.lowerBound)
        let upper = max(min(selection.upperBound, range.upperBound), lower)
        let safeSelection = lower...upper

        let safeCount = max(tickCount, 1)
        lowerIndex = indexForSelection(safeSelection.lowerBound, count: safeCount)
        upperIndex = indexForSelection(safeSelection.upperBound, count: safeCount)

        let safeWidth = max(containerWidth, 1)
        lowerOffset = offsetForIndex(lowerIndex, count: safeCount, width: safeWidth)
        upperOffset = offsetForIndex(upperIndex, count: safeCount, width: safeWidth)
        lowerStartOffset = lowerOffset
        upperStartOffset = upperOffset

        if self.selection != safeSelection {
            self.selection = safeSelection
        }
    }

    private func indexForSelection(_ value: Int, count: Int) -> Int {
        let safeValue = max(min(value, range.upperBound), range.lowerBound)
        let diff = max(range.upperBound - range.lowerBound, 1)
        let progress = CGFloat(safeValue - range.lowerBound) / CGFloat(diff)
        let maxIndex = max(count - 1, 0)
        return max(min(Int(round(progress * CGFloat(maxIndex))), maxIndex), 0)
    }

    private func indexForOffset(_ offset: CGFloat, count: Int, width: CGFloat) -> Int {
        let safeWidth = max(width, 1)
        let maxIndex = max(count - 1, 0)
        let progress = min(max(offset / safeWidth, 0), 1)
        let index = Int(round(progress * CGFloat(maxIndex)))
        return max(min(index, maxIndex), 0)
    }

    private func offsetForIndex(_ index: Int, count: Int, width: CGFloat) -> CGFloat {
        let maxIndex = max(count - 1, 1)
        let safeIndex = max(min(index, maxIndex), 0)
        return (CGFloat(safeIndex) / CGFloat(maxIndex)) * max(width, 1)
    }

    private func selectionForIndex(_ index: Int, count: Int) -> Int {
        let safeCount = max(count, 1)
        let safeIndex = max(min(index, safeCount - 1), 0)
        let denominator = max(safeCount - 1, 1)
        let progress = CGFloat(safeIndex) / CGFloat(denominator)
        let diff = range.upperBound - range.lowerBound
        let progressFromLower = Int(round(CGFloat(diff) * progress))
        return range.lowerBound + progressFromLower
    }

    private var width: CGFloat {
        return config.tickWidth + (2 * config.tickHPadding)
    }

    private func adaptiveTickCount(width: CGFloat) -> Int {
        let count = width / (config.tickWidth + (config.tickHPadding * 2))
        return Int(round(count))
    }

    private func isGlassAvailable() -> Bool {
        if #available(iOS 26.0, *) {
            return true
        } else {
            return false
        }
    }

    private func triggerSelectionHaptic() {
        guard config.hapticsEnabled else { return }
        #if os(iOS)
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
        #endif
    }
}

// MARK: - Conditional modifiers
private extension View {
    @ViewBuilder
    func clearGlassEffect(isInteractive: Bool = false) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(.clear.interactive(isInteractive))
        } else {
            self
        }
    }

    @ViewBuilder
    func `if`<TrueContent: View>(
        _ condition: Bool,
        @ViewBuilder then: (Self) -> TrueContent
    ) -> some View {
        if condition {
            then(self)
        } else {
            self
        }
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
