import AppKit
import ScreenCaptureKit
import Vision

struct VisualWord { let text: String; let rect: CGRect }
final class VisualScanner {
    var busy = false
    private let queue = DispatchQueue(label:"local.nailong.vision",qos:.utility)
    // The screenshot stays in memory and is never written to disk.
    func scan(pid: pid_t, windowRect: CGRect?, region: CGRect, completion: @escaping ([VisualWord]?,String?) -> Void) {
        guard !busy else { return }; busy = true
        SCShareableContent.getExcludingDesktopWindows(true,onScreenWindowsOnly:true) { content,error in
            guard let content = content else { DispatchQueue.main.async { self.busy=false; completion(nil,"Screen access unavailable. Enable Screen Recording, then restart Nailong.") }; return }
            let windows = content.windows.filter { $0.owningApplication?.processID == pid && $0.windowLayer == 0 && $0.frame.width > 100 && $0.frame.height > 80 }
            let ordered = CGWindowListCopyWindowInfo([.optionOnScreenOnly,.excludeDesktopElements],kCGNullWindowID) as? [[String:Any]] ?? []
            let frontID = ordered.first { ($0[kCGWindowOwnerPID as String] as? Int)==Int(pid) && ($0[kCGWindowLayer as String] as? Int)==0 }?[kCGWindowNumber as String] as? UInt32
            let front = windows.first { $0.windowID==frontID }
            let window = front ?? windows.min { a,b in
                guard let r = windowRect else { return a.frame.contains(region.center) && !b.frame.contains(region.center) }
                return abs(a.frame.minX-r.minX)+abs(a.frame.minY-r.minY)+abs(a.frame.width-r.width) < abs(b.frame.minX-r.minX)+abs(b.frame.minY-r.minY)+abs(b.frame.width-r.width)
            }
            guard let window=window else { DispatchQueue.main.async { self.busy=false; completion(nil,"No capturable foreground window.") }; return }
            // Capture in display coordinates, not a separately rendered window image.
            // A window image may have a different content origin/scale than SCWindow.frame.
            let windowRegion = region.intersection(window.frame)
            guard let display = content.displays.max(by: {
                $0.frame.intersection(windowRegion).area < $1.frame.intersection(windowRegion).area
            }), let geometry = ScreenCaptureGeometry(region:windowRegion, display:display.frame) else {
                DispatchQueue.main.async { self.busy=false; completion([],nil) }; return
            }
            let roi = geometry.region
            let filter = SCContentFilter(display:display,including:[window])
            let config = SCStreamConfiguration()
            config.sourceRect = geometry.sourceRect
            config.width = Int(roi.width*2); config.height = Int(roi.height*2)
            config.destinationRect = CGRect(x:0,y:0,width:config.width,height:config.height)
            config.scalesToFit=false; config.showsCursor=false
            config.ignoreShadowsDisplay=true; config.captureResolution = .nominal
            SCScreenshotManager.captureImage(contentFilter:filter,configuration:config) { image,error in
                guard let image=image else { DispatchQueue.main.async { self.busy=false; completion(nil,"Could not capture the selected screen region.") }; return }
                // Do not point at a stale location if the browser moved during capture.
                let latest = CGWindowListCopyWindowInfo(.optionIncludingWindow,window.windowID) as? [[String:Any]]
                if let bounds=latest?.first?[kCGWindowBounds as String] as? NSDictionary,
                   let current=CGRect(dictionaryRepresentation:bounds),
                   abs(current.minX-window.frame.minX)>1 || abs(current.minY-window.frame.minY)>1 || abs(current.width-window.frame.width)>1 || abs(current.height-window.frame.height)>1 {
                    DispatchQueue.main.async { self.busy=false; completion(nil,"Window moved. Checking again…") }; return
                }
                self.queue.async {
                    let words = Self.recognize(image: image, window:roi, region:roi)
                    DispatchQueue.main.async { self.busy=false; completion(words,nil) }
                }
            }
        }
    }
    static func recognize(image: CGImage, window: CGRect, region: CGRect) -> [VisualWord] {
        let clipped=region.intersection(window)
        guard !clipped.isNull, clipped.width>0, clipped.height>0 else { return [] }
        let scaleX=CGFloat(image.width)/window.width, scaleY=CGFloat(image.height)/window.height
        let pixels=CGRect(x:(clipped.minX-window.minX)*scaleX,y:(clipped.minY-window.minY)*scaleY,width:clipped.width*scaleX,height:clipped.height*scaleY).integral.intersection(CGRect(x:0,y:0,width:image.width,height:image.height))
        guard let crop=image.cropping(to:pixels) else { return [] }
        let mapped=CGRect(x:window.minX+pixels.minX/scaleX,y:window.minY+pixels.minY/scaleY,width:pixels.width/scaleX,height:pixels.height/scaleY)
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false // Preserve the misspelling rather than silently correcting OCR.
        request.recognitionLanguages = ["en-US"]
        do { try VNImageRequestHandler(cgImage:crop,options:[:]).perform([request]) } catch { return [] }
        var words: [VisualWord] = []
        let regex = try! NSRegularExpression(pattern:"[A-Za-z]{3,}(?:['’][A-Za-z]+)?")
        for observation in request.results ?? [] {
            guard let candidate=observation.topCandidates(1).first, candidate.confidence > 0.65 else { continue }
            let text=candidate.string
            for match in regex.matches(in:text,range:NSRange(text.startIndex...,in:text)) {
                guard let range=Range(match.range,in:text), let box=try? candidate.boundingBox(for:range) else { continue }
                let b=box.boundingBox
                let rect=CGRect(x:mapped.minX+b.minX*mapped.width,y:mapped.minY+(1-b.maxY)*mapped.height,width:b.width*mapped.width,height:b.height*mapped.height)
                words.append(VisualWord(text:String(text[range]),rect:rect))
            }
        }
        return words
    }
}
extension CGRect { var center: CGPoint { CGPoint(x:midX,y:midY) } }

// Quartz screen coordinates use a top-left origin, including on secondary displays.
struct ScreenCaptureGeometry {
    let region: CGRect
    let sourceRect: CGRect
    init?(region: CGRect, display: CGRect) {
        let clipped = region.intersection(display).integral.intersection(display)
        guard !clipped.isNull, clipped.width>10, clipped.height>10 else { return nil }
        self.region = clipped
        sourceRect = clipped.offsetBy(dx:-display.minX,dy:-display.minY)
    }
}
private extension CGRect {
    var area: CGFloat { isNull ? 0 : max(0,width)*max(0,height) }
}
