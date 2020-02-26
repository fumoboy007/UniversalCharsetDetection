# UniversalCharsetDetection

A Swift wrapper around the [`uchardet` library](https://www.freedesktop.org/wiki/Software/uchardet/) to detect the [character encoding](https://en.wikipedia.org/wiki/Character_encoding) of a sequence of bytes.

`uchardet` is more versatile than [`NSString.stringEncoding(for:encodingOptions:convertedString:usedLossyConversion:)`](https://developer.apple.com/documentation/foundation/nsstring/1413576-stringencoding) because
- it supports many more encodings;
- it supports streaming large files; and
- its output is compatible with [`iconv`](https://en.wikipedia.org/wiki/Iconv).

## Usage

Compatible with Swift 4.2+.

- To integrate the library into your project, add a dependency on this package in your project’s Swift Package Manager configuration file or in your Xcode 11+ project.
- To detect the character encoding of a file, see `CharacterEncodingDetector+File`.
- To detect the character encoding of a collection of bytes, see `DataProtocol+CharacterEncoding`.
- To detect the character encoding of a manually-provided stream of bytes, see `CharacterEncodingDetector`.

## License

See the `LICENSE.md` file.

## Contributing

Since the Swift Package Manager does not yet support binary dependencies, we copy the `uchardet` source code into the `Sources/Cuchardet` directory to enable the Swift Package Manager to build and link with the `uchardet` library. See the `adapt-uchardet-to-swiftpm` script.

To change the version of the `uchardet` library, run the following commands in the root of the source code directory tree:
```
$ git init uchardet
$ git submodule update --remote uchardet
$ cd uchardet
$ git checkout <master or tag name>
$ cd ..
$ ./adapt-uchardet-to-swiftpm
```
