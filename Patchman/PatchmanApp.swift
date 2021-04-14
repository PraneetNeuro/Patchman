//
//  PatchmanApp.swift
//  Patchman
//
//  Created by Praneet S on 16/03/21.
//

import SwiftUI

func openRequestProfile() -> String? {
    let dialog = NSOpenPanel();
    
    dialog.title  = "Choose a CSV file";
    dialog.showsResizeIndicator = true;
    dialog.showsHiddenFiles = false;
    dialog.allowsMultipleSelection = false;
    dialog.canChooseDirectories = false;
    dialog.allowedFileTypes = ["patchman"];
    
    if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
        let result = dialog.url
        if (result != nil) {
            let path: String = result!.path
            return path
        }
    } else {
        return nil
    }
    return nil
}

@main
struct PatchmanApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands(content: {
            CommandMenu("Quickies", content: {
                Button("Open", action: {
                    let requestProfilePath = openRequestProfile()
                    guard let requestProfileURL = requestProfilePath else {
                        return
                    }
                    let profile = try? JSONDecoder().decode(Profile.self, from: Data(contentsOf: URL(fileURLWithPath: requestProfileURL), options: []))
                    guard let profileUnwrapped = profile else {
                        return
                    }
                    profileUnwrapped.save()
                    Defaults.shared.profiles.append(profileUnwrapped)
                })
            })
        })
        .windowStyle(HiddenTitleBarWindowStyle())
    }
}
