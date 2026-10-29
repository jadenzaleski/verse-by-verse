//
//  StorageKeys.swift
//  VerseByVerse
//
//  Created by Jaden Zaleski on 1/28/26.
//

import SwiftUI

enum StorageKeys: String, CaseIterable {
    case firstLaunch
    case lastUsedTranslation
    case displayName
    case fumsDeviceId
    case memorySort
    case setSort
    case sortReversed
    case filterDueOnly
    case filterTestament
}

extension AppStorage {
    // MARK: - String Support

    init(wrappedValue: Value, _ key: StorageKeys) where Value == String {
        self.init(wrappedValue: wrappedValue, key.rawValue)
    }

    init(_ key: StorageKeys) where Value == String? {
        self.init(key.rawValue)
    }

    // MARK: - Bool Support

    init(wrappedValue: Value, _ key: StorageKeys) where Value == Bool {
        self.init(wrappedValue: wrappedValue, key.rawValue)
    }

    init(_ key: StorageKeys) where Value == Bool? {
        self.init(key.rawValue)
    }

    // MARK: - RawRepresentable (String) Support

    init(wrappedValue: Value, _ key: StorageKeys) where Value: RawRepresentable, Value.RawValue == String {
        self.init(wrappedValue: wrappedValue, key.rawValue)
    }

    // MARK: - Int Support

    init(wrappedValue: Value, _ key: StorageKeys) where Value == Int {
        self.init(wrappedValue: wrappedValue, key.rawValue)
    }

    init(_ key: StorageKeys) where Value == Int? {
        self.init(key.rawValue)
    }
}
