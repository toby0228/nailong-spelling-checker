import AppKit

struct PointingPlacement {
    let origin: CGPoint
    let facesLeft: Bool
    static let fingerY: CGFloat = 124
    static func calculate(word: CGRect, screen: CGRect) -> PointingPlacement {
        let roomLeft=word.minX-screen.minX, roomRight=screen.maxX-word.maxX
        let leftSide=roomLeft>=155 || roomLeft>=roomRight
        let rawX=leftSide ? word.minX-155 : word.maxX+5
        let x=max(screen.minX,min(rawX,screen.maxX-150))
        let y=max(screen.minY,min(word.midY-fingerY,screen.maxY-190))
        return PointingPlacement(origin:CGPoint(x:x,y:y),facesLeft:x+75>word.midX)
    }
    var fingertip: CGPoint { CGPoint(x:origin.x+(facesLeft ? 13 : 137),y:origin.y+Self.fingerY) }
}
final class TargetOverlayView: NSView {
    var word=CGRect.zero
    var finger=CGPoint.zero
    var showLine=false
    var scanBox: CGRect?
    override func draw(_ dirtyRect: NSRect) {
        if let box=scanBox {
            NSColor.systemYellow.withAlphaComponent(0.8).setStroke()
            let path=NSBezierPath(roundedRect:box,xRadius:8,yRadius:8);path.lineWidth=2
            path.setLineDash([6,4],count:2,phase:0);path.stroke();return
        }
        guard word.width>0 else { return }
        NSColor.systemOrange.withAlphaComponent(0.12).setFill()
        let outline=NSBezierPath(roundedRect:word.insetBy(dx:-3,dy:-3),xRadius:4,yRadius:4)
        outline.fill();NSColor.systemOrange.setStroke();outline.lineWidth=2;outline.stroke()
        guard showLine else { return }
        let end=CGPoint(x:finger.x<word.midX ? word.minX-5 : word.maxX+5,y:word.midY)
        let dx=end.x-finger.x,dy=end.y-finger.y,dist=hypot(dx,dy)
        guard dist>4 else { return }
        let line=NSBezierPath();line.move(to:finger);line.line(to:end);line.lineWidth=2;line.stroke()
        let u=CGPoint(x:dx/dist,y:dy/dist)
        let arrow=NSBezierPath();arrow.move(to:CGPoint(x:end.x-u.x*7-u.y*4,y:end.y-u.y*7+u.x*4));arrow.line(to:end);arrow.line(to:CGPoint(x:end.x-u.x*7+u.y*4,y:end.y-u.y*7-u.x*4));arrow.stroke()
    }
}
final class TargetOverlay {
    let panel: PetPanel
    let view: TargetOverlayView
    init() {
        panel=PetPanel(contentRect:.zero,styleMask:[.borderless,.nonactivatingPanel],backing:.buffered,defer:false)
        panel.isOpaque=false;panel.backgroundColor = .clear;panel.hasShadow=false;panel.ignoresMouseEvents=true
        panel.level = .floating;panel.hidesOnDeactivate=false;panel.collectionBehavior=[.canJoinAllSpaces,.fullScreenAuxiliary]
        view=TargetOverlayView(frame:.zero);panel.contentView=view
    }
    func show(word:CGRect,finger:CGPoint,line:Bool,screen:CGRect) {
        panel.setFrame(screen,display:false);view.frame=CGRect(origin:.zero,size:screen.size)
        view.word=word.offsetBy(dx:-screen.minX,dy:-screen.minY)
        view.finger=CGPoint(x:finger.x-screen.minX,y:finger.y-screen.minY)
        view.showLine=line;view.scanBox=nil;view.needsDisplay=true;panel.orderFrontRegardless()
    }
    func showScan(_ rect:CGRect,screen:CGRect) {
        panel.setFrame(screen,display:false);view.frame=CGRect(origin:.zero,size:screen.size)
        view.scanBox=rect.offsetBy(dx:-screen.minX,dy:-screen.minY);view.needsDisplay=true;panel.orderFrontRegardless()
    }
    func hide() { panel.orderOut(nil) }
}
