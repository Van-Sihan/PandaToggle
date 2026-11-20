import Cocoa

// 판다 VPN(com.panda.fastconnect) 상태를 메뉴 막대에 표시하고 클릭으로 켜고 끈다.
let vpnType = "com.panda.fastconnect"

@discardableResult
func scutil(_ args: [String]) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
    p.arguments = ["--nc"] + args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = pipe
    do { try p.run() } catch { return "" }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    return String(data: data, encoding: .utf8) ?? ""
}

struct VPN {
    let id: String
    let name: String
    let status: String // Connected, Disconnected, Connecting, Disconnecting ...
}

func findVPN() -> VPN? {
    for line in scutil(["list"]).split(separator: "\n") where line.contains("[VPN:\(vpnType)]") {
        let parts = line.split(separator: " ", omittingEmptySubsequences: true)
        guard let id = parts.first(where: { $0.count == 36 && $0.filter({ $0 == "-" }).count == 4 }) else { continue }
        var name = ""
        if let a = line.firstIndex(of: "\""), let b = line.lastIndex(of: "\""), a < b {
            name = String(line[line.index(after: a)..<b])
        }
        let status = scutil(["status", String(id)]).split(separator: "\n").first.map(String.init) ?? "Unknown"
        return VPN(id: String(id), name: name, status: status.trimmingCharacters(in: .whitespaces))
    }
    return nil
}


// 메뉴 막대용 판다 얼굴 아이콘 (18x18pt). color 한 가지로 그린다.
func pandaImage(color: NSColor) -> NSImage {
    let img = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
        guard let ctx = NSGraphicsContext.current else { return false }
        color.set()
        // 귀
        NSBezierPath(ovalIn: NSRect(x: 0.8, y: 11.2, width: 6, height: 6)).fill()
        NSBezierPath(ovalIn: NSRect(x: 11.2, y: 11.2, width: 6, height: 6)).fill()
        // 얼굴 안쪽에 겹친 귀 부분을 지운다
        let head = NSBezierPath(ovalIn: NSRect(x: 2, y: 1, width: 14, height: 14))
        ctx.compositingOperation = .clear
        head.fill()
        ctx.compositingOperation = .sourceOver
        color.set()
        let outline = NSBezierPath(ovalIn: NSRect(x: 2.7, y: 1.7, width: 12.6, height: 12.6))
        outline.lineWidth = 1.4
        outline.stroke()
        // 눈 주변 검은 무늬 (비스듬한 타원)
        for (cx, angle) in [(6.4, -35.0), (11.6, 35.0)] {
            let t = NSAffineTransform()
            t.translateX(by: cx, yBy: 8.6)
            t.rotate(byDegrees: angle)
            let p = NSBezierPath(ovalIn: NSRect(x: -1.6, y: -2.3, width: 3.2, height: 4.6))
            p.transform(using: t as AffineTransform)
            p.fill()
        }
        // 코
        NSBezierPath(ovalIn: NSRect(x: 7.8, y: 4.4, width: 2.4, height: 1.7)).fill()
        return true
    }
    return img
}

class AppDelegate: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var vpn: VPN?
    var timer: Timer?

    func applicationDidFinishLaunching(_ n: Notification) {
        item.button?.target = self
        item.button?.action = #selector(clicked)
        item.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        refresh()
        timer = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in self?.refresh() }
    }

    func refresh() {
        DispatchQueue.global().async {
            let v = findVPN()
            DispatchQueue.main.async { self.vpn = v; self.draw() }
        }
    }

    func draw() {
        guard let button = item.button else { return }
        let status = vpn?.status ?? "None"
        let on = status == "Connected"
        let busy = status == "Connecting" || status == "Disconnecting"
        let color: NSColor = on ? .systemGreen : (busy ? .systemOrange : .secondaryLabelColor)
        button.image = pandaImage(color: color)
        button.imagePosition = .imageLeading
        let text = vpn == nil ? " 없음" : (busy ? " …" : (on ? " ON" : " OFF"))
        button.attributedTitle = NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .semibold),
            .foregroundColor: on ? NSColor.systemGreen : NSColor.labelColor,
        ])
        button.toolTip = vpn.map { "판다 VPN: \($0.name) (\($0.status))" } ?? "판다 VPN 설정을 찾지 못했습니다"
    }

    @objc func clicked() {
        if NSApp.currentEvent?.type == .rightMouseUp { showMenu() } else { toggle() }
    }

    @objc func toggle() {
        guard let v = vpn else { return }
        let on = v.status == "Connected" || v.status == "Connecting"
        vpn = VPN(id: v.id, name: v.name, status: on ? "Disconnecting" : "Connecting")
        draw()
        DispatchQueue.global().async {
            scutil([on ? "stop" : "start", v.id])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { self.refresh() }
        }
    }

    func showMenu() {
        let menu = NSMenu()
        let on = vpn?.status == "Connected"
        let head = NSMenuItem(title: vpn.map { "\($0.name) · \(on ? "연결됨" : $0.status)" } ?? "판다 VPN 없음", action: nil, keyEquivalent: "")
        head.isEnabled = false
        menu.addItem(head)
        menu.addItem(.separator())
        menu.addItem(withTitle: on ? "VPN 끄기" : "VPN 켜기", action: #selector(toggle), keyEquivalent: "").target = self
        menu.addItem(withTitle: "판다 VPN 앱 열기", action: #selector(openPanda), keyEquivalent: "").target = self
        menu.addItem(.separator())
        menu.addItem(withTitle: "종료", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        item.button?.performClick(nil)
        item.menu = nil
    }

    @objc func openPanda() {
        NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications/판다VPN-Fast Connect.app"))
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
