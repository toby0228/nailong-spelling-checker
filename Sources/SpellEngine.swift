import AppKit

final class SpellEngine {
    let tag = NSSpellChecker.uniqueSpellDocumentTag()
    var language: String? = "en_US"
    var ignored = Set<String>()
    func firstTypo(_ text: String, caret: Int?, limit: Int = 12000) -> NSRange? {
        let ns = text as NSString
        guard ns.length > 0, ns.length <= limit else { return nil }
        let words = try! NSRegularExpression(pattern: "(?<![\\p{L}\\p{N}_])[\\p{L}]+(?:['’][\\p{L}]+)?(?![\\p{L}\\p{N}_])")
        var matches = words.matches(in:text,range:NSRange(location:0,length:ns.length))
        if let caret = caret { matches.sort { abs(NSMaxRange($0.range)-caret) < abs(NSMaxRange($1.range)-caret) } }
        for match in matches {
            let r = match.range, word = ns.substring(with:r)
            if let caret = caret, caret > r.location && caret <= NSMaxRange(r) { continue }
            if r.length < 3 || ignored.contains(word.lowercased()) { continue }
            // Skip URLs, email fragments, snake_case and camelCase/code identifiers.
            let token = ns.substring(with:NSRange(location:max(0,r.location-1),length:min(ns.length,NSMaxRange(r)+1)-max(0,r.location-1)))
            if token.contains("_") || token.contains("@") || token.contains("/") { continue }
            if word.range(of:"[a-z][A-Z]",options:.regularExpression) != nil || word == word.uppercased() { continue }
            let result = NSSpellChecker.shared.checkSpelling(of:word,startingAt:0,language:language,wrap:false,inSpellDocumentWithTag:tag,wordCount:nil)
            if result.location != NSNotFound { return r }
        }
        return nil
    }
}

struct BrowserTarget: Codable {
    var time: Double
    var browser: String
    var state: String
    var x: Double?
    var y: Double?
    var width: Double?
    var height: Double?
    var windowX: Double?
    var windowY: Double?
    var windowWidth: Double?
    var windowHeight: Double?
    func valid(now: Double = Date().timeIntervalSince1970) -> Bool {
        guard abs(now-time) < 2.5, ["clear","target","blocked","idle","visual","docs-unavailable"].contains(state), ["chrome","edge","brave","chromium"].contains(browser) else { return false }
        if state != "target" && state != "visual" { return true }
        guard let x=x, let y=y, let w=width, let h=height,
              let wx=windowX, let wy=windowY, let ww=windowWidth, let wh=windowHeight else { return false }
        return [x,y,w,h,wx,wy,ww,wh].allSatisfy { $0.isFinite } && w>0 && w<4000 && h>0 && h<1000 && ww>0 && wh>0 && abs(x)<50000 && abs(y)<50000
    }
}

enum Project {
    static var support: URL { FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/Nailong") }
    static var root: URL {
        if URL(fileURLWithPath:CommandLine.arguments[0]).lastPathComponent.hasPrefix("NailongBridge-"),
           let data=try? Data(contentsOf:support.appendingPathComponent("installation.json")),
           let record=(try? JSONSerialization.jsonObject(with:data)) as? [String:String],let path=record["projectRoot"] { return URL(fileURLWithPath:path) }
        // build/Nailong.app/Contents/MacOS/Nailong → project folder
        return URL(fileURLWithPath:CommandLine.arguments[0]).standardizedFileURL.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
    }
    static var runtime: URL {
        if let test=ProcessInfo.processInfo.environment["NAILONG_TEST_RUNTIME"] { return URL(fileURLWithPath:test) }
        return support.appendingPathComponent("runtime")
    }
    static func write<T: Encodable>(_ value: T, name: String) {
        try? FileManager.default.createDirectory(at:runtime,withIntermediateDirectories:true,attributes:[.posixPermissions:0o700])
        guard let data = try? JSONEncoder().encode(value) else { return }
        let url = runtime.appendingPathComponent(name)
        try? data.write(to:url,options:.atomic)
        try? FileManager.default.setAttributes([.posixPermissions:0o600],ofItemAtPath:url.path)
    }
    static func read<T: Decodable>(_ type: T.Type, name: String) -> T? {
        guard let data = try? Data(contentsOf:runtime.appendingPathComponent(name)), data.count < 65536 else { return nil }
        return try? JSONDecoder().decode(type,from:data)
    }
}
struct BridgeSettings: Codable { let enabled: Bool; let time: Double; let ignored: [String] }

struct BridgeConnection: Codable { let time: Double; let version: String }
