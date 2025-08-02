#!/usr/bin/env python3

import os
import sys

def main():
    # Dateien die zum Xcode-Projekt hinzugefügt werden müssen
    files_to_add = [
        "ios/SmartCityGuide/Models/OverpassPOI.swift",
        "ios/SmartCityGuide/Services/OverpassAPIService.swift"
    ]
    
    project_root = "/Users/dengelma/develop/private/smart-city-guide"
    
    print("🚀 Adding new files to Xcode project...")
    
    for file_path in files_to_add:
        full_path = os.path.join(project_root, file_path)
        if os.path.exists(full_path):
            print(f"✅ File exists: {file_path}")
        else:
            print(f"❌ File not found: {file_path}")
            return 1
    
    print("""
📝 Manual Steps Required:

1. Open Xcode project: /Users/dengelma/develop/private/smart-city-guide/ios/SmartCityGuide.xcodeproj

2. Add these files to the project:
   - Right-click on 'Models' group → Add Files to "SmartCityGuide"
   - Select: ios/SmartCityGuide/Models/OverpassPOI.swift
   
   - Right-click on 'Services' group → Add Files to "SmartCityGuide"
   - Select: ios/SmartCityGuide/Services/OverpassAPIService.swift

3. Make sure both files are added to the SmartCityGuide target

4. Build the project again

Alternatively, we can try to build again - sometimes Xcode auto-detects new files.
""")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())