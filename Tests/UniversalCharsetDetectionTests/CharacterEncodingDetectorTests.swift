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

final class CharacterDecodingDetectorTests: XCTestCase {
   // MARK: - Private Properties

   private let characterEncodingDetector = CharacterEncodingDetector()

   // MARK: - Tests

   func testNoData() {
      let characterEncoding = characterEncodingDetector.finish()

      XCTAssertNil(characterEncoding)
   }

   func testDetection() {
      let nonASCIIText = "こんにちは世界！"
      let shiftJISBytes = nonASCIIText.data(using: .shiftJIS)!

      XCTAssertTrue(characterEncodingDetector.analyzeNextChunk(shiftJISBytes))
      let characterEncoding = characterEncodingDetector.finish()

      XCTAssertEqual(characterEncoding, "SHIFT_JIS")
   }

   func testReset() {
      let nonASCIIText = "こんにちは世界！"
      let shiftJISBytes = nonASCIIText.data(using: .shiftJIS)!
      let utf8Bytes = nonASCIIText.data(using: .utf8)!

      XCTAssertTrue(characterEncodingDetector.analyzeNextChunk(shiftJISBytes))
      characterEncodingDetector.reset()
      XCTAssertTrue(characterEncodingDetector.analyzeNextChunk(utf8Bytes))
      let characterEncoding = characterEncodingDetector.finish()

      XCTAssertEqual(characterEncoding, "UTF-8")
   }
}
