import AppKit
final class CaptureCheckView: NSView {
    override func draw(_ dirtyRect: NSRect) {
        NSColor.white.setFill();bounds.fill()
        ("beautifull" as NSString).draw(at:CGPoint(x:130,y:110),withAttributes:[.font:NSFont.systemFont(ofSize:32),.foregroundColor:NSColor.black])
    }
}
func runCaptureCheck() {
    let app=NSApplication.shared
    guard CGPreflightScreenCaptureAccess() else { print("CAPTURE CHECK BLOCKED: Enable Screen Recording for Nailong, then restart it.");exit(2) }
    app.setActivationPolicy(.accessory)
    let window=NSWindow(contentRect:CGRect(x:250,y:200,width:600,height:300),styleMask:[.titled],backing:.buffered,defer:false)
    let view=CaptureCheckView(frame:CGRect(x:0,y:0,width:600,height:300));window.contentView=view
    let scanner=VisualScanner()
    func sample(_ count:Int) {
        window.setFrameOrigin(CGPoint(x:count==0 ? 250:470,y:count==0 ? 200:320))
        window.orderFrontRegardless();view.display()
        DispatchQueue.main.asyncAfter(deadline:.now()+0.8) {
            let local=CGRect(x:130,y:110,width:160,height:40)
            let cocoa=window.convertToScreen(view.convert(local,to:nil))
            let expected=CGRect(x:cocoa.minX,y:NSScreen.screens[0].frame.maxY-cocoa.maxY,width:cocoa.width,height:cocoa.height)
            scanner.scan(pid:ProcessInfo.processInfo.processIdentifier,windowRect:nil,region:expected.insetBy(dx:-80,dy:-50)) { words,error in
                guard let found=words?.first(where:{$0.text.lowercased()=="beautifull"}) else { print("FAIL CAPTURE",error ?? "word missing");exit(1) }
                print("CAPTURE",count,"expected text region",expected,"observed",found.rect)
                guard abs(found.rect.minX-expected.minX)<8, expected.insetBy(dx:-8,dy:-8).contains(found.rect) else { print("FAIL: target shifted away from visible word");exit(1) }
                if count==0 { sample(1) } else { print("PASS: actual ScreenCaptureKit OCR aligns at two window positions");exit(0) }
            }
        }
    }
    sample(0);app.run()
}
