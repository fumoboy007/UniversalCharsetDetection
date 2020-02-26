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

import Cuchardet
import Foundation

/**
 Detects the character encoding of a sequence of bytes.
 */
public final class CharacterEncodingDetector {
   // MARK: - Private Properties

   private let uchardet: uchardet_t
   private var isFinished = false

   // MARK: - Public API

   public init() {
      self.uchardet = uchardet_new()
   }

   deinit {
      uchardet_delete(uchardet)
   }

   /**
    Resets the detector so that it can analyze a new sequence of bytes.
    */
   public func reset() {
      uchardet_reset(uchardet)
      isFinished = false
   }

   /**
    Analyzes the next chunk of bytes in the sequence.

    If the operation fails, you may call `finish()` to get a best-effort detection result.

    - Precondition: After `finish()` is called, `reset()` must be called before a new analysis can performed.

    - Parameter data: The next chunk of bytes in the sequence.

    - Returns: Whether the operation was successful. The operation may fail, for example,
               if there is no more available memory.
   */
   public func analyzeNextChunk<T: DataProtocol>(_ data: T) -> Bool {
      precondition(!isFinished)

      for region in data.regions {
         let status: Int32 = region.withUnsafeBytes { rawBufferPointer in
            guard let bytes = rawBufferPointer.baseAddress?.assumingMemoryBound(to: CChar.self) else {
               return 0
            }
            return uchardet_handle_data(uchardet, bytes, rawBufferPointer.count)
         }
         guard status == 0 else {
            return false
         }
      }

      return true
   }

   /**
    Finishes the analysis and returns the detection result.

    In order to get the most accurate result, call this method only after feeding all the bytes in
    the sequence to the detector.

    - Precondition: After this method is called, `reset()` must be called before a new analysis can performed.

    - Returns: The `iconv`-compatible identifier of the detected character encoding, or `nil` if
               detection failed.
    */
   public func finish() -> String? {
      precondition(!isFinished)

      uchardet_data_end(uchardet)
      isFinished = true

      let encodingIdentifier = String(cString: uchardet_get_charset(uchardet))
      guard !encodingIdentifier.isEmpty else {
         return nil
      }
      return encodingIdentifier
   }
}
