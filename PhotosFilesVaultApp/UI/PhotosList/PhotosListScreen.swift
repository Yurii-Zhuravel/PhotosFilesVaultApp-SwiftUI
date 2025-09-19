import SwiftUI

struct PhotosListScreen: View {
    let services: ServicesProtocol
    let album: AlbumItem
    @Binding var navigationPath: NavigationPath
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    Text("__List of photos___")
                }
            }.navigationTitle(album.name)
                .navigationBarTitleDisplayMode(.inline)
                
        }
    }
}

#Preview {
    let services = MockedServices.standard()
    @State var navigationPath = NavigationPath()
    let album = AlbumItem(id: "1", name: "Test album")
    
    PhotosListScreen(
        services: services,
        album: album,
        navigationPath: $navigationPath
    )
}
