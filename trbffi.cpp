/*
 * TRBBFI - The Really Better Brainfuck Interpreter
 * Author: TheRealOwenJ
 * Repository: https://github.com/TheRealOwenJ/trbbfi
 *
 * Licensed under GNU GPL v3.
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
        if (program.empty()) return;

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
                    }
                    break;
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
        std::cout << "  - Debug output goes to stderr (red text in most terminals)\n";
        std::cout << "  - Files must contain valid Brainfuck code (+-<>[].,)\n";
        std::cout << "  - Memory is limited to 1MB for safety\n";
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
            if (!std::getline(std::cin, line)) break;

            line.erase(0, line.find_first_not_of(" \t"));
            line.erase(line.find_last_not_of(" \t") + 1);

            if (line.empty()) continue;
            if (line == "exit" || line == "quit" || line == "q") break;

            auto tokens = tokenize(line);
            std::string cmd = tokens.empty() ? "" : tokens[0];

            if (cmd == "help" || cmd == "h") printHelp();
            else if (cmd == "clear" || cmd == "c") current_program.clear();
            else std::cout << "Unknown command\n";
        }
    }
};

void printUsage(const char* prog_name) {
    std::cout << "TRBBFI v" << TRBBFI_VERSION << " - The Really Better Brainfuck Interpreter\n";
}

void printVersion() {
    std::cout << "TRBBFI v" << TRBBFI_VERSION << " by TheRealOwenJ\n";
    std::cout << "Licensed under GNU GPL v3\n";
    std::cout << "https://github.com/TheRealOwenJ/trbbfi\n";
}

int main(int argc, char* argv[]) {
    printUsage(argv[0]);
    return 0;
}
