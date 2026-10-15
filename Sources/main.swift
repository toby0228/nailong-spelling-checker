import AppKit
import ApplicationServices
import ScreenCaptureKit

final class PetPanel: NSPanel {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

final class PetView: NSView {
    weak var owner: Controller?
    var frames: [NSImage] = []
    var pose = 0
    var left = false
    var phase: Double = 0
    var anchor = NSPoint.zero
    var origin = NSPoint.zero
    override func draw(_ dirtyRect: NSRect) {
        guard !frames.isEmpty else { return }
        NSGraphicsContext.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: left ? bounds.width : 0, yBy: 0)
        if left { transform.scaleX(by: -1, yBy: 1) }
        transform.concat()
        let bob = pose == 0 ? sin(phase * 2) * 1.5 : (pose == 3 ? 0 : abs(sin(phase * 12)) * 5)
        frames[pose].draw(in: NSRect(x: 0, y: bob, width: bounds.width, height: bounds.height - 7))
        NSGraphicsContext.restoreGraphicsState()
    }
    override func mouseDown(with event: NSEvent) {
        anchor = NSEvent.mouseLocation; origin = window!.frame.origin
        owner?.dragging = true
        owner?.epoch += 1
    }
    override func mouseDragged(with event: NSEvent) {
        let p = NSEvent.mouseLocation
        window?.setFrameOrigin(NSPoint(x: origin.x + p.x - anchor.x, y: origin.y + p.y - anchor.y))
    }
    override func mouseUp(with event: NSEvent) {
        owner?.dragging = false
        owner?.setHome(window!.frame.origin)
    }
    override func rightMouseDown(with event: NSEvent) {
        if let menu = owner?.menu { NSMenu.popUpContextMenu(menu, with: event, for: self) }
    }
}

