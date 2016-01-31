# SGASScreenRecorder :movie_camera:

##### Unfortunately, this no longer works when running on iOS 9.x. The behavior of `IOMobileFramebufferGetLayerDefaultSurface()` function has changed at it seems that there is no longer a way to access the screen's surface to capture video samples from. More details can be found in StackOverflow answer by [@jvisenti](https://github.com/jvisenti) here: http://stackoverflow.com/a/32512999/1987487.

Super-efficient, highly convenient, and easily configurable screen recording for iOS apps.

**Warning**: This is only meant to be used during development in debug and in-house testing builds and is completely **NOT** App Store-safe.

### What

It allows you to continuously record whatever is happening on the device's screen while your application is in foreground and save this recording either to a video file or to device's Photo Library.

### How

Screen capture is done using low-level functions from the `IOKit`, `IOSurface` and `IOMobileFramebuffer` *private* frameworks. This mostly boils down to `IOMobileFramebufferGetLayerDefaultSurface()` and `IOSurfaceAcceleratorTransferSurface()` calls.

Capturing is done from a callback of a `CADisplayLink` scheduled on a background thread's runloop to minimize performance impact on application code. There's no busy waiting and no operations are performed on the main thread during capture.

### Why

* Because recording in-app activities has never been simpler
* Because a video is worth a thousand words of any bug report

### What's Inside

* Screen recorder
* Photo library import for recorded videos
* Screen corner overlay UI for convenient integration
* On-screen touch visualization during screen recording

## Usage

Use [CocoaPods](http://cocoapods.org) to quickly run the example project:

	pod try SGASScreenRecorder


## Requirements

* iOS 7.0.0 and above
* iOS devices only. Will build for and run on iOS Simulator, but will not do any actual recording


## Installation

SGASScreenRecorder is available through [CocoaPods](http://cocoapods.org).

### Simple

For a simple all-in-one installation, add the following line to your Podfile:

    pod 'SGASScreenRecorder', '~> 1.0'

To initialize the screen recording UI overlay, run something along the following lines:

```objc
- (void)setupScreenRecorderUIManager {
#ifndef APPSTORE
    SGASScreenRecorderSettings *settings = [SGASScreenRecorderSettings new];
    _screenRecorderUIManager = [[SGASScreenRecorderUIManager alloc] initWithScreenCorner:UIRectCornerTopLeft
                                                                  screenRecorderSettings:settings];
#endif
}
```

Make sure to use compile-time checks/preprocessor macros to prevent this code from getting to App Store builds.

Feel free to peek into the demo project for more details.

### Granular

If you do not need the recording overlay UI and would rather prefer to start and stop recording yourself, you could only import what you need:

* Use `pod 'SGASScreenRecorder/SGASScreenRecorder', '~> 1.0'` to get just the screen recorder

or

* Use `pod 'SGASScreenRecorder/SGASPhotoLibraryScreenRecorder', '~> 1.0'` to get the screen recorder plus Photo Library import support


## Authors

[@Shmatlay](https://github.com/Shmatlay), [@sanekgusev](https://github.com/sanekgusev)

This project was initially based on the early versions of [RecordMyScreen](https://github.com/coolstar/RecordMyScreen) project and was privately developed by [@Shmatlay](https://github.com/Shmatlay), who added screen overlay controls, touch visualization, and saving to the Photo Library. With Andrey's permission, I later refactored the project, transitioned it to ARC, made it more modular, and completely rewrote the capturing code to support iOS8, improve performance and memory footprint.

I can be bugged via the following:

* [@sanekgusev](https://twitter.com/sanekgusev) on Twitter
* [@sanekgusev](https://telegram.me/sanekgusev) on Telegram
* [sanekgusev@gmail.com](mailto:sanekgusev@gmail.com)


## License

SGASScreenRecorder is available under the MIT license. See the LICENSE file for more info.

