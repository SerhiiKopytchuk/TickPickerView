//
//  TickPicker.swift
//  TickPickerView
//
//  Created by Serhii Kopytchuk on 24.12.2025.
//

import SwiftUI

struct GlassTickPickerConfig {
    var tickWidth: CGFloat = 2
    var tickHeight: CGFloat = 20
    var tickHPadding: CGFloat = 3
    var inActiveHeightProgress: CGFloat = 0.55
    var interactionHeight: CGFloat = 60
    var knobWidth: CGFloat = 40
    var activeTint: Color = .blue
    var inActiveTint: Color = .primary
    var knobColor: Color = .white
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

struct GlassTickPicker: View {
    var range: ClosedRange<Int>
    var config: GlassTickPickerConfig = .init()
    @Binding var selection: Int

    // MARK: View Properties
    @State private var scrollIndex: Int = 0
    @State private var animationQueue: [Int] = []
    @State private var isInitialSetupDone: Bool = false

    @State private var isDragging: Bool = false
    @State private var capsuleOffset: CGFloat = 0
    @State private var capsuleStartOffset: CGFloat = 0
    @State private var containerWidth: CGFloat = 1
    @State private var tickCount: Int = 1
    @State private var progress: CGFloat = 0 {
        didSet {
            let diff = range.upperBound - range.lowerBound
            let progressFromLower = Int(round(CGFloat(diff) * progress))
            selection = range.lowerBound + progressFromLower
        }
    }

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

                KnobView(containerSize: size, numberOfTics: count)
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
            let selectionAtCurrentIndex = selectionForIndex(scrollIndex, count: tickCount)
            guard selectionAtCurrentIndex != newValue else { return }
            updatePosition(selection: newValue)
        }
    }

    // MARK: Views
    @ViewBuilder
    func TickView(_ index: Int) -> some View {
        let height = config.tickHeight
        let isInside = animationQueue.contains(index)
        let fillColor = scrollIndex == index ? config.activeTint : config.inActiveTint.opacity(isInside ? 1 : 0.4)

        Rectangle()
            .fill(fillColor)
            .frame(
                width: config.tickWidth,
                height: height * (isInside ? 1 : config.inActiveHeightProgress)
            )
            .frame(width: width, height: height, alignment: .center)
            .animation(isInside || !isInitialSetupDone ? .none : config.animation, value: isInside)
    }

    @ViewBuilder
    func KnobView(containerSize size: CGSize, numberOfTics count: Int) -> some View {
        Capsule()
            .fill(
                isDragging
                  ? isGlassAvailable()
                    ? config.knobColor.opacity(0.001)
                    : config.knobColor
                  : config.knobColor
            )
            .opacity(
                isGlassAvailable()
                ? isDragging ? 0.01 : 1
                : 1
            )
            .clearGlassEffect(isInteractive: true)
            .if(isGlassAvailable() == false, then: { view in
                view.scaleEffect(isDragging ? 1.3 : 1)
            })
            .shadow(color: .black.opacity(isDragging ? 0.3 : 0.1), radius: 4)
            .frame(width: config.knobWidth, height: config.interactionHeight / 2)
            .padding(.horizontal, -config.knobWidth / 2)
            .offset(x: capsuleOffset)
            .animation(.spring(duration: 0.3), value: isDragging)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isDragging = true

                        let rawOffset = capsuleStartOffset + value.translation.width
                        let clampedOffset = min(max(rawOffset, 0), size.width)
                        capsuleOffset = clampedOffset
                        let safeWidth = max(size.width, 1)
                        progress = capsuleOffset / safeWidth

                        let maxIndex = max(count - 1, 0)
                        let newIndex = Int(round((capsuleOffset / safeWidth) * CGFloat(maxIndex)))
                        let clampedIndex = max(min(newIndex, maxIndex), 0)

                        if clampedIndex != scrollIndex {
                            enqueueTransition(from: scrollIndex, to: clampedIndex)
                            scrollIndex = clampedIndex
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                        capsuleStartOffset = capsuleOffset
                        let safeWidth = max(size.width, 1)
                        progress = capsuleOffset / safeWidth
                    }
            )
    }

    // MARK: Helpers
    private func updatePosition(selection: Int) {
        guard isDragging == false else { return }
        let safeSelection = max(min(selection, range.upperBound), range.lowerBound)
        let rangeDiff = max(range.upperBound - range.lowerBound, 1)
        let nextProgress = CGFloat(safeSelection - range.lowerBound) / CGFloat(rangeDiff)
        let clampedProgress = min(max(nextProgress, 0), 1)

        progress = clampedProgress

        let safeCount = max(tickCount, 1)
        let maxIndex = max(safeCount - 1, 0)
        let newIndex = Int(round(clampedProgress * CGFloat(maxIndex)))
        let safeIndex = max(min(newIndex, maxIndex), 0)

        scrollIndex = safeIndex
        enqueueTransition(from: safeIndex, to: safeIndex)

        let safeWidth = max(containerWidth, 1)
        capsuleOffset = clampedProgress * safeWidth
        capsuleStartOffset = capsuleOffset
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

    // MARK: animation range
    private func enqueueTransition(from start: Int, to end: Int) {
        let step = start <= end ? 1 : -1
        var value = start

        while true {
            enqueueTick(value)
            if value == end { break }
            value += step
        }
    }

    private func enqueueTick(_ tick: Int) {
        animationQueue.append(tick)

        Task {
            try? await Task.sleep(for: .seconds(0.04))
            await MainActor.run {
                if let index = animationQueue.firstIndex(of: tick) {
                    animationQueue.remove(at: index)
                }
            }
        }
    }

    private func isGlassAvailable() -> Bool {
        if #available(iOS 26.0, *) {
            return true
        } else {
            return false
        }
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
