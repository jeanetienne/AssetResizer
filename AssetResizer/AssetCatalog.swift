//
//  AssetCatalog.swift
//  AssetResizer
//
//  Created by Jean-Étienne on 2/6/17.
//  Copyright © 2017 Jean-Étienne. All rights reserved.
//

import Foundation

public struct AssetCatalog {

    enum AssetCatalogError: Error {
        case CouldNotInterpretImageSizesFromJSON
        case CouldNotUpdateContents
    }

    private let path: URL
    
    private var jsonPath: URL {
        return path.appendingPathComponent("Contents.json")
    }
    
    private var jsonContents: [String: Any]?

    internal var jsonRepresentation: [String: Any]? {
        return jsonContents
    }

    public var sizes: [SizeDescription] {
        if let jsonSizes = jsonContents?["images"] as? [[String: String]] {
            return jsonSizes.map { jsonSize -> SizeDescription? in
                return SizeDescription(json: jsonSize)
                }.flatMap { $0 }
        } else {
            return []
        }
    }
    
    public static func findAppIconSets(inFolder folder: URL) -> [URL] {
        return AssetCatalog.findItems(withExtension: "appiconset", inFolder: folder)
    }
    
    public static func findItems(withExtension fileExtension: String, inFolder folder: URL) -> [URL] {
        let keys = [URLResourceKey.isDirectoryKey]
        if let enumerator = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: keys) {
            let allPaths = enumerator.allObjects as! [URL]
            return allPaths.filter { $0.pathExtension == fileExtension }
        } else {
            return []
        }
    }
    
    public init(atPath aPath: URL) {
        path = aPath
        jsonContents = readContents(atPath: jsonPath)
    }

    public mutating func update(with resizedImages: [ResizedImage]) throws {
        guard let jsonSizes = jsonContents?["images"] as? [[String: String]] else {
            throw AssetCatalogError.CouldNotInterpretImageSizesFromJSON
        }

        jsonContents?["images"] = jsonSizes
            .map { jsonSize -> [String: String]? in
                guard let jsonSizeDescription = SizeDescription(json: jsonSize) else {
                    return nil
                }

                let resizedImage = resizedImages.first { resizedImage -> Bool in
                    resizedImage.sizeDescription == jsonSizeDescription
                }

                var newJsonSize = jsonSize
                newJsonSize["filename"] = resizedImage?.filename

                return newJsonSize
            }
            .flatMap { $0 }

        if let jsonContents = jsonContents {
            try write(jsonContents: jsonContents, atPath: jsonPath)
        } else {
            throw AssetCatalogError.CouldNotUpdateContents
        }
    }

    // MARK: - Private helpers
    private func readContents(atPath path: URL) -> [String: Any]? {
        if let data = try? Data(contentsOf: path),
            let JSON = try? JSONSerialization.jsonObject(with: data) {
            return JSON as? [String: Any]
        } else {
            return nil
        }
    }

    private func write(jsonContents contents: [String: Any], atPath path: URL) throws {
        try JSONSerialization
            .data(withJSONObject: contents, options: .prettyPrinted)
            .write(to: path)
    }

}
