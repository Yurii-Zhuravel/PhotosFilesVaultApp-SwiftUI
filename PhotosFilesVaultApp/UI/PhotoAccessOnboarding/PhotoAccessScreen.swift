import SwiftUI

struct PhotoAccessScreen: View {
    var body: some View {
        ZStack {
            Text("PhotoAccessScreen")
        }.navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    PhotoAccessScreen()
}
