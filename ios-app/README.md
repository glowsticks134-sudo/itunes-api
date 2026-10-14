# App Catalog for iPhone

A native SwiftUI app that searches Apple's public iTunes Search API for App Store apps.

## Features

- Search apps by name
- Display app icons, developer, price, and rating when available
- Open the official App Store listing
- Dark interface with red accents
- No API key required for basic catalog searches

## Important

This app searches the public catalog and opens App Store listings. It does not download app packages or bypass Screen Time, parental controls, device management, or App Store restrictions.

## Requirements

- A Mac with Xcode
- iOS 16 or later
- Internet connection
- XcodeGen (to generate the Xcode project from project.yml)

## Build

1. Install Xcode from the Mac App Store.
2. Install XcodeGen, for example with Homebrew: `brew install xcodegen`.
3. From this directory, run: `xcodegen generate`.
4. Open `ITunesCatalog.xcodeproj` in Xcode.
5. Select an iPhone simulator or connect your iPhone.
6. In Signing & Capabilities, choose your Apple development team if running on a physical device.
7. Press Run.

The generated .xcodeproj is a build artifact and is not committed. Run XcodeGen whenever project.yml changes.
