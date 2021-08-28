import Foundation
import Darwin

private var alternate = false
private var _pipe: Pipe = Pipe()
private var pipe_: Pipe = Pipe()

var currentPipe: Pipe { alternate ? _pipe : pipe_ }
var previousPipe: Pipe { get { alternate ? pipe_ : _pipe } set { if alternate { pipe_ = newValue } else { _pipe = newValue } } }

enum Pipekind {
    case first
    case middle
    case last
    case none
}

func eof() {
    print("exit")
    exit(0)
}

func prompt() {
    print("minishell$", terminator: " ")
}

var environment: [String: String] {
    ProcessInfo.processInfo.environment
}

func connectPipe(of kind: Pipekind, with process: Process) {
    switch kind {
        case .first:
            process.standardOutput = currentPipe.fileHandleForWriting
        case .middle:
            process.standardInput = previousPipe.fileHandleForReading
            process.standardOutput = currentPipe.fileHandleForWriting
        case .last: 
            process.standardInput = previousPipe.fileHandleForReading
        default: break
    }
}

func closePipe(of kind: Pipekind) {
    switch kind {
        case .first:
            try! currentPipe.fileHandleForWriting.close()
        case .middle:
            try! previousPipe.fileHandleForReading.close()
            previousPipe = Pipe()
            try! currentPipe.fileHandleForWriting.close()
        case .last: 
            try! previousPipe.fileHandleForReading.close()
            previousPipe = Pipe()
        default: break
    }
}

func execute(_ command: [String], pipe kind: Pipekind = .none) {
    let process = Process()
    var launchPath = ""

    process.arguments = Array(command.dropFirst())
    let subpaths = ["."] + (environment["PATH"] ?? "").components(separatedBy: ":")
    connectPipe(of: kind, with: process)
    for subpath in subpaths {
        launchPath = subpath + "/" + command[0]
        let executableURL = URL(fileURLWithPath: launchPath)
        process.executableURL = executableURL
        do {
            try process.run()
            process.waitUntilExit()
            closePipe(of: kind)
            alternate.toggle()
            return
        } catch { continue }
    }
    exit(-1)
}

extension Array where Element == String {
    func separate(by separator: String) -> [[Element]] {
        var chunks: [[Element]] = []
        var elements: [Element] = []

        for element in self {
            if element != separator {
                elements.append(element)
            } else {
                chunks.append(elements)
                elements = []
            }
        }
        chunks.append(elements)
        return chunks
    }
}

func run(_ commands: [[String]]) {
    let count = commands.count

    if count == 1 {
        execute(commands[0])
    } else {
        for i in 0..<count {
            switch i {
                case 0: execute(commands[i], pipe: .first)
                case count-1: execute(commands[i], pipe: .last)
                default: execute(commands[i], pipe: .middle)
            }
        }
    }
}

func main() {
    while true {
        prompt()
        guard let line = readLine() else { return eof() }
        let arguments = line.components(separatedBy: " ").filter { $0 != "" } 
        let commands = arguments.separate(by: "|")
        run(commands)
    }
}

main()
