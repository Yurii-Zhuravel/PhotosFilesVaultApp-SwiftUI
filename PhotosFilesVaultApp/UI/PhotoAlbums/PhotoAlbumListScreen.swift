import SwiftUI

struct PhotoAlbumListScreen: View {
    let services: ServicesProtocol
    let bottomTabBarHeight: CGFloat
    
    @State private var navigationPath = NavigationPath()
    @State private var isShowingAddingSheet = false
    @State private var isShowingDeleteConfirmationAlert = false
    @State private var isShowingEditFolderAlert = false
    @State private var isShowingAddFolderAlert = false
    @State private var editedFolderName = ""
    @State private var folderToDelete: FolderModel?
    
    @StateObject private var viewModel = VaultViewModel()

    private let gridColumns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GeometryReader { geometry in
                ZStack {
                    Color.contentBack
                        .ignoresSafeArea()
                    
                    let contentPadding: CGFloat = 20
                    let itemsPadding: CGFloat = 20
                    let itemSize: CGFloat = (geometry.size.width - contentPadding * 3.0 - itemsPadding) / 2.0
                    let adjustedPositiveItemSize = (itemSize >= 0) ? itemSize : 0
                    
                    buildContent(contentPadding: contentPadding,
                                 adjustedPositiveItemSize: adjustedPositiveItemSize,
                                 itemsPadding: itemsPadding)
                        .padding(.horizontal, contentPadding)
                        .ignoresSafeArea(edges: .bottom)
                        .bottomSafeAreaPadding(tabBarHeight:  self.bottomTabBarHeight)
                    
                    buildBottomButtonAdd(contentPadding: contentPadding)
                        .padding(.horizontal, contentPadding)
                        .ignoresSafeArea(edges: .bottom)
                        .bottomSafeAreaPadding(tabBarHeight:  self.bottomTabBarHeight)
                    
                    if self.isShowingEditFolderAlert {
                        buildEditFolderAlert()
                    }
                    if self.isShowingAddFolderAlert {
                        buildAddFolderAlert()
                    }
                }.ignoresSafeArea(edges: .bottom)
                    .navigationTitle("photos")
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationDestination(for: PhotoAlbumNavigationRoutes.self) { route in
                        switch route {
                        case .photosList(let folder):
                            PhotosListScreen(
                                services: services,
                                folder: folder,
                                navigationPath: $navigationPath
                            )
                        }
                    }
                    .sheet(isPresented: $isShowingAddingSheet) {
                        AddPhotoTypeItemView(
                            isShowing: $isShowingAddingSheet,
                            onImportPhotoVideoCallback: {
                                // TODO:
                                print("!!! AAA onImportPhotoVideoCallback")
                                self.isShowingAddingSheet = false
                            }, onAddNewFolderCallback: {
                                self.isShowingAddingSheet = false
                                
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    self.isShowingAddFolderAlert = true
                                }
                            }
                        )
                            .presentationDetents([.height(250)])
                            .presentationDragIndicator(.visible)
                    }.onAppear {
                        viewModel.fetchSubfolders()
                    }
                    .alert("delete_confirmation_alert_title",
                           isPresented: $isShowingDeleteConfirmationAlert,
                           actions: {
                        Button(role: .cancel) {
                            self.folderToDelete = nil
                        } label: {
                            Text("no")
                        }
                        Button(role: .destructive) {
                            if let folderToDelete {
                                viewModel.deleteFolder(folderToDelete)
                                self.folderToDelete = nil
                            }
                        } label: {
                            Text("yes")
                        }
                    }, message: {
                        Text("delete_confirmation_alert_message")
                    })
            }
        }
    }
    
    var placeholderView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            Text("__No items___")
            
            Spacer()
        }
    }
    
    @ViewBuilder
    private func buildContent(contentPadding: CGFloat,
                              adjustedPositiveItemSize: CGFloat,
                              itemsPadding: CGFloat) -> some View {
        if self.viewModel.showsLoading {
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.primaryAccent)
                Spacer()
            }
            
        } else if self.viewModel.subfolders.isEmpty {
            self.placeholderView
            
        } else {
            ScrollView {
                Spacer().frame(height: contentPadding)
                
                LazyVGrid(columns: gridColumns,
                          spacing: itemsPadding) {
                    ForEach(viewModel.subfolders, id: \.self) { folder in
                        PhotoAlmubItemView(
                            folder: folder,
                            onAlbumPressed: { albumId in
                                // TODO: !!!
                                /*
                                if let album = self.items.first(where: { $0.id == albumId }) {
                                    let newPath = PhotoAlbumNavigationRoutes.photosList(album)
                                    self.navigationPath.append(newPath)
                                } else {
                                    print("PhotoAlbumListScreen: Can't find album with id: \(albumId)")
                                }
                                 */
                            }
                        ).frame(width: adjustedPositiveItemSize,
                                height: adjustedPositiveItemSize)
                        .contextMenu {
                            if folder.isEditable {
                                Button {
                                    self.editedFolderName = folder.name
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        self.isShowingEditFolderAlert = true
                                    }
                                } label: {
                                    Label("edit_name", systemImage: "pencil")
                                }
                                Button(role: .destructive) {
                                    self.folderToDelete = folder
                                    isShowingDeleteConfirmationAlert = true
                                } label: {
                                    Label("delete", systemImage: "trash")
                                }
                            }
                        } preview: {
                            // 👇 This defines what appears during the "lift-off" animation
                            PhotoAlmubItemView(
                                folder: folder,
                                onAlbumPressed: { _ in }
                            ).frame(width: adjustedPositiveItemSize,
                                    height: adjustedPositiveItemSize)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }.id(viewModel.refreshTrigger)
                
                Spacer().frame(height: contentPadding)
            }
        }
    }
    
    private func buildBottomButtonAdd(contentPadding: CGFloat) -> some View {
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

            }
            Spacer().frame(height: contentPadding)
        }
    }
    
    private func buildEditFolderAlert() -> some View {
        TextFieldAlert(
            isPresented: $isShowingEditFolderAlert,
            firstText: $editedFolderName,
            title: NSLocalizedString("edit_folder_alert_title",
                                     comment: ""),
            message:  NSLocalizedString("edit_folder_alert_message",
                                        comment: ""),
            buttonOkTitle: NSLocalizedString("save",
                                             comment: ""),
            onSave: {
                self.editedFolderName = ""
            }
        )
    }
    
    private func buildAddFolderAlert() -> some View {
        TextFieldAlert(
            isPresented: $isShowingAddFolderAlert,
            firstText: $editedFolderName,
            title: NSLocalizedString("add_folder_alert_title",
                                     comment: ""),
            message: NSLocalizedString("add_folder_alert_message",
                                       comment: ""),
            buttonOkTitle: NSLocalizedString("create",
                                             comment: ""),
            onSave: {
                if !self.editedFolderName.isEmpty {
                    
                    guard !self.editedFolderName.isEmpty
                    else {
                        self.isShowingAddingSheet = false
                        return
                    }
                    viewModel.createNewFolder(name: self.editedFolderName)
                }
                self.editedFolderName = ""
            }
        )
    }
}

#Preview("Light mode") {
    let services = MockedServices.standard()
    
    PhotoAlbumListScreen(
        services: services,
        bottomTabBarHeight: 60
    )
}
