/*
 * TRBBFI - The Really Better Brainfuck Interpreter
 * Author: TheRealOwenJ
 * Repository: https://github.com/TheRealOwenJ/trbbfi
 *
 * Licensed under GNU GPL v3 to prevent theft.
 * See LICENSE file for details.
 */

#include <iostream>
#include <fstream>
#include <vector>
#include <stack>
#include <string>
#include <sstream>
#include <algorithm>
#include <cstring>
#include <getopt.h>

#define TRBBFI_VERSION "1.0"
#define TRBBFI_BUILD_DATE __DATE__

class BrainfuckInterpreter {
private:
    std::vector<unsigned char> memory;
    std::vector<char> code;
    size_t memptr;
    size_t codeptr;
    std::stack<size_t> loop_stack;
    bool debug_mode;

public:
    BrainfuckInterpreter() : memory(30000, 0), memptr(0), codeptr(0), debug_mode(false) {}

    void setDebug(bool debug) { debug_mode = debug; }

    void loadCode(const std::string& program) {
        code.clear();
        for (char c : program) {
            if (c == '>' || c == '<' || c == '+' || c == '-' ||
                c == '.' || c == ',' || c == '[' || c == ']') {
                code.push_back(c);
            }
        }
    }

    bool validateBrackets() {
        int balance = 0;
        for (char c : code) {
            if (c == '[') balance++;
            if (c == ']') balance--;
            if (balance < 0) return false;
        }
        return balance == 0;
    }

    void reset() {
        std::fill(memory.begin(), memory.end(), 0);
        memptr = 0;
        codeptr = 0;
        while (!loop_stack.empty()) loop_stack.pop();
    }

    bool execute() {
        if (!validateBrackets()) {
            std::cerr << "Error: Unmatched brackets\n";
            return false;
        }

        codeptr = 0;
        memptr = 0;
        while (!loop_stack.empty()) loop_stack.pop();
        std::fill(memory.begin(), memory.end(), 0);

        while (codeptr < code.size()) {
            if (debug_mode) {
                std::cerr << "[DEBUG] Step " << codeptr << ": '" << code[codeptr]
                          << "' ptr=" << memptr << " val=" << (int)memory[memptr] << std::endl;
            }

            switch (code[codeptr]) {
                case '>':
                    memptr++;
                    if (memptr >= memory.size()) {
                        if (memory.size() >= 1000000) {
                            std::cout << "\nError: Memory limit exceeded (1MB)\n";
                            return false;
                        }
                        memory.resize(std::min(memory.size() * 2, size_t(1000000)), 0);
                    }
                    break;
                case '<':
                    if (memptr > 0) memptr--;
                    break;
                case '+':
                    memory[memptr]++;
                    break;
                case '-':
                    memory[memptr]--;
                    break;
                case '.':
                    std::cout << (char)memory[memptr];
                    std::cout.flush();
                    break;
                case ',':
                {
                    int input = std::cin.get();
                    if (std::cin.fail()) {
                        std::cin.clear();
                        memory[memptr] = 0;
                    } else {
                        memory[memptr] = (input == EOF) ? 0 : (unsigned char)input;
                    }
                    break;
                }
                case '[':
                    if (memory[memptr] == 0) {
                        int balance = 1;
                        size_t pos = codeptr + 1;
                        while (pos < code.size() && balance > 0) {
                            if (code[pos] == '[') balance++;
                            if (code[pos] == ']') balance--;
                            pos++;
                        }
                        if (balance > 0) {
                            std::cout << "\nError: Unmatched '[' at position " << codeptr << "\n";
                            return false;
                        }
                        codeptr = pos - 1;
                    } else {
                        loop_stack.push(codeptr);
                    }
                    break;
                case ']':
                    if (loop_stack.empty()) {
                        std::cout << "\nError: Unmatched ']' at position " << codeptr << "\n";
                        return false;
                    }
                    if (memory[memptr] != 0) {
                        codeptr = loop_stack.top();
                    } else {
                        loop_stack.pop();
                    }
                    break;
            }
            codeptr++;
        }
        return true;
    }

