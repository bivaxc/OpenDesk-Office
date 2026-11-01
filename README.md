# OpenDesk Office for iPhone

Native SwiftUI iOS project. Phase 1 foundation, not yet the complete office suite.

## Included
- SwiftUI Home, Tools and Me tabs
- Local document library and Files import
- PDF preview using PDFKit
- Document scanning using VisionKit
- iOS Simulator build workflow

## Build
Open `OpenDeskOffice.xcodeproj` in Xcode 16+ on macOS. Deployment target: iOS 17.

GitHub Actions builds the iOS Simulator target without signing. It does not create an installable iPhone IPA. Physical-device installation requires Apple code signing and provisioning.

## Current scope
DOCX/XLSX/PPTX editing, advanced PDF operations, OCR export, conversion engines, encryption and release QA are not implemented in Phase 1.

Documents remain in the app's local Documents directory. No cloud upload, login, analytics or advertising is included.
