import Foundation
import SwiftUI

struct TextFieldAlertStyle: TextFieldStyle {
    var backgroundColor: Color = .gray

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(10)
            .background(backgroundColor)
            .cornerRadius(8)
    }
}

struct TextFieldAlert: View {
    @Binding var isPresented: Bool
    @Binding var firstText: String
    var title: String
    var message: String
    let buttonOkTitle: String
    var onSave: () -> Void
    
    @StateObject private var keyboard = KeyboardResponder()

    var body: some View {
        if isPresented {
            GeometryReader { geometry in
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture { } // captures taps and blocks them from going through

                    VStack(spacing: 0) {
                        VStack(spacing: 0) {
                            Text(title)
                                .font(.system(size: 18, weight: .medium))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.contentText)
                            
                            Spacer().frame(height: 16)
                            
                            Text(message)
                                .font(.system(size: 12, weight: .regular))
                                .multilineTextAlignment(.center)
                                .foregroundColor(.contentText)
                            
                            Spacer().frame(height: 16)
                            
                            TextField("name", text: $firstText)
                                .keyboardType(.default)
                                .textFieldStyle(TextFieldAlertStyle(backgroundColor: .textFieldBack))
                                .shadow(color: .gray, radius: 1)
                                .foregroundColor(.contentText)
                        }.padding(15)
                        Spacer().frame(height: 10)
                        
                        Divider()
                            .background(.gray)
                            .foregroundColor(.gray)
                            .frame(height: 0.5)
                        
                        HStack(spacing: 0) {
                            Button(action: {
                                isPresented = false
                            }) {
                                Text("cancel")
                                    .bold()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }

                            Rectangle()
                                .frame(width: 0.5)
                                .foregroundColor(.gray)

                            Button(action: {
                                isPresented = false
                                onSave()
                            }) {
                                Text(buttonOkTitle)
                                    .bold()
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .contentShape(Rectangle())
                            }
                        }.frame(height: 44)
                    }
                    .background(Color(.alertBack))
                    .cornerRadius(12)
                    .frame(width: geometry.size.width * 0.8)
                    .shadow(radius: 10)
                    .offset(y: -keyboard.currentHeight / 2) // move alert up
                    .animation(.easeOut(duration: 0.25), value: keyboard.currentHeight)
                }
            }
        }
    }
}

#Preview("Light") {
    ZStack {
        Color.gray
        TextFieldAlert(isPresented: .constant(true),
                firstText: .constant("My test folder name"),
                title: NSLocalizedString("edit_folder_alert_title", comment: ""),
                message: NSLocalizedString("edit_folder_alert_message", comment: ""),
                buttonOkTitle: "Save",
                onSave: {})
            .environment(\.colorScheme, .light)
            .clipped()
    }
}

#Preview("Dark") {
    ZStack {
        Color.gray
        TextFieldAlert(isPresented: .constant(true),
                firstText: .constant("My test folder name"),
                title: NSLocalizedString("edit_folder_alert_title", comment: ""),
                message: NSLocalizedString("edit_folder_alert_message", comment: ""),
                buttonOkTitle: "Save",
                onSave: {})
            .environment(\.colorScheme, .dark)
            .clipped()
    }
}