    void dumpMemory(size_t start = 0, size_t count = 16) {
        if (start >= memory.size()) {
            std::cout << "Error: Start position " << start << " exceeds memory size " << memory.size() << "\n";
            return;
        }
        size_t end = std::min(start + count, memory.size());
        std::cout << "Memory [" << start << "-" << (end - 1) << "]: ";
        for (size_t i = start; i < end; i++) {
            if (i == memptr) std::cout << "[" << (int)memory[i] << "] ";
            else std::cout << (int)memory[i] << " ";
        }
        std::cout << "\n";
    }

    size_t getCodeSize() const { return code.size(); }
    size_t getMemoryPointer() const { return memptr; }
};

class Shell {
private:
    BrainfuckInterpreter interpreter;
    std::string current_program;
    bool debug_mode;

public:
    Shell() : debug_mode(false) {}

    void printBanner() {
        std::cout << "TRBBFI v" << TRBBFI_VERSION << " - The Really Better Brainfuck Interpreter\n";
        std::cout << "Built by TheRealOwenJ - Licensed under GNU GPL v3\n";
        std::cout << "Type 'help' for commands\n\n";
    }

    void printHelp() {
        std::cout << "TRBBFI - Brainfuck Interpreter Commands:\n";
        std::cout << "  load <file.bf>     - Load brainfuck program from file\n";
        std::cout << "  code <program>     - Load brainfuck program from command line\n";
        std::cout << "  run (or r)         - Execute loaded brainfuck program\n";
        std::cout << "  reset              - Reset interpreter state (clear memory)\n";
        std::cout << "  dump [start] [cnt] - Show memory contents\n";
        std::cout << "  debug [on|off]     - Toggle debug mode (shows step-by-step)\n";
        std::cout << "  show (or s)        - Show loaded brainfuck program\n";
        std::cout << "  clear (or c)       - Clear loaded program\n";
        std::cout << "  status             - Show interpreter status\n";
        std::cout << "  help (or h)        - Show this help\n";
        std::cout << "  exit/quit/q        - Exit TRBBFI\n";
        std::cout << "\nTips:\n";
        std::cout << "  - Debug output goes to stderr\n";
        std::cout << "  - Files must contain valid Brainfuck code (+-<>[].,)\n";
        std::cout << "  - Memory is limited to 1MB\n";
    }

    std::vector<std::string> tokenize(const std::string& line) {
        std::vector<std::string> tokens;
        std::stringstream ss(line);
        std::string token;
        while (ss >> token) tokens.push_back(token);
        return tokens;
    }

