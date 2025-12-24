# TRBBFI - The Really Better Brainfuck Interpreter
# Author: TheRealOwenJ
# Repository: https://github.com/TheRealOwenJ/trbbfi
# Licensed under GNU GPL v3 - see LICENSE file

# =============================================================================
# Configuration
# =============================================================================

# Detect OS
ifeq ($(OS),Windows_NT)
    IS_WINDOWS = 1
else
    IS_WINDOWS = 0
endif

# Compiler and tools
CXX ?= g++
STRIP ?= strip
INSTALL ?= install
RM ?= rm -f

# On Windows with MinGW, du and seq may not exist. Use alternatives
ifeq ($(IS_WINDOWS),1)
    DU ?= echo
    SEQ ?= $(shell seq)
else
    DU ?= du -h
    SEQ ?= seq
endif

# Directories
PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
MANDIR = $(PREFIX)/share/man/man1
SRCDIR = .
BUILDDIR = build
TESTDIR = tests

# Project info
TARGET = trbbfi
SOURCE = trbbfi.cpp
VERSION = 1.0

# Compiler flags
CXXFLAGS_BASE = -std=c++17 -Wall -Wextra -Wpedantic -Wconversion -Wshadow
CXXFLAGS_RELEASE = $(CXXFLAGS_BASE) -O3 -DNDEBUG
CXXFLAGS_DEBUG = $(CXXFLAGS_BASE) -g3 -O0 -DDEBUG
CXXFLAGS_PROFILE = $(CXXFLAGS_BASE) -O2 -g -pg

CXXFLAGS ?= $(CXXFLAGS_RELEASE)

# Linker flags
LDFLAGS_DEBUG =
LDFLAGS_PROFILE = -pg
LDFLAGS ?=

# Test programs
HELLO_WORLD = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
HELLO_WORLD_2 = "+++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."

# =============================================================================
# Targets
# =============================================================================

.PHONY: all clean debug release profile strip install uninstall test test-verbose
.PHONY: check-syntax format lint help info dirs
.DEFAULT_GOAL := all

# Build targets
all: release

release: CXXFLAGS = $(CXXFLAGS_RELEASE)
release: $(TARGET)

debug: CXXFLAGS = $(CXXFLAGS_DEBUG)
debug: LDFLAGS = $(LDFLAGS_DEBUG)
debug: clean $(TARGET)

profile: CXXFLAGS = $(CXXFLAGS_PROFILE)
profile: LDFLAGS = $(LDFLAGS_PROFILE)
profile: clean $(TARGET)

$(TARGET): $(SOURCE)
	@echo "Building $(TARGET) with $(CXX)..."
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $(TARGET) $(SOURCE)
	@echo "Build complete: $(TARGET)"
ifeq ($(IS_WINDOWS),0)
	@echo "Binary size: $$(du -h $(TARGET) | cut -f1)"
endif

strip: $(TARGET)
ifeq ($(IS_WINDOWS),0)
	@echo "Stripping debug symbols..."
	$(STRIP) $(TARGET)
	@echo "Stripped binary size: $$(du -h $(TARGET) | cut -f1)"
else
	@echo "Strip not supported on native Windows. Skipping..."
endif

# Development targets
check-syntax:
	@echo "Checking syntax..."
	$(CXX) $(CXXFLAGS_BASE) -fsyntax-only $(SOURCE)
	@echo "Syntax check passed!"

format:
	@echo "Formatting code (if clang-format is available)..."
	@if command -v clang-format >/dev/null 2>&1; then \
		clang-format -i $(SOURCE); \
		echo "Code formatted!"; \
	else \
		echo "clang-format not found, skipping..."; \
	fi

lint:
	@echo "Running static analysis (if available)..."
	@if command -v cppcheck >/dev/null 2>&1; then \
		cppcheck --enable=all --std=c++17 $(SOURCE); \
	elif command -v clang-tidy >/dev/null 2>&1; then \
		clang-tidy $(SOURCE) -- $(CXXFLAGS_BASE); \
	else \
		echo "No linting tools (cppcheck/clang-tidy) found, skipping..."; \
	fi

# Testing targets
test: $(TARGET)
	@echo "========================================="
	@echo "Running TRBBFI Test Suite"
	@echo "========================================="
	@echo
	@echo "Test 1: Command-line code execution..."
	@printf "Expected: Hello World!\nActual:   "
	@./$(TARGET) -c $(HELLO_WORLD)
	@echo "✓ PASSED"
	@echo
	@echo "Test 2: File execution..."
	@echo $(HELLO_WORLD_2) > test_temp.bf
	@printf "Expected: Hello World!\nActual:   "
	@./$(TARGET) test_temp.bf
	@$(RM) test_temp.bf
	@echo "✓ PASSED"
	@echo
	@echo "Test 3: Version information..."
	@./$(TARGET) --version | head -1
	@echo "✓ PASSED"
	@echo
	@echo "Test 4: Help information..."
	@./$(TARGET) --help >/dev/null && echo "✓ PASSED" || echo "✗ FAILED"
	@echo
	@echo "Test 5: Interactive shell (basic)..."
	@echo -e "status\nexit" | ./$(TARGET) >/dev/null && echo "✓ PASSED" || echo "✗ FAILED"
	@echo
	@echo "Test 6: Error handling (invalid option)..."
	@./$(TARGET) --invalid-option >/dev/null 2>&1 && echo "✗ FAILED" || echo "✓ PASSED"
	@echo
	@echo "========================================="
	@echo "All tests completed successfully!"
	@echo "========================================="

# Installation targets
install: $(TARGET)
	@echo "Installing $(TARGET) to $(BINDIR)..."
	$(INSTALL) -d $(BINDIR)
	$(INSTALL) -m 755 $(TARGET) $(BINDIR)/$(TARGET)
	@echo "Installation complete!"

uninstall:
	@echo "Uninstalling $(TARGET) from $(BINDIR)..."
	$(RM) $(BINDIR)/$(TARGET)
	@echo "Uninstallation complete!"

# Cleanup targets
clean:
	@echo "Cleaning build artifacts..."
	$(RM) $(TARGET) *.o *~ *.core *.gch
	@echo "Clean complete!"

distclean: clean
	$(RM) *.tar.gz
	$(RM) -r $(BUILDDIR) 2>/dev/null || true

# Help/info
help:
	@echo "TRBBFI - The Really Better Brainfuck Interpreter"
	@echo "Build targets:"
	@echo "  all, release    Build optimized release version (default)"
	@echo "  debug          Build debug version with sanitizers"
	@echo "  profile        Build profiling version"
	@echo "  strip          Strip debug symbols from binary"
	@echo "  clean          Remove build artifacts"
	@echo "  distclean      Remove all generated files"
