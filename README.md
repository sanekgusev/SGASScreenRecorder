# SGASScreenRecorder :movie_camera:

[![CI Status](http://img.shields.io/travis/Alexander Gusev/SGASScreenRecorder.svg?style=flat)](https://travis-ci.org/Alexander Gusev/SGASScreenRecorder)

Efficient, convenient, and configurable screen recorder for iOS apps.

**NOTE:** This is only meant to be used during development in debug and in-house testing builds and is completely **NOT** Appstore-safe.

### What

It allows you to continuosly record whatever is happening on the screen while your app is in foreground and save this recording either to an mp4 file or to device's photo library.

### How

Screen capture is done using low-level functions from the `IOKit`, `IOSurface` and `IOMobileFramebuffer` private frameworks.

Capturing is done from a callback of a display link running in a background thread to minimize performance impact on application code. There's no busy waiting and no operations are performed on the main thread during capture.

### Why

* because recording in-app activities has never been simpler
* because a video is worth a thousand words, especially if those words are in a bug report

### What's in:

* Screen recorder
* Photo library export support
* Status bar overlay HUD UI for convenient integration

## Usage

To run the example project, run `pod try SGASScreenRecorder`.

## Requirements

* iOS 7.0 and above
* iOS Device only. Will compile and build for iOS Simulator too, but will not do anything.

## Installation

SGASScreenRecorder is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

    pod "SGASScreenRecorder"

## Authors

[Andrey Shmatlay](https://github.com/Shmatlay), Alexander Gusev

This was initially based on the early versions of [RecordMyScreen](https://github.com/coolstar/RecordMyScreen) project and was privately developed by [Andrey Shmatlay](https://github.com/Shmatlay), who added status bar overlay support and saving to the photo library support. With Andrey's permission, I, Alexander Gusev, later refactored the project, transitioned it to ARC, made it more modular, and completely rewrote the capturing code to support iOS8.

Alexander Gusev is the current maintainer of the project.
Email: [sanekgusev@gmail.com](mailto:sanekgusev@gmail.com)
Twitter: [@sanekgusev](https://twitter.com/sanekgusev)


## License

SGASScreenRecorder is available under the MIT license. See the LICENSE file for more info.