    void run() {
        printBanner();
        std::string line;

        while (true) {
            std::cout << "trbbfi> ";
            if (!std::getline(std::cin, line)) {
                std::cout << "\nBye!\n";
                break;
            }

            line.erase(0, line.find_first_not_of(" \t"));
            line.erase(line.find_last_not_of(" \t") + 1);

            if (line.empty()) continue;
            if (line == "exit" || line == "quit" || line == "q") break;

            auto tokens = tokenize(line);
            if (tokens.empty()) continue;

            std::string cmd = tokens[0];

            try {
                if (cmd == "help" || cmd == "h") printHelp();
                else if (cmd == "load") {
                    if (tokens.size() < 2) { std::cout << "Usage: load <file.bf>\n"; continue; }
                    std::string filename = tokens[1];
                    if (filename.find("..") != std::string::npos) { std::cout << "Error: Invalid filename\n"; continue; }
                    std::ifstream file(filename, std::ios::binary);
                    if (!file) { std::cout << "Error: Cannot open file\n"; continue; }
                    file.seekg(0, std::ios::end);
                    size_t filesize = file.tellg();
                    if (filesize > 1000000) { std::cout << "Error: File too large\n"; continue; }
                    file.seekg(0, std::ios::beg);
                    std::string program((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
                    interpreter.loadCode(program);
                    current_program = program;
                    std::cout << "Loaded " << interpreter.getCodeSize() << " instructions from " << filename << "\n";
                } else if (cmd == "code") {
                    if (tokens.size() < 2) { std::cout << "Usage: code <program>\n"; continue; }
                    std::string program;
                    for (size_t i = 1; i < tokens.size(); i++) { program += tokens[i]; if (i < tokens.size() - 1) program += " "; }
                    if (program.length() > 10000) { std::cout << "Error: Program too long\n"; continue; }
                    interpreter.loadCode(program);
                    current_program = program;
                    std::cout << "Loaded " << interpreter.getCodeSize() << " instructions\n";
                } else if (cmd == "run" || cmd == "r") {
                    if (current_program.empty()) std::cout << "No program loaded.\n";
                    else if (!interpreter.execute()) std::cout << "Program failed.\n";
                } else if (cmd == "reset") { interpreter.reset(); std::cout << "Interpreter reset\n"; }
                else if (cmd == "dump") {
                    size_t start = 0, count = 16;
                    if (tokens.size() > 1) start = std::stoul(tokens[1]);
                    if (tokens.size() > 2) count = std::stoul(tokens[2]);
                    interpreter.dumpMemory(start, count);
                } else if (cmd == "debug" || cmd == "d") {
                    if (tokens.size() > 1) {
                        std::string arg = tokens[1]; std::transform(arg.begin(), arg.end(), arg.begin(), ::tolower);
                        if (arg == "on") { interpreter.setDebug(true); debug_mode = true; std::cout << "Debug mode on\n"; }
                        else if (arg == "off") { interpreter.setDebug(false); debug_mode = false; std::cout << "Debug mode off\n"; }
                        else std::cout << "Usage: debug [on|off]\n";
                    } else std::cout << "Usage: debug [on|off]\n";
                } else if (cmd == "show" || cmd == "s") {
                    if (current_program.empty()) std::cout << "No program loaded\n";
                    else std::cout << "Program (" << interpreter.getCodeSize() << " instructions): "
                                   << current_program.substr(0, std::min(size_t(200), current_program.size())) << "\n";
                } else if (cmd == "clear" || cmd == "c") { current_program.clear(); std::cout << "Program cleared\n"; }
                else if (cmd == "status") {
                    std::cout << "Status:\n  Program loaded: " << (current_program.empty() ? "No" : "Yes")
                              << "\n  Instructions: " << interpreter.getCodeSize()
                              << "\n  Memory pointer: " << interpreter.getMemoryPointer()
                              << "\n  Debug mode: " << (debug_mode ? "On" : "Off") << "\n";
                } else { std::cout << "Unknown command: " << cmd << "\n"; }
            } catch (...) { std::cout << "Error occurred\n"; }
        }

        std::cout << "Goodbye!\n";
    }
};

void printUsage(const char* prog_name) {
    std::cout << "TRBBFI v" << TRBBFI_VERSION << " - The Really Better Brainfuck Interpreter\n\n";
    std::cout << "Usage:\n  " << prog_name << "         # Start shell\n"
              << "  " << prog_name << " file.bf  # Execute file\n"
              << "  " << prog_name << " -c code   # Execute code\n"
              << "  " << prog_name << " -d file.bf # Debug mode\n"
              << "  " << prog_name << " -h|--help  # Help\n"
              << "  " << prog_name << " -v|--version # Version\n";
}

void printVersion() {
    std::cout << "TRBBFI v" << TRBBFI_VERSION << " by TheRealOwenJ\n"
              << "Licensed under GNU GPL v3\n"
              << "https://github.com/TheRealOwenJ/trbbfi\n";
}

int main(int argc, char* argv[]) {
    BrainfuckInterpreter interpreter;
    bool debug_mode = false;
    std::string code_arg;

    static struct option long_options[] = {
        {"help", no_argument, 0, 'h'},
        {"version", no_argument, 0, 'v'},
        {"code", required_argument, 0, 'c'},
        {"debug", no_argument, 0, 'd'},
        {0, 0, 0, 0}
    };

    int c;
    while ((c = getopt_long(argc, argv, "hvc:d", long_options, NULL)) != -1) {
        switch (c) {
            case 'h': printUsage(argv[0]); return 0;
            case 'v': printVersion(); return 0;
            case 'c': code_arg = optarg; break;
            case 'd': debug_mode = true; break;
            case '?': return 1;
            default: return 1;
        }
    }

    interpreter.setDebug(debug_mode);

    if (!code_arg.empty()) {
        interpreter.loadCode(code_arg);
        return interpreter.execute() ? 0 : 1;
    }

    if (optind < argc) {
        std::ifstream file(argv[optind], std::ios::binary);
        if (!file) { std::cerr << "Error opening file\n"; return 1; }
        std::string program((std::istreambuf_iterator<char>(file)), std::istreambuf_iterator<char>());
        interpreter.loadCode(program);
        return interpreter.execute() ? 0 : 1;
    }

    try {
        Shell shell;
        shell.run();
    } catch (...) { std::cerr << "Fatal error\n"; return 1; }

    return 0;
}