final class Controller: NSObject, NSApplicationDelegate, NSTextViewDelegate {
    var panel: PetPanel!
    var pet: PetView!
    var status: NSStatusItem!
    let menu = NSMenu()
    var home = NSPoint.zero
    var destination = NSPoint.zero
    var pointLeft = false
    var pointing = false
    var dragging = false
    var paused = false
    var demo: NSWindow!
    var editor: NSTextView!
    var label: NSTextField!
    var lastText = ""
    var changedAt = Date.distantPast
    var timer: Timer?
    var scanTimer: Timer?
    let engine = SpellEngine()
    let visual = VisualScanner()
    var statusLine: NSMenuItem!
    var setup: NSWindow?
    var setupStatus: NSTextField?
    var lastFrontPID: pid_t = 0
    var lastInput = Date.distantPast
    var lastInputPID: pid_t = 0
    var lastScan = Date.distantPast
    var lastClick = CGPoint.zero
    var lastClickPID: pid_t = 0
    var manualUntil = Date.distantPast
    var manualRegion: CGRect?
    var visualApps = Set(UserDefaults.standard.stringArray(forKey:"visualApps") ?? [])
    var monitors: [Any] = []
    var epoch = 0
    var visualCandidate = ""
    var currentWord: String?
    var stateText = "Ready"
    var heartbeat: Timer?
    var overlay: TargetOverlay?
    var targetRect: CGRect?
    var countdownUntil = Date.distantPast
    var chosenBrowser = UserDefaults.standard.string(forKey:"chosenBrowser") ?? "chrome"



    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        let size = NSSize(width: 150, height: 190)
        panel = PetPanel(contentRect: NSRect(origin: .zero, size: size), styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        panel.isOpaque = false; panel.backgroundColor = .clear; panel.hasShadow = false
        panel.level = .floating; panel.hidesOnDeactivate = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        pet = PetView(frame: NSRect(origin: .zero, size: size)); pet.owner = self
        let url = Bundle.main.url(forResource: "nailong-atlas", withExtension: "png")!
        let image = NSImage(contentsOf: url)!
        var rect = NSRect(origin: .zero, size: image.size)
        let cg = image.cgImage(forProposedRect: &rect, context: nil, hints: nil)!
        for i in 0..<4 {
            let crop = cg.cropping(to: CGRect(x: i * cg.width / 4, y: 0, width: cg.width / 4, height: cg.height))!
            pet.frames.append(NSImage(cgImage: crop, size: NSSize(width: crop.width, height: crop.height)))
        }
        panel.contentView = pet
        overlay=TargetOverlay()
        let screen = NSScreen.main!.visibleFrame
        home = NSPoint(x: screen.maxX - 175, y: screen.minY + 35)
        if UserDefaults.standard.object(forKey: "homeX") != nil {
            home = NSPoint(x: UserDefaults.standard.double(forKey: "homeX"), y: UserDefaults.standard.double(forKey: "homeY"))
        }
        setHome(clamp(home)); panel.setFrameOrigin(home); panel.orderFrontRegardless()
        status = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        status.button?.title = "🟡"
        add("Nailong · Typo companion", nil)
        statusLine = NSMenuItem(title:"Ready",action:nil,keyEquivalent:""); menu.addItem(statusLine)
        add("Setup & detection status…", #selector(showSetup))
        add("Connect / repair browser…", #selector(connectBrowser))
        add("Test browser connection", #selector(testBrowser))
        menu.addItem(.separator())
        add("Open typing playground", #selector(showDemo))
        add("Enable Accessibility…", #selector(permission))
        add("Enable Screen Recording…", #selector(screenPermission))
        add("Toggle visual checking for current app", #selector(toggleVisualApp))
        add("Check around pointer in 3 seconds", #selector(checkPointer))
        add("Ignore current word", #selector(ignoreWord))
        add("Pause / resume detection", #selector(toggle))
        add("Bring pet home", #selector(goHome))
        add("Reset position", #selector(reset))
        menu.addItem(.separator()); add("Quit Nailong", #selector(quit))
        status.menu = menu
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/30, repeats: true) { [weak self] _ in self?.animate() }
        scanTimer = Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { [weak self] _ in self?.scan() }
        engine.ignored = Set(UserDefaults.standard.stringArray(forKey:"ignoredWords") ?? [])
        heartbeat = Timer.scheduledTimer(withTimeInterval:1, repeats:true) { [weak self] _ in self?.publishSettings(); self?.installMonitors(); if let self=self { self.setStatus(self.stateText) } }
        publishSettings(); installMonitors()
        showSetup()
    }
    func add(_ title: String, _ action: Selector?) { let item = NSMenuItem(title: title, action: action, keyEquivalent: ""); item.target = self; menu.addItem(item) }
    func clamp(_ p: NSPoint) -> NSPoint {
        let frame = (NSScreen.screens.first { $0.frame.contains(NSPoint(x: p.x+75, y: p.y+95)) } ?? NSScreen.main!).visibleFrame
        return NSPoint(x: max(frame.minX, min(p.x, frame.maxX-150)), y: max(frame.minY, min(p.y, frame.maxY-190)))
    }
    func setHome(_ p: NSPoint) {
        home = clamp(p); destination = home; pointing = false; targetRect=nil; overlay?.hide()
        UserDefaults.standard.set(home.x, forKey: "homeX"); UserDefaults.standard.set(home.y, forKey: "homeY")
    }
    @objc func goHome() { pointing = false; targetRect=nil; overlay?.hide(); destination = clamp(home) }
    @objc func reset() { let f = NSScreen.main!.visibleFrame; setHome(NSPoint(x:f.maxX-175,y:f.minY+35)) }
    @objc func toggle() { paused.toggle(); epoch += 1; if paused { goHome() }; status.button?.title = paused ? "⏸" : "🟡"; publishSettings(); setStatus(paused ? "Paused" : "Ready") }
    @objc func quit() { NSApp.terminate(nil) }
    @objc func permission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
        NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
    }
    func animate() {
        guard !dragging else { return }
        let p = panel.frame.origin
        let dx = destination.x-p.x, dy = destination.y-p.y, distance = hypot(dx,dy)
        pet.phase += 1.0/30
        if distance > 2 {
            let step = min(distance, 15.0)
            pet.left = dx < 0
            panel.setFrameOrigin(NSPoint(x:p.x+dx/distance*step,y:p.y+dy/distance*step))
            pet.pose = 1 + Int(pet.phase * 9) % 2
        } else {
            panel.setFrameOrigin(destination)
            pet.pose = pointing ? 3 : 0
            pet.left = pointing && pointLeft
        }
        pet.needsDisplay = true
        if let word=targetRect, let screen=NSScreen.screens.first(where:{$0.frame.intersects(word)}) {
            let finger=CGPoint(x:panel.frame.minX+(pointLeft ? 13 : 137),y:panel.frame.minY+PointingPlacement.fingerY)
            overlay?.show(word:word,finger:finger,line:pet.pose==3,screen:screen.frame)
            panel.orderFrontRegardless()
        }
    }
    func point(at rect: NSRect) {
        let screen = NSScreen.screens.first { $0.frame.intersects(rect) }
        guard let screen = screen, rect.width > 0, rect.height > 0 else { goHome(); return }
        let placement=PointingPlacement.calculate(word:rect,screen:screen.visibleFrame)
        destination=placement.origin; pointLeft=placement.facesLeft; pointing=true; targetRect=rect

    }
    func typo(_ text: String, caret: Int) -> NSRange? { engine.firstTypo(text,caret:caret) }
    func setStatus(_ text: String) {
        stateText=text; statusLine?.title=text
        let connection=Project.read(BridgeConnection.self,name:"bridge-status.json")
        let browserConnected=connection.map { Date().timeIntervalSince1970-$0.time<10 } ?? false
        setupStatus?.stringValue="Accessibility: \(AXIsProcessTrusted() ? "enabled" : "not enabled")\nScreen Recording: \(CGPreflightScreenCaptureAccess() ? "enabled" : "not enabled")\nBrowser: \(browserConnected ? "connected" : "not connected — use Test browser connection")\n\(text)"
    }
    func publishSettings() {
        Project.write(BridgeSettings(enabled:!paused,time:Date().timeIntervalSince1970,ignored:Array(engine.ignored)),name:"settings.json")
    }
    func applicationWillTerminate(_ notification: Notification) {
        Project.write(BridgeSettings(enabled:false,time:Date().timeIntervalSince1970,ignored:[]),name:"settings.json")
    }
    func installMonitors() {
        guard monitors.isEmpty, AXIsProcessTrusted() else { return }
        if let monitor=NSEvent.addGlobalMonitorForEvents(matching:[.keyDown,.leftMouseDown,.leftMouseDragged,.rightMouseDown,.scrollWheel], handler: { [weak self] event in
            guard let self=self else { return }
            self.epoch += 1
            if event.type == .keyDown { self.lastInput=Date(); self.lastInputPID=NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0 }
            if event.type == .leftMouseDown {
                let p=NSEvent.mouseLocation
                self.lastClick=CGPoint(x:p.x,y:NSScreen.screens[0].frame.maxY-p.y)
                self.lastClickPID=NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
                self.visualCandidate=""
            }
            if event.type == .scrollWheel { self.goHome(); self.visualCandidate="" }
        }) { monitors.append(monitor) }
    }
    @objc func ignoreWord() {
        guard let word=currentWord else { setStatus("No word to ignore. Browser checks use the macOS dictionary."); return }
        engine.ignored.insert(word.lowercased()); UserDefaults.standard.set(Array(engine.ignored),forKey:"ignoredWords"); publishSettings(); goHome()
    }
    @objc func screenPermission() {
        _ = CGRequestScreenCaptureAccess()
        NSWorkspace.shared.open(URL(string:"x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
    }
    @objc func toggleVisualApp() {
        guard let app=NSWorkspace.shared.frontmostApplication, app.processIdentifier != ProcessInfo.processInfo.processIdentifier, let id=app.bundleIdentifier else {
            setStatus("Switch to the app you want, then use the yellow menu-bar icon."); return
        }
        if visualApps.contains(id) { visualApps.remove(id) } else { visualApps.insert(id) }
        UserDefaults.standard.set(Array(visualApps),forKey:"visualApps"); epoch += 1; goHome()
        setStatus("Visual checking \(visualApps.contains(id) ? "on" : "off") for \(app.localizedName ?? id)")
    }
    @objc func checkPointer() {
        manualUntil = .distantPast; countdownUntil=Date().addingTimeInterval(3)
        goHome(); setStatus("In 3 seconds: point your mouse directly at the word.")
        DispatchQueue.main.asyncAfter(deadline:.now()+3) { [weak self] in
            guard let self=self, !self.paused else { return }
            let p=NSEvent.mouseLocation
            self.lastClick=CGPoint(x:p.x,y:NSScreen.screens[0].frame.maxY-p.y)
            self.lastClickPID=NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
            self.manualRegion=CGRect(x:self.lastClick.x-450,y:self.lastClick.y-120,width:900,height:240)
            self.manualUntil=Date().addingTimeInterval(25); self.lastInput=Date().addingTimeInterval(-2)
            self.visualCandidate=""; self.epoch += 1
            self.setStatus("Checking the highlighted area around your pointer…")
            if let region=self.manualRegion, let screen=NSScreen.screens.first(where:{$0.frame.contains(p)}) {
                self.overlay?.showScan(self.cocoa(region),screen:screen.frame)
            }
        }
    }
    func cgFrame(_ element: AXUIElement) -> CGRect? {
        guard let p=attr(element,kAXPositionAttribute), let s=attr(element,kAXSizeAttribute), CFGetTypeID(p)==AXValueGetTypeID(), CFGetTypeID(s)==AXValueGetTypeID() else { return nil }
        var point=CGPoint.zero; var size=CGSize.zero
        guard AXValueGetValue(p as! AXValue,.cgPoint,&point), AXValueGetValue(s as! AXValue,.cgSize,&size) else { return nil }
        return CGRect(origin:point,size:size)
    }
    func cocoa(_ r: CGRect) -> NSRect { NSRect(x:r.minX,y:NSScreen.screens[0].frame.maxY-r.maxY,width:r.width,height:r.height) }
    func browserTarget(app: NSRunningApplication, window: CGRect?) -> Bool {
        let ids=["com.google.Chrome":"chrome","com.microsoft.edgemac":"edge","com.brave.Browser":"brave","org.chromium.Chromium":"chromium"]
        guard let kind=ids[app.bundleIdentifier ?? ""], let target=Project.read(BrowserTarget.self,name:"browser-target.json"), target.browser==kind, target.valid() else { return false }
        if let w=window, let x=target.windowX, let y=target.windowY, abs(w.minX-x)>40 || abs(w.minY-y)>90 { return false }
        if target.state == "idle" { return false }
        if target.state == "docs-unavailable" {
            goHome();setStatus("Google Docs: click inside the document. If needed use the 3-second pointer check.");return true
        }
        if target.state == "visual", let x=target.x,let y=target.y,let w=target.width,let h=target.height {
            guard CGPreflightScreenCaptureAccess() else { goHome();setStatus("Google Docs needs Screen Recording. Enable it in setup, then restart Nailong.");return true }
            scanDocs(app:app,window:window,region:CGRect(x:x,y:y,width:w,height:h));return true
        }
        currentWord=nil
        if target.state == "target", let x=target.x, let y=target.y, let w=target.width, let h=target.height {
            point(at:cocoa(CGRect(x:x,y:y,width:w,height:h))); setStatus("Browser bridge · checking the focused editor")
        } else { goHome(); setStatus(target.state == "blocked" ? "Private / excluded field — not checked" : "Browser bridge · all clear") }
        return true
    }
    func scanDocs(app:NSRunningApplication,window:CGRect?,region:CGRect) {
        guard !visual.busy,Date().timeIntervalSince(lastScan)>1.35 else { return }
        lastScan=Date();let generation=epoch;let pid=app.processIdentifier
        visual.scan(pid:pid,windowRect:window,region:region) { [weak self] words,error in
            guard let self=self,!self.paused,!self.dragging,self.epoch==generation,NSWorkspace.shared.frontmostApplication?.processIdentifier==pid else { return }
            if let error=error { self.goHome();self.setStatus(error);return }
            if let word=(words ?? []).reversed().first(where:{self.engine.firstTypo($0.text,caret:nil) != nil}) {
                self.currentWord=word.text
                if self.visualCandidate==word.text { self.point(at:self.cocoa(word.rect));self.setStatus("Google Docs · possible typo: \(word.text)") }
                else { self.visualCandidate=word.text;self.setStatus("Google Docs · confirming spelling near the caret…") }
            } else {self.visualCandidate="";self.goHome();self.setStatus("Google Docs · all clear near the caret")}
        }
    }
    func scanVisual(app: NSRunningApplication, window: CGRect?, field: CGRect?) {
        let manual=Date()<manualUntil && lastClickPID==app.processIdentifier
        guard manual || visualApps.contains(app.bundleIdentifier ?? "") else { goHome(); setStatus("No text access here. Enable visual checking for this app, or check around the pointer."); return }
        guard CGPreflightScreenCaptureAccess() else { goHome(); setStatus("Visual checking needs Screen Recording permission."); return }
        let sinceInput=Date().timeIntervalSince(lastInput)
        guard manual || (lastInputPID==app.processIdentifier && sinceInput>1.0 && sinceInput<20) else { if sinceInput>=20 { goHome() }; return }
        guard !visual.busy, Date().timeIntervalSince(lastScan)>1.35 else { return }
        var region: CGRect
        if manual, let selected=manualRegion { region=selected }
        else if let field=field, field.width>10, field.height>10 {
            region=field
            if field.height>350, lastClickPID==app.processIdentifier, field.contains(lastClick) { region=field.intersection(CGRect(x:field.minX,y:lastClick.y-150,width:field.width,height:300)) }
        } else {
            guard lastClickPID==app.processIdentifier else { goHome(); setStatus("Click the text area, then type to start visual checking."); return }
            region=CGRect(x:lastClick.x-450,y:lastClick.y-120,width:900,height:240)
        }
        lastScan=Date(); let generation=epoch; let pid=app.processIdentifier
        visual.scan(pid:pid,windowRect:window,region:region) { [weak self] words,error in
            guard let self=self, !self.paused, !self.dragging, self.epoch==generation, NSWorkspace.shared.frontmostApplication?.processIdentifier==pid else { return }
            if let error=error { self.goHome(); self.setStatus(error); return }
            let candidates=(words ?? []).sorted { hypot($0.rect.midX-self.lastClick.x,$0.rect.midY-self.lastClick.y)<hypot($1.rect.midX-self.lastClick.x,$1.rect.midY-self.lastClick.y) }
            if let word=candidates.first(where:{ self.engine.firstTypo($0.text,caret:nil) != nil }) {
                self.currentWord=word.text
                if self.visualCandidate==word.text { self.point(at:self.cocoa(word.rect)); self.setStatus("Visual check · possible typo: \(word.text)") }
                else { self.goHome(); self.visualCandidate=word.text; self.setStatus("Visual check · confirming a possible typo…") }
            } else { self.visualCandidate=""; self.currentWord=nil; self.goHome(); self.setStatus("Visual check · all clear in the checked area") }
        }
    }
    func stable(_ text: String) -> Bool {
        if text != lastText { lastText = text; changedAt = Date(); return false }
        return Date().timeIntervalSince(changedAt) > 0.65
    }
    func attr(_ element: AXUIElement, _ key: String) -> CFTypeRef? {
        var result: CFTypeRef?; guard AXUIElementCopyAttributeValue(element, key as CFString, &result) == .success else { return nil }; return result
    }
    func scan() {
        guard !paused, !dragging else { return }
        if Date()<countdownUntil { setStatus("Point at the word · \(Int(ceil(countdownUntil.timeIntervalSinceNow)))…"); return }
        guard let app=NSWorkspace.shared.frontmostApplication else { goHome(); return }
        if app.processIdentifier != lastFrontPID {
            lastFrontPID=app.processIdentifier; epoch += 1; lastText=""; visualCandidate=""; currentWord=nil; goHome()
        }
        if NSApp.isActive, demo?.isKeyWindow == true {
            let text=editor.string
            guard stable(text) else { return }
            guard let r=typo(text,caret:editor.selectedRange().location) else { label.stringValue="All clear. Nailong is heading home."; goHome(); setStatus("Playground · all clear"); return }
            var actual=NSRange()
            let rect=editor.firstRect(forCharacterRange:r,actualRange:&actual)
            currentWord=(text as NSString).substring(with:r)
            label.stringValue="Check “\(currentWord!)” — fix it and I’ll head home."
            point(at:rect); setStatus("Playground · typo found"); return
        }
        guard app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { goHome(); return }
        let axApp=AXUIElementCreateApplication(app.processIdentifier)
        AXUIElementSetMessagingTimeout(axApp,0.12)
        var window: CGRect?
        if AXIsProcessTrusted(), let w=attr(axApp,kAXFocusedWindowAttribute), CFGetTypeID(w)==AXUIElementGetTypeID() { window=cgFrame(w as! AXUIElement) }
        // An explicit pointer check can override normal detection, except known secure fields.
        var field: CGRect?
        if AXIsProcessTrusted(), let focus=attr(axApp,kAXFocusedUIElementAttribute), CFGetTypeID(focus)==AXUIElementGetTypeID() {
            let element=focus as! AXUIElement
            let role=attr(element,kAXRoleAttribute) as? String ?? ""
            let subrole=attr(element,kAXSubroleAttribute) as? String ?? ""
            if subrole=="AXSecureTextField" || (attr(element,"AXProtectedContent") as? Bool == true) { epoch += 1; goHome(); setStatus("Secure field — not checked"); return }
            if Date()<manualUntil && lastClickPID==app.processIdentifier { scanVisual(app:app,window:window,field:cgFrame(element)); return }
            if browserTarget(app:app,window:window) { return }
            if ["AXTextField","AXTextArea","AXComboBox","AXSearchField"].contains(role) {
                field=cgFrame(element)
                if Date()>=manualUntil, let text=attr(element,kAXValueAttribute) as? String, !text.isEmpty, (text as NSString).length<=12000 {
                    guard stable(text) else { return }
                    var selection=CFRange(location:0,length:0)
                    if let v=attr(element,kAXSelectedTextRangeAttribute), CFGetTypeID(v)==AXValueGetTypeID() { AXValueGetValue(v as! AXValue,.cfRange,&selection) }
                    guard let r=typo(text,caret:selection.location) else { currentWord=nil; goHome(); setStatus("Accessibility · all clear"); return }
                    var range=CFRange(location:r.location,length:r.length)
                    let value=AXValueCreate(.cfRange,&range)!
                    var result: CFTypeRef?
                    if AXUIElementCopyParameterizedAttributeValue(element,kAXBoundsForRangeParameterizedAttribute as CFString,value,&result) == .success,
                       let result=result, CFGetTypeID(result)==AXValueGetTypeID() {
                        var rect=CGRect.zero
                        if AXValueGetValue(result as! AXValue,.cgRect,&rect), rect.width>0, rect.height>0, field?.intersects(rect) ?? true {
                            currentWord=(text as NSString).substring(with:r); point(at:cocoa(rect)); setStatus("Accessibility · checking \(app.localizedName ?? "app")"); return
                        }
                    }
                } else if let text=attr(element,kAXValueAttribute) as? String, text.isEmpty { goHome(); setStatus("Empty text field"); return }
            }
        } else {
            if Date()<manualUntil && lastClickPID==app.processIdentifier { scanVisual(app:app,window:window,field:nil); return }
            if browserTarget(app:app,window:window) { return }
        }
        scanVisual(app:app,window:window,field:field)
    }
    @objc func connectBrowser() {
        let alert=NSAlert(); alert.messageText="Connect Nailong to your browser"
        alert.informativeText="Choose your browser. Nailong will repair its local bridge and copy the extension folder path. No Terminal commands are needed."
        for choice in BrowserInstaller.choices { alert.addButton(withTitle:choice.1) }
        alert.addButton(withTitle:"Cancel")
        let index=alert.runModal().rawValue-NSApplication.ModalResponse.alertFirstButtonReturn.rawValue
        guard index>=0 && index<BrowserInstaller.choices.count else { return }
        chosenBrowser=BrowserInstaller.choices[index].0; UserDefaults.standard.set(chosenBrowser,forKey:"chosenBrowser")
        do {
            try BrowserInstaller.install(chosenBrowser)
            NSPasteboard.general.clearContents(); NSPasteboard.general.setString(Project.root.appendingPathComponent("BrowserExtension").path,forType:.string)
            BrowserInstaller.openPage(chosenBrowser)
            let done=NSAlert(); done.messageText="Bridge ready · folder path copied"
            done.informativeText="First install: turn on Developer mode, click Load unpacked, press ⇧⌘G, paste the copied folder path and select it.\n\nAlready installed? Click Reload on the Nailong extension. Then refresh your website tab.\n\nUse Test browser connection in Nailong to check every step."
            done.addButton(withTitle:"OK"); done.runModal()
        } catch { setStatus("Browser setup failed: \(error.localizedDescription)") }
    }
    @objc func testBrowser() { BrowserInstaller.openPage(chosenBrowser,test:true) }
    @objc func openExtension() { NSWorkspace.shared.open(Project.root.appendingPathComponent("BrowserExtension")) }
    @objc func openGuide() { NSWorkspace.shared.open(Project.root.appendingPathComponent("START-HERE.html")) }
    @objc func showSetup() {
        if setup == nil {
            let window=NSWindow(contentRect:NSRect(x:0,y:0,width:610,height:490),styleMask:[.titled,.closable,.miniaturizable],backing:.buffered,defer:false)
            window.title="Nailong · Setup & coverage"; window.isReleasedWhenClosed=false; window.center()
            let view=window.contentView!
            func label(_ text:String,_ y:CGFloat,_ h:CGFloat,_ size:CGFloat) -> NSTextField {
                let field=NSTextField(wrappingLabelWithString:text); field.font = .systemFont(ofSize:size); field.frame=NSRect(x:28,y:y,width:550,height:h); view.addSubview(field); return field
            }
            _ = label("Your little proofreader, across your Mac.",432,38,23)
            _ = label("1. Accessibility supports native text fields.\n2. The browser extension supports website editors.\n3. Optional visual checks cover more apps using local OCR.",346,72,14)
            setupStatus=label("",242,90,13)
            let actions:[(String,Selector,CGFloat,CGFloat)] = [
                ("Enable Accessibility…",#selector(permission),28,195),
                ("Enable Screen Recording…",#selector(screenPermission),300,195),
                ("Connect / repair browser…",#selector(connectBrowser),28,150),
                ("Open setup guide",#selector(openGuide),300,150),
                ("Try the playground",#selector(showDemo),28,105),
                ("Test browser connection",#selector(testBrowser),300,105)]
            for (title,action,x,y) in actions { let b=NSButton(title:title,target:self,action:action); b.frame=NSRect(x:x,y:y,width:265,height:34); view.addSubview(b) }
            _ = label("For visual checks: switch to an app, then choose “Toggle visual checking for current app” from the yellow menu-bar icon. Screenshots stay in memory. Password fields are skipped when identifiable.",20,70,12)
            setup=window
        }
        setStatus(stateText); NSApp.activate(ignoringOtherApps:true); setup?.makeKeyAndOrderFront(nil)
    }
    @objc func showDemo() {
        if demo == nil {
            demo = NSWindow(contentRect:NSRect(x:0,y:0,width:650,height:430),styleMask:[.titled,.closable,.miniaturizable],backing:.buffered,defer:false)
            demo.title = "Nailong · Typing playground"; demo.isReleasedWhenClosed = false; demo.center()
            let content = demo.contentView!
            let heading = NSTextField(labelWithString:"A little friend. An extra pair of eyes.")
            heading.font = .systemFont(ofSize:25,weight:.semibold); heading.frame = NSRect(x:28,y:365,width:600,height:35); content.addSubview(heading)
            let help = NSTextField(wrappingLabelWithString:"Drag Nailong to choose his home. Type a misspelled word followed by a space, then correct it. Right-click him for controls.")
            help.textColor = .secondaryLabelColor; help.frame = NSRect(x:28,y:305,width:590,height:48); content.addSubview(help)
            let scroll = NSScrollView(frame:NSRect(x:28,y:100,width:594,height:190)); scroll.hasVerticalScroller = true; scroll.borderType = .bezelBorder
            editor = NSTextView(frame:scroll.bounds); editor.font = .systemFont(ofSize:22); editor.textContainerInset = NSSize(width:16,height:18)
            editor.isRichText = false; editor.isAutomaticSpellingCorrectionEnabled = false; editor.isContinuousSpellCheckingEnabled = true
            editor.autoresizingMask = [.width]; editor.isVerticallyResizable = true
            editor.textContainer?.widthTracksTextView = true
            editor.string = "Hello, little friend. This is a beautifull day. "
            editor.setSelectedRange(NSRange(location:(editor.string as NSString).length,length:0))
            scroll.documentView = editor; content.addSubview(scroll)
            label = NSTextField(labelWithString:"English spell checking • local processing • no text saved")
            label.font = .systemFont(ofSize:12); label.textColor = .secondaryLabelColor; label.frame = NSRect(x:28,y:66,width:594,height:22); content.addSubview(label)
            let button = NSButton(title:"Enable in other apps…",target:self,action:#selector(permission)); button.frame = NSRect(x:26,y:20,width:200,height:32); content.addSubview(button)
        }
        NSApp.activate(ignoringOtherApps:true); demo.makeKeyAndOrderFront(nil); demo.makeFirstResponder(editor)
    }
}

if CommandLine.arguments.contains("--install-browser") {
    _ = NSApplication.shared
    do { try BrowserInstaller.install(CommandLine.arguments.last ?? "chrome"); print("Browser bridge ready.") }
    catch { fputs("Browser setup failed: \(error)\n",stderr); exit(1) }
} else if CommandLine.arguments.contains("--native-host") || URL(fileURLWithPath:CommandLine.arguments[0]).lastPathComponent.hasPrefix("NailongBridge-") {
    NativeBridge().run()
} else if CommandLine.arguments.contains("--capture-test") {
    runCaptureCheck()
} else if CommandLine.arguments.contains("--self-test") {
    runSelfTests()
} else {
    let app = NSApplication.shared
    let delegate = Controller(); app.delegate = delegate; app.run()
}
