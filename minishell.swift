import Foundation
import Darwin

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

func execute(_ arguments: [String]) {
    let process = Process()
    var launchPath = ""

    process.arguments = Array(arguments.dropFirst())
    let subpaths = ["."] + (environment["PATH"]?.components(separatedBy: ":") ?? [])
    for subpath in subpaths {
        launchPath = subpath + "/" + arguments[0]
        let executableURL = URL(fileURLWithPath: launchPath)
        process.executableURL = executableURL
        do { 
            try process.run()
            process.waitUntilExit()
            return
        } catch { continue }
    }
}

func main() {
    while true {
        prompt()
        guard let line = readLine() else { return eof() }
        let arguments = line.components(separatedBy: " ").filter { $0 != "" } 
        execute(arguments)
    }
}

main()
