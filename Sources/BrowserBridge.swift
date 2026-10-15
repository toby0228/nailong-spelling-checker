import AppKit

// Chrome launches this mode over private stdin/stdout pipes, never an HTTP port.
final class NativeBridge {
    let engine = SpellEngine()
    func readExactly(_ count: Int) -> Data? {
        var data = Data()
        while data.count < count {
            guard let part = try? FileHandle.standardInput.read(upToCount:count-data.count), !part.isEmpty else { return nil }
            data.append(part)
        }
        return data
    }
    func run() {
        while let header = readExactly(4) {
            let length = header.enumerated().reduce(UInt32(0)) { $0 | UInt32($1.element) << ($1.offset*8) }
            guard length > 0, length < 128*1024, let data = readExactly(Int(length)) else { return }
            var response: [String:Any]
            if let message = (try? JSONSerialization.jsonObject(with:data)) as? [String:Any] { response = handle(message); response["id"] = message["id"] }
            else { response = ["ok":false,"error":"Invalid message"] }
            guard let output = try? JSONSerialization.data(withJSONObject:response) else { return }
            var count = UInt32(output.count).littleEndian
            do {
                try FileHandle.standardOutput.write(contentsOf:Data(bytes:&count,count:4))
                try FileHandle.standardOutput.write(contentsOf:output)
            } catch { return }
        }
    }
    func handle(_ message: [String:Any]) -> [String:Any] {
        if message["type"] as? String == "ping" {
            let settings=Project.read(BridgeSettings.self,name:"settings.json")
            let running=settings.map { Date().timeIntervalSince1970-$0.time<5 } ?? false
            return ["ok":true,"version":"0.3.0","running":running,"enabled":running && (settings?.enabled ?? false)]
        }
        if message["type"] as? String == "launch" {
            NSWorkspace.shared.open(Project.root.appendingPathComponent("build/Nailong.app"))
            return ["ok":true]
        }
        guard let settings = Project.read(BridgeSettings.self,name:"settings.json"), Date().timeIntervalSince1970-settings.time < 5, settings.enabled else {
            return ["ok":false,"error":"Open Nailong and resume detection."]
        }
        Project.write(BridgeConnection(time:Date().timeIntervalSince1970,version:"0.3.0"),name:"bridge-status.json")
        engine.ignored = Set(settings.ignored)
        switch message["type"] as? String {
        case "check":
            guard let text = message["text"] as? String, (text as NSString).length <= 12000, let caret = message["caret"] as? Int, caret >= 0, caret <= (text as NSString).length else { return ["ok":false,"error":"Invalid text range"] }
            if let r = engine.firstTypo(text,caret:caret) { return ["ok":true,"range":["location":r.location,"length":r.length]] }
            return ["ok":true,"range":NSNull()]
        case "target":
            guard let raw = message["target"], let data = try? JSONSerialization.data(withJSONObject:raw), var target = try? JSONDecoder().decode(BrowserTarget.self,from:data) else { return ["ok":false] }
            if let argument=CommandLine.arguments.first(where:{ $0.hasPrefix("--browser=") }) {
                target.browser=String(argument.dropFirst("--browser=".count))
            }
            let helperName=URL(fileURLWithPath:CommandLine.arguments[0]).lastPathComponent
            if helperName.hasPrefix("NailongBridge-") { target.browser=String(helperName.dropFirst("NailongBridge-".count)) }
            target.time = Date().timeIntervalSince1970
            guard target.valid() else { return ["ok":false] }
            Project.write(target,name:"browser-target.json")
            return ["ok":true]
        case "ping": return ["ok":true]
        default: return ["ok":false,"error":"Unknown request"]
        }
    }
}
