# SGASScreenRecorder :movie_camera:

[![CI Status](http://img.shields.io/travis/Alexander Gusev/SGASScreenRecorder.svg?style=flat)](https://travis-ci.org/Alexander Gusev/SGASScreenRecorder)

Efficient, convenient, and configurable screen recording for iOS apps.

**WARNING:** This is only meant to be used during development in debug and in-house testing builds and is completely **NOT** App Store-safe.

### What

It allows you to continuosly record whatever is happening on the screen while your app is in foreground and save this recording either to a video file or to device's photo library.

### How

Screen capture is done using low-level functions from the `IOKit`, `IOSurface` and `IOMobileFramebuffer` *private* frameworks. This mostly boils down to `IOMobileFramebufferGetLayerDefaultSurface` and `IOSurfaceAcceleratorTransferSurface` calls.

Capturing is done from a callback of a `CADisplayLink` scheduled on a background thread's runloop to minimize performance impact on application code. There's no busy waiting and no operations are performed on the main thread during capture.

### Why

* Because recording in-app activities has never been quicker and simpler
* Because a video is worth a thousand words of any bug report

### What's inside

* Configurable screen recorder
* Photo library import for recorded videos
* Screen corner overlay UI for convenient integration
* On-screen touch visualization during screen recording

## Usage

Use [CocoaPods](http://cocoapods.org) to quickly run the example project:

	pod try SGASScreenRecorder


## Requirements

* iOS 7.0 and above
* iOS devices only. Will build for and run on iOS Simulator, but will not do any actual recording


## Installation

SGASScreenRecorder is available through [CocoaPods](http://cocoapods.org).

### Simple

For a simple all-in-one installation, add the following line to your Podfile:

    pod "SGASScreenRecorder", ~> 1.0

To initialize the screen recording UI overlay, run something along the following lines:

```objc
- (void)setupScreenRecorderUIManager {
    SGASScreenRecorderSettings *settings = [SGASScreenRecorderSettings new];
    _screenRecorderUIManager = [[SGASScreenRecorderUIManager alloc] initWithScreenCorner:UIRectCornerTopLeft
                                                                  screenRecorderSettings:settings];
}
```

Make sure to use compile-time checks/preprocessor macros to prevent this code from getting to App Store buils.

Feel free to peek into the demo project for more details.

### Granular

If you do not need the recording overlay UI and would rather prefer to start and stop recording yourself, you could only import what you need:

* Use `pod "SGASScreenRecorder/SGASScreenRecorder", ~> 1.0` to get just the screen recorder
or
* Use `pod "SGASScreenRecorder/SGASPhotoLibraryScreenRecorder", ~> 1.0` to also get Photo Library import support


## Authors

@Shmatlay, @sanekgusev

This was initially based on the early versions of [RecordMyScreen](https://github.com/coolstar/RecordMyScreen) project and was privately developed by [Andrey Shmatlay](https://github.com/Shmatlay), who added status bar overlay support and saving to the photo library support. With Andrey's permission, I, Alexander Gusev, later refactored the project, transitioned it to ARC, made it more modular, and completely rewrote the capturing code to support iOS8.

Alexander Gusev is the current maintainer of the project.

* [sanekgusev@gmail.com](mailto:sanekgusev@gmail.com)
* [@sanekgusev](https://twitter.com/sanekgusev) on Twitter
* [@sanekgusev](https://telegram.me/sanekgusev) on Telegram


## License

SGASScreenRecorder is available under the MIT license. See the LICENSE file for more info.

