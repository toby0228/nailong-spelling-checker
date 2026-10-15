import AppKit
import Vision

func runSelfTests() {
    _ = NSApplication.shared
    for display in [CGRect(x:0,y:0,width:1470,height:956), CGRect(x:-1920,y:-240,width:1920,height:1080)] {
        let selected=CGRect(x:display.minX+300,y:display.minY+150,width:900,height:240)
        let geometry=ScreenCaptureGeometry(region:selected,display:display)!
        assert(geometry.sourceRect==CGRect(x:300,y:150,width:900,height:240))
        assert(geometry.region==selected)
        let clipped=ScreenCaptureGeometry(region:CGRect(x:display.minX-100,y:display.minY-30,width:300,height:200),display:display)!
        assert(clipped.sourceRect==CGRect(x:0,y:0,width:200,height:170))
    }
    let engine=SpellEngine()
    let text="Hello 🦕, a beautifull day. "
    let r=engine.firstTypo(text,caret:(text as NSString).length)!
    assert((text as NSString).substring(with:r)=="beautifull", "UTF-16 range must survive emoji")
    assert(engine.firstTypo("A beautiful day. ",caret:17)==nil)
    assert(engine.firstTypo("beautifull",caret:10)==nil)
    assert(engine.firstTypo("",caret:0)==nil)
    assert(engine.firstTypo("helloWorld snake_case ABCD ",caret:27)==nil)
    engine.ignored.insert("beautifull")
    assert(engine.firstTypo("beautifull ",caret:11)==nil)
    let now=Date().timeIntervalSince1970
    let good=BrowserTarget(time:now,browser:"chrome",state:"target",x:120,y:200,width:100,height:20,windowX:0,windowY:0,windowWidth:1000,windowHeight:800)
    assert(good.valid()); var old=good; old.time=now-10; assert(!old.valid())
    var bad=good; bad.x=Double.nan; assert(!bad.valid())
    bad=good; bad.width = -1; assert(!bad.valid())
    print("PASS: spelling, correction, unfinished words, ignored words, code identifiers, emoji/UTF-16, stale/invalid browser geometry")

    let width=900, height=180
    let bitmap=NSBitmapImageRep(bitmapDataPlanes:nil,pixelsWide:width,pixelsHigh:height,bitsPerSample:8,samplesPerPixel:4,hasAlpha:true,isPlanar:false,colorSpaceName:.deviceRGB,bytesPerRow:0,bitsPerPixel:0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current=NSGraphicsContext(bitmapImageRep:bitmap)
    NSColor.white.setFill(); NSRect(x:0,y:0,width:width,height:height).fill()
    ("A beautifull morning" as NSString).draw(at:NSPoint(x:40,y:65),withAttributes:[.font:NSFont.systemFont(ofSize:40),.foregroundColor:NSColor.black])
    NSGraphicsContext.restoreGraphicsState()
    let frame=CGRect(x:100,y:200,width:900,height:180)
    let words=VisualScanner.recognize(image:bitmap.cgImage!,window:frame,region:frame)
    assert(words.contains { $0.text.lowercased()=="beautifull" },"OCR must preserve typo: \(words.map(\.text))")
    assert(words.allSatisfy { frame.contains($0.rect) },"OCR coordinate mapping")
    print("PASS: local OCR preserves misspellings and maps word coordinates")
    let expectedX=frame.minX+40+("A " as NSString).size(withAttributes:[.font:NSFont.systemFont(ofSize:40)]).width
    let knownWord=words.first { $0.text.lowercased()=="beautifull" }!.rect
    assert(abs(knownWord.minX-expectedX)<8,"OCR must align with the drawn word, not a shifted rectangle")
    assert(knownWord.midY>frame.minY+65 && knownWord.midY<frame.minY+115)
    let typoBox=words.first { $0.text.lowercased()=="beautifull" }!.rect
    let cropped=VisualScanner.recognize(image:bitmap.cgImage!,window:frame,region:typoBox.insetBy(dx:-15,dy:-15))
    let croppedBox=cropped.first { $0.text.lowercased()=="beautifull" }!.rect
    assert(abs(croppedBox.midX-typoBox.midX)<4 && abs(croppedBox.midY-typoBox.midY)<4,"Cropped OCR must preserve screen coordinates")
    for screen in [CGRect(x:0,y:0,width:1440,height:900),CGRect(x:-1920,y:-300,width:1920,height:1080)] {
        for target in [CGRect(x:screen.minX+4,y:screen.minY+4,width:80,height:20),CGRect(x:screen.maxX-90,y:screen.maxY-24,width:80,height:20),CGRect(x:screen.midX,y:screen.midY,width:80,height:20)] {
            let placement=PointingPlacement.calculate(word:target,screen:screen)
            assert(screen.contains(CGRect(origin:placement.origin,size:CGSize(width:150,height:190))))
            assert(placement.facesLeft == (placement.origin.x+75>target.midX))
            assert(placement.facesLeft ? placement.fingertip.x>target.midX : placement.fingertip.x<target.midX)
        }
    }
    print("PASS: cropped OCR retains target coordinates; pointing faces the word at screen edges and on negative-origin displays")
    let controller=Controller()
    controller.panel=PetPanel(contentRect:NSRect(x:0,y:0,width:150,height:190),styleMask:[.borderless],backing:.buffered,defer:false)
    controller.pet=PetView(frame:NSRect(x:0,y:0,width:150,height:190))
    let f=NSScreen.main!.visibleFrame
    controller.home=NSPoint(x:f.minX+20,y:f.minY+20)
    controller.panel.setFrameOrigin(controller.home)
    controller.point(at:NSRect(x:f.midX,y:f.midY,width:80,height:20))
    for _ in 0..<500 { controller.animate() }
    assert(controller.pet.pose==3 && controller.pointing)
    controller.goHome()
    for _ in 0..<500 { controller.animate() }
    assert(controller.pet.pose==0 && !controller.pointing && controller.panel.frame.origin==controller.home)
    print("PASS: movement reaches the word, switches to pointing, returns exactly home, then idles")
}
