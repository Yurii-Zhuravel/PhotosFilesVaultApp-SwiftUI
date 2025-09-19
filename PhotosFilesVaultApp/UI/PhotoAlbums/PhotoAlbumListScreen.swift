import SwiftUI

struct PhotoAlbumListScreen: View {
    let services: ServicesProtocol
    
    @State private var navigationPath = NavigationPath()
    @State private var isShowingAddingSheet = false
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    
                    let contentPadding: CGFloat = 20
                    let itemsPadding: CGFloat = 20
                    let itemSize: CGFloat = (geometry.size.width - contentPadding * 2.0 - itemsPadding) / 2.0
                    let adjustedPositiveItemSize = (itemSize >= 0) ? itemSize : 0
                    
                    VStack(spacing: 0) {
                        Spacer().frame(height: contentPadding)
                        
                        // TODO: Albums!
                        HStack {
                            PhotoAlmubItemView(name: "My favorite photos")
                                .frame(width: adjustedPositiveItemSize,
                                       height: adjustedPositiveItemSize)
                            Spacer()
                            
                            PhotoAlmubItemView(name: "My car")
                                .frame(width: adjustedPositiveItemSize,
                                       height: adjustedPositiveItemSize)
                        }
                        Spacer().frame(height: itemsPadding)
                        
                        HStack {
                            PhotoAlmubItemView(name: "Family photos")
                                .frame(width: adjustedPositiveItemSize,
                                       height: adjustedPositiveItemSize)
                            
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
                                self.isShowingAddingSheet = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .foregroundColor(.accent)
                                    Image(systemName: "plus")
                                        .font(.system(size: 34, weight: .regular))
                                        .foregroundColor(.buttonText)
                                }.frame(width: 60, height: 60)
                                    .contentShape(Rectangle())
                            }.shadow(color: .secondaryAccent.opacity(0.7),
                                     radius: 8)
                            .contentShape(Rectangle())

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
                    .sheet(isPresented: $isShowingAddingSheet) {
                        AddPhotoTypeItemView(
                            isShowing: $isShowingAddingSheet,
                            onImportPhotoVideoCallback: {
                                // TODO:
                                print("!!! AAA onImportPhotoVideoCallback")
                                self.isShowingAddingSheet = false
                            }, onAddNewFolderCallback: {
                                // TODO:
                                print("!!! AAA onAddNewFolderCallback")
                                self.isShowingAddingSheet = false
                            }
                        )
                            .presentationDetents([.height(250)])
                            .presentationDragIndicator(.visible)
                    }
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
