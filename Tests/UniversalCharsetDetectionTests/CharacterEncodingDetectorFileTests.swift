// MIT License
//
// Copyright © 2020 Darren Mo.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import UniversalCharsetDetection

import Foundation
import XCTest

final class CharacterEncodingDetectorFileTests: XCTestCase {
   // MARK: - Private Properties

   private static var temporaryDirectoryURL: URL!
   private var fileURL: URL!

   private static let shiftJISBytes = """
      映スセノヘ録日テヌ数件ナヤユ果6導イめざく完舞ゃーおべ優保ソエフナ癒前よあク球択ナノ国意配界ヌト解図かちぐの付締うぞわ外4枝すはみ内今況よスイみ記理ヨソケア稿玉ラテト非構イン。
      学本中れだば来17性ルヘ立行四えルば戦介ヨホコキ見神ぽイう至子ナユケ参授サネラク江均た増63済しざぼほ場祐シ院梗や六特り省映だ主7解まざそ。
      """.data(using: .shiftJIS)!
   /// Contains mostly newline characters (whose Shift-JIS-encoded bytes are ASCII-compatible) followed by a small number of Japanese characters.
   private static let largeShiftJISBytes: Data = {
      var combinedShiftJISBytes = Data(repeating: UInt8(ascii: "\n"),
                                       count: 10 * 1000 * 1000)
      combinedShiftJISBytes.append(shiftJISBytes)

      return combinedShiftJISBytes
   }()

   private enum CharacterEncoding: String {
      case shiftJIS = "SHIFT_JIS"
      case ascii = "ASCII"
   }

   // MARK: - Setup/Teardown

   override class func setUp() {
      super.setUp()

      temporaryDirectoryURL =
         try! FileManager.default.url(for: .itemReplacementDirectory,
                                      in: .userDomainMask,
                                      appropriateFor: URL(fileURLWithPath: NSTemporaryDirectory(),
                                                          isDirectory: true),
                                      create: true)
   }

   override func setUp() {
      super.setUp()

      fileURL = Self.temporaryDirectoryURL.appendingPathComponent("CharacterEncodingDetectorFileTests \(UUID().uuidString).txt")
   }

   override func tearDown() {
      try? FileManager.default.removeItem(at: fileURL)

      super.tearDown()
   }

   override class func tearDown() {
      try! FileManager.default.removeItem(at: temporaryDirectoryURL)

      super.tearDown()
   }

   // MARK: - Tests

   func testInvalidFile() {
      XCTAssertThrowsError(try CharacterEncodingDetector.detectCharacterEncoding(ofFileAt: fileURL,
                                                                                 on: .main,
                                                                                 completionQueue: .main,
                                                                                 completionHandler: { _ in }))
   }

   func testEmptyFile() throws {
      try writeDataToFile(Data())

      let expectation = self.expectation(description: "Expected the completion handler to be called.")
      // TODO: Remove assignment to underscore after SR-12271 is fixed.
      _ = try CharacterEncodingDetector.detectCharacterEncoding(ofFileAt: fileURL, on: .main, completionQueue: .main) { characterEncoding in
         XCTAssertNil(characterEncoding)

         expectation.fulfill()
      }

      waitForExpectations(timeout: 1, handler: nil)
   }

   func testFile() throws {
      try writeDataToFile(Self.shiftJISBytes)

      let expectation = self.expectation(description: "Expected the completion handler to be called.")
      // TODO: Remove assignment to underscore after SR-12271 is fixed.
      _ = try CharacterEncodingDetector.detectCharacterEncoding(ofFileAt: fileURL, on: .main, completionQueue: .main) { characterEncoding in
         XCTAssertEqual(characterEncoding, CharacterEncoding.shiftJIS.rawValue)

         expectation.fulfill()
      }

      waitForExpectations(timeout: 1, handler: nil)
   }

   func testFile_cancellation() throws {
      try writeDataToFile(Self.largeShiftJISBytes)

      var cancelOperation: () -> Void = {}
      DispatchQueue.main.async {
         cancelOperation()
      }

      let expectation = self.expectation(description: "Expected the completion handler to be called.")
      cancelOperation = try CharacterEncodingDetector.detectCharacterEncoding(ofFileAt: fileURL, on: .main, completionQueue: .main) { characterEncoding in
         if let characterEncoding = characterEncoding {
            XCTAssertEqual(characterEncoding, CharacterEncoding.ascii.rawValue)
         } else {
            // `nil` is also possible if the operation was canceled before any data was read.
         }

         expectation.fulfill()
      }

      waitForExpectations(timeout: 1, handler: nil)
   }

   func testFileDescriptor() throws {
      try writeDataToFile(Self.shiftJISBytes)

      let fileHandle = try FileHandle(forReadingFrom: fileURL)

      let expectation = self.expectation(description: "Expected the completion handler to be called.")
      // TODO: Remove assignment to underscore after SR-12271 is fixed.
      _ = CharacterEncodingDetector.detectCharacterEncoding(ofDataFromFileDescriptor: fileHandle.fileDescriptor, on: .main, completionQueue: .main) { characterEncoding in
         XCTAssertEqual(characterEncoding, CharacterEncoding.shiftJIS.rawValue)

         expectation.fulfill()
      }

      waitForExpectations(timeout: 1, handler: nil)
   }

   func testFileDescriptor_cancellation() throws {
      try writeDataToFile(Self.largeShiftJISBytes)

      let fileHandle = try FileHandle(forReadingFrom: fileURL)

      var cancelOperation: () -> Void = {}
      DispatchQueue.main.async {
         cancelOperation()
      }

      let expectation = self.expectation(description: "Expected the completion handler to be called.")
      cancelOperation = CharacterEncodingDetector.detectCharacterEncoding(ofDataFromFileDescriptor: fileHandle.fileDescriptor, on: .main, completionQueue: .main) { characterEncoding in
         if let characterEncoding = characterEncoding {
            XCTAssertEqual(characterEncoding, CharacterEncoding.ascii.rawValue)
         } else {
            // `nil` is also possible if the operation was canceled before any data was read.
         }

         expectation.fulfill()
      }

      waitForExpectations(timeout: 1, handler: nil)
   }

   func testLargeFile() throws {
      try writeDataToFile(Self.largeShiftJISBytes)

      let expectation = self.expectation(description: "Expected the completion handler to be called.")
      // TODO: Remove assignment to underscore after SR-12271 is fixed.
      _ = try CharacterEncodingDetector.detectCharacterEncoding(ofFileAt: fileURL, on: .main, completionQueue: .main) { characterEncoding in
         XCTAssertEqual(characterEncoding, CharacterEncoding.shiftJIS.rawValue)

         expectation.fulfill()
      }

      waitForExpectations(timeout: 1, handler: nil)
   }

   // MARK: - Helpers

   private func writeDataToFile(_ data: Data) throws {
      try data.write(to: fileURL,
                     options: .withoutOverwriting)
   }
}
