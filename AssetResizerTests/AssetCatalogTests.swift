//
//  AssetCatalogTests.swift
//  AssetResizer
//
//  Created by Jean-Étienne on 2/6/17.
//  Copyright © 2017 Jean-Étienne. All rights reserved.
//

import XCTest

@testable import AssetResizer

class AssetCatalogTests: XCTestCase {

    override func setUp() {
        super.setUp()
        TestData.createCacheFolder()
        TestData.copyCompressedSampleAppIconSetToCacheFolder()
        TestData.decompressSampleAppIconSet()
    }

    override func tearDown() {
        super.tearDown()
        TestData.removeCacheFolder()
    }

    func testFindAssetCatalog() {
        let paths = AssetCatalog.findAppIconSets(inFolder: URL.cacheFolder)

        XCTAssertEqual(paths.count, 1, "AssetCatalog didn't find exactly one .appiconset")
    }
    
    func testNotFindAssetCatalogInsideAssetCatalog() {
        let paths = AssetCatalog.findAppIconSets(inFolder: URL.cacheFolder.appendingPathComponent("SampleAppIcon.appiconset"))

        XCTAssertEqual(paths.count, 0, "AssetCatalog found an .appiconset")
    }

    func testGettingSizes() {
        let paths = AssetCatalog.findAppIconSets(inFolder: URL.cacheFolder)
        let appIconSetPath = paths[0]
        let assetCatalog = AssetCatalog(atPath: appIconSetPath)
        let sizes = assetCatalog.sizes

        XCTAssertEqual(sizes.count, 44, "AssetCatalog didn't find exactly 44 sizes")
    }

    func testGettingNoSizes() {
        let assetCatalog = AssetCatalog(atPath: URL.cacheFolder)
        let sizes = assetCatalog.sizes

        XCTAssertEqual(sizes.count, 0, "AssetCatalog found some sizes")
    }

    func testUpdate() {
        let originalImage = TestData.image(named: "sample-red-app-icon")!
        let paths = AssetCatalog.findAppIconSets(inFolder: URL.cacheFolder)
        let appIconSetPath = paths[0]
        var assetCatalog = AssetCatalog(atPath: appIconSetPath)

        let resizedImages = assetCatalog.sizes.map { sizeDescription -> ResizedImage? in
            return ResizedImage(original: originalImage,
                                name: sizeDescription.canonicalName,
                                resizing: sizeDescription,
                                bitmapType: .PNG)
            }.flatMap { $0 }

        do {
            try assetCatalog.update(with: resizedImages)
        } catch {
            XCTAssertTrue(false, "AssetCatalog could not update the contents")
        }

        if let updatedSizes = AssetCatalog(atPath: appIconSetPath).jsonRepresentation?["images"] as? [[String: String]] {
            let updatedFilenames = updatedSizes.map { $0["filename"] }.flatMap { $0 }.sorted()
            let expectedFilenames = [
                "car-60x60@2x.png",
                "car-60x60@3x.png",
                "ipad-20x20@1x.png",
                "ipad-20x20@2x.png",
                "ipad-29x29@1x.png",
                "ipad-29x29@2x.png",
                "ipad-40x40@1x.png",
                "ipad-40x40@2x.png",
                "ipad-50x50@1x.png",
                "ipad-50x50@2x.png",
                "ipad-72x72@1x.png",
                "ipad-72x72@2x.png",
                "ipad-76x76@1x.png",
                "ipad-76x76@2x.png",
                "ipad-83x83@2x.png",
                "iphone-20x20@2x.png",
                "iphone-20x20@3x.png",
                "iphone-29x29@1x.png",
                "iphone-29x29@2x.png",
                "iphone-29x29@3x.png",
                "iphone-40x40@2x.png",
                "iphone-40x40@3x.png",
                "iphone-57x57@1x.png",
                "iphone-57x57@2x.png",
                "iphone-60x60@2x.png",
                "iphone-60x60@3x.png",
                "mac-16x16@1x.png",
                "mac-16x16@2x.png",
                "mac-32x32@1x.png",
                "mac-32x32@2x.png",
                "mac-128x128@1x.png",
                "mac-128x128@2x.png",
                "mac-256x256@1x.png",
                "mac-256x256@2x.png",
                "mac-512x512@1x.png",
                "mac-512x512@2x.png",
                "watch-24x24@2x.png",
                "watch-27x27@2x.png",
                "watch-29x29@2x.png",
                "watch-29x29@3x.png",
                "watch-40x40@2x.png",
                "watch-44x44@2x.png",
                "watch-86x86@2x.png",
                "watch-98x98@2x.png"
            ].sorted()

            XCTAssertEqual(updatedFilenames, expectedFilenames, "AssetCatalog didn't find the expected updated contents")
        } else {
            XCTAssertTrue(false, "AssetCatalog could not read the updated catalog")
        }
    }

}
