import SwiftUI

struct PhotoAlbumListScreen: View {
    let services: ServicesProtocol
    
    @State private var navigationPath = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    
                    let contentPadding: CGFloat = 20
                    let itemsPadding: CGFloat = 20
                    let itemSize: CGFloat = (geometry.size.width - contentPadding * 2.0 - itemsPadding) / 2.0
                    
                    VStack(spacing: 0) {
                        Spacer().frame(height: contentPadding)
                        
                        // TODO: Albums!
                        HStack {
                            PhotoAlmubItemView(name: "My favorite photos")
                                .frame(width: itemSize, height: itemSize)
                            Spacer()
                            
                            PhotoAlmubItemView(name: "My car")
                                .frame(width: itemSize, height: itemSize)
                        }
                        Spacer().frame(height: itemsPadding)
                        
                        HStack {
                            PhotoAlmubItemView(name: "Family photos")
                                .frame(width: itemSize, height: itemSize)
                            
                            Spacer()
                        }
                        Spacer()
                        
                        Spacer().frame(height: contentPadding)

                    }.padding(.horizontal, contentPadding)
                    
                    VStack {
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Button {
                                // TODO:
                            } label: {
                                ZStack {
                                    Circle()
                                        .foregroundColor(.accent)
                                    Image(systemName: "plus")
                                        .font(.system(size: 34, weight: .regular))
                                        .foregroundColor(.buttonText)
                                }.frame(width: 60, height: 60)
                            }.shadow(color: .secondaryAccent.opacity(0.7),
                                     radius: 8)

                        }.padding(20)
                    }.ignoresSafeArea()
                }.navigationTitle("photos")
                    .navigationBarTitleDisplayMode(.inline)
    //                .navigationDestination(for: HomeTabsNavigationRoutes.self) { route in
    //                    switch route {
    //                    case .photoAlbumList:
    //                        PhotoAlbumListScreen(services: services)
    //                    case .settings:
    //                        SettingsScreen(services: services)
    //                    }
    //                }
            }
        }
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    PhotoAlbumListScreen(
        services: services
    )
}
