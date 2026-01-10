import SwiftUI

/// Picker for selecting an audio input device.
///
/// Shows "System Default" option (nil value) plus all available input devices.
struct AudioDevicePickerView: View {
    @Binding var selectedDeviceID: String?
    let devices: [AudioDevice]

    var body: some View {
        Picker("Input Device", selection: $selectedDeviceID) {
            Text("System Default")
                .tag(nil as String?)

            if !devices.isEmpty {
                Divider()

                ForEach(devices) { device in
                    HStack {
                        Text(device.name)
                        if device.isDefault {
                            Text("(Default)")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .tag(device.id as String?)
                }
            }
        }
        .pickerStyle(.menu)
    }
}

#Preview {
    @Previewable @State var selectedDeviceID: String? = nil

    AudioDevicePickerView(
        selectedDeviceID: $selectedDeviceID,
        devices: [
            AudioDevice(id: "device1", name: "MacBook Pro Microphone", isDefault: true),
            AudioDevice(id: "device2", name: "External USB Microphone", isDefault: false),
            AudioDevice(id: "device3", name: "AirPods Pro", isDefault: false)
        ]
    )
    .padding()
    .frame(width: 400)
}
