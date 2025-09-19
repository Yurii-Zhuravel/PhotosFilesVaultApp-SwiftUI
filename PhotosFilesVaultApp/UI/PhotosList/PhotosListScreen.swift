import SwiftUI

struct PhotosListScreen: View {
    let services: ServicesProtocol
    let folder: FolderModel
    @Binding var navigationPath: NavigationPath

    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    Text("__List of photos___")
                }
            }.navigationTitle(folder.name)
                .navigationBarTitleDisplayMode(.inline)
                
        }
    }
}

#Preview {
    let services = MockedServices.standard()
    @State var navigationPath = NavigationPath()
    let folder = FolderModel(path: "",
                             name: "Test 1",
                             items: [],
                             timeStamp: Date(),
                             thubnailPath: nil,
                             filesCount: 0,
                             foldersCount: 0)

    PhotosListScreen(
        services: services,
        folder: folder,
        navigationPath: $navigationPath
    )
}
