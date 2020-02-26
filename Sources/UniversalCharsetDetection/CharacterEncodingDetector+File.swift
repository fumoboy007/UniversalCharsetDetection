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

import Dispatch
import Foundation

extension CharacterEncodingDetector {
   /**
    Detects the character encoding of a file.

    - Parameter fileURL: The URL of the target file. The file does not need to be seekable.
    - Parameter queue: The dispatch queue on which to perform the analysis.
    - Parameter completionQueue: The dispatch queue on which to call the completion handler.
    - Parameter completionHandler: The closure to call after the potentially-asynchronous operation is finished.
    - Parameter characterEncoding: The `iconv`-compatible identifier of the detected character encoding, or
                                   `nil` if detection failed.

    - Throws: An error if the file could not be opened.

    - Returns: A closure to cancel the operation. The completion handler will still be called even if the operation is canceled.
    */
   @discardableResult
   public static func detectCharacterEncoding(ofFileAt fileURL: URL,
                                              on queue: DispatchQueue,
                                              completionQueue: DispatchQueue,
                                              completionHandler: @escaping (_ characterEncoding: String?) -> Void) throws -> () -> Void {
      precondition(fileURL.isFileURL)
      let fileHandle = try FileHandle(forReadingFrom: fileURL)

      let completionHandlerWithCleanup: (String?) -> Void = { characterEncoding in
         // Retain the file handle in the completion handler to prevent it from
         // being deinitialized before we finish reading the data.
         _ = fileHandle

         completionHandler(characterEncoding)
      }

      return detectCharacterEncoding(ofDataFromFileDescriptor: fileHandle.fileDescriptor,
                                     on: queue,
                                     completionQueue: completionQueue,
                                     completionHandler: completionHandlerWithCleanup)
   }

   /**
    Detects the character encoding of a file.

    - Attention: This method may modify the file offset of the file descriptor.

    - Parameter fileDescriptor: The file descriptor of the target file. The file descriptor does not need to be seekable.
    - Parameter queue: The dispatch queue on which to perform the analysis.
    - Parameter completionQueue: The dispatch queue on which to call the completion handler.
    - Parameter completionHandler: The closure to call after the potentially-asynchronous operation is finished.
    - Parameter characterEncoding: The `iconv`-compatible identifier of the detected character encoding, or
                                   `nil` if detection failed.

    - Returns: A closure to cancel the operation. The completion handler will still be called even if the operation is canceled.
    */
   @discardableResult
   public static func detectCharacterEncoding(ofDataFromFileDescriptor fileDescriptor: Int32,
                                              on queue: DispatchQueue,
                                              completionQueue: DispatchQueue,
                                              completionHandler: @escaping (_ characterEncoding: String?) -> Void) -> () -> Void {
      let channel = DispatchIO(type: .stream,
                               fileDescriptor: fileDescriptor,
                               queue: queue,
                               cleanupHandler: { _ in })

      return detectCharacterEncoding(ofDataFromChannel: channel,
                                     on: queue,
                                     completionQueue: completionQueue,
                                     completionHandler: completionHandler)
   }

   private static func detectCharacterEncoding(ofDataFromChannel channel: DispatchIO,
                                               on queue: DispatchQueue,
                                               completionQueue: DispatchQueue,
                                               completionHandler: @escaping (_ characterEncoding: String?) -> Void) -> () -> Void {
      // Set the maximum buffer size to 1 MiB. This value (along with the
      // minimum buffer size and the handler interval) can be tuned.
      // - If the value is too high, more memory is used and multithreading
      //   is less efficient because the handler is called less frequently.
      // - If the value is too low, reading is less efficient because memory
      //   allocations are more frequent.
      channel.setLimit(highWater: 1024 * 1024)

      let dispatchGroup = DispatchGroup()
      dispatchGroup.enter()

      let detector = CharacterEncodingDetector()
      channel.read(offset: 0, length: .max, queue: queue) { (done, data, error) in
         if let data = data, detector.analyzeNextChunk(data) && !done && error == 0 {
            return
         }

         dispatchGroup.leave()

         let characterEncoding = detector.finish()
         completionQueue.async {
            completionHandler(characterEncoding)
         }
      }

      dispatchGroup.notify(queue: queue) {
         // Retain the channel until it is done reading data.
         _ = channel
      }

      return {
         channel.close(flags: .stop)
      }
   }
}
