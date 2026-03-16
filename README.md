# Apple Style Pickers with ticks

A sleek, customizable SwiftUI Tick Picker inspired by Apple’s modern UI style.
Built entirely in pure SwiftUI, it provides smooth interaction and lightweight performance across Apple platforms.

Includes multiple variants — classic tick picker, glass-style slider, and range selection — making it easy to integrate precise value controls into your app.

<img src="https://github.com/user-attachments/assets/56248a96-0d02-44c5-9890-9c7d8ff44dc3" width="400"/>

## Features

- 🌟 Pure SwiftUI implementation
- 📱 Cross-platform support for Apple devices
- 🎨 Fully customizable colors and animations
- ⚡️ Optimized performance with configurable parameters
- 🔄 Smooth, fluid animations
- 🎯 Easy to integrate into existing projects

## Platform Support

- ✅ WatchOS
- ✅ iOS
- ✅ iPadOS
- ✅ macOS

## Demos

### iOS

<img src="https://github.com/user-attachments/assets/947c738f-4965-4683-8478-2db4993e50c8" width="400"/>

## Installation

1. Copy the desired picker file (e.g., `TickPicker.swift` or `GlassTickPicker.swift`) into your project
2. Import the file in your SwiftUI view
3. Implement views as shown in the examples below

## Customization Guide

### Configuration
Each picker has its own configuartion. Use it to setup how picker looks

```swift
struct TickPickerConfig {
    var tickWidth: CGFloat = 3
    var tickHeight: CGFloat = 30
    var tickHPadding: CGFloat = 3
    var inActiveHeightProgress: CGFloat = 0.55
    var interactionHeight: CGFloat = 60
    var activeTint: Color = .yellow
    var inActiveTint: Color = .primary
    var hapticsEnabled: Bool = true
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
```

## Usage Examples

### Basic Implementation
```swift
struct ContentView: View {
    @State private var classicSelection: Int = 0
    @State private var glassSelection: Int = 0
    @State private var rangeGlassSelection: ClosedRange<Int> = 0...100

    var body: some View {
        ZStack {
            // Your content here
            TickPicker(count: 100, selection: $classicSelection)
            GlassTickPicker(range: 0...100, selection: $glassSelection)
            RangeGlassTickPicker(range: 0...100, selection: $rangeGlassSelection)
        }
    }
}
```

### With Custom Parameters
```swift
struct ContentView: View {
    @State private var classicSelection: Int = 0
    
    var body: some View {
        ZStack {
            // Your content here
            TickPicker(
                count: 100,
                config: TickPickerConfig(
                    tickWidth: 3,
                    tickHeight: 30,
                    tickHPadding: 3,
                    inActiveHeightProgress: 0.55,
                    interactionHeight: 60,
                    activeTint: .yellow,
                    inActiveTint: .primary,
                    hapticsEnabled: true,
                    alignment: .bottom,
                    animation: .interpolatingSpring(duration: 0.3, bounce: 0, initialVelocity: 0)
                ),
                selection: $classicSelection
            )
        }
    }
}
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

---

⭐️ If this project helped you, please consider giving it a star!
