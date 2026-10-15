import AppKit

struct BrowserInstaller {
    static let choices:[(String,String,String)] = [
        ("chrome","Google Chrome","Google/Chrome"),("edge","Microsoft Edge","Microsoft Edge"),
        ("brave","Brave Browser","BraveSoftware/Brave-Browser"),("chromium","Chromium","Chromium")]
    static func install(_ kind:String) throws {
        guard let browser=choices.first(where:{$0.0==kind}) else { return }
        let root=Project.root
        let id=try String(contentsOf:root.appendingPathComponent("BrowserExtension/extension-id.txt"),encoding:.utf8).trimmingCharacters(in:.whitespacesAndNewlines)
        let helperDirectory=Project.support.appendingPathComponent("NativeHosts")
        try FileManager.default.createDirectory(at:helperDirectory,withIntermediateDirectories:true)
        let helper=helperDirectory.appendingPathComponent("NailongBridge-\(kind)")
        let binary=try Data(contentsOf:root.appendingPathComponent("build/Nailong.app/Contents/MacOS/Nailong"))
        try binary.write(to:helper,options:.atomic)
        try FileManager.default.setAttributes([.posixPermissions:0o700],ofItemAtPath:helper.path)
        try JSONSerialization.data(withJSONObject:["projectRoot":root.path]).write(to:Project.support.appendingPathComponent("installation.json"),options:.atomic)
        let directory=FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support/\(browser.2)/NativeMessagingHosts")
        try FileManager.default.createDirectory(at:directory,withIntermediateDirectories:true)
        let manifest:[String:Any] = ["name":"local.nailong.bridge","description":"Nailong local spelling bridge","path":helper.path,"type":"stdio","allowed_origins":["chrome-extension://\(id)/"]]
        try JSONSerialization.data(withJSONObject:manifest,options:.prettyPrinted).write(to:directory.appendingPathComponent("local.nailong.bridge.json"),options:.atomic)
    }
    static func openPage(_ kind:String, test:Bool=false) {
        guard let browser=choices.first(where:{$0.0==kind}) else { return }
        let app=URL(fileURLWithPath:"/Applications/\(browser.1).app")
        let scheme=kind=="edge" ? "edge" : (kind=="brave" ? "brave" : "chrome")
        let id=(try? String(contentsOf:Project.root.appendingPathComponent("BrowserExtension/extension-id.txt"),encoding:.utf8))?.trimmingCharacters(in:.whitespacesAndNewlines) ?? ""
        let url=URL(string:test ? "chrome-extension://\(id)/test.html" : "\(scheme)://extensions")!
        NSWorkspace.shared.open([url],withApplicationAt:app,configuration:NSWorkspace.OpenConfiguration(),completionHandler:nil)
    }
}
