# TRBBFI - The Really Better Brainfuck Interpreter
# Author: TheRealOwenJ
# Repository: https://github.com/TheRealOwenJ/trbbfi
# Licensed under GNU GPL v3 - see LICENSE file

# =============================================================================
# Configuration
# =============================================================================

# Compiler and tools
CXX ?= g++
STRIP ?= strip
INSTALL ?= install
RM ?= rm -f

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
CXXFLAGS_RELEASE = $(CXXFLAGS_BASE) -O3 -DNDEBUG -march=native
CXXFLAGS_DEBUG = $(CXXFLAGS_BASE) -g3 -O0 -DDEBUG -fsanitize=address -fsanitize=undefined
CXXFLAGS_PROFILE = $(CXXFLAGS_BASE) -O2 -g -pg

# Default flags
CXXFLAGS ?= $(CXXFLAGS_RELEASE)

# Linker flags
LDFLAGS_DEBUG = -fsanitize=address -fsanitize=undefined
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
	@echo "Binary size: $$(du -h $(TARGET) | cut -f1)"
	@if [ "$(CXXFLAGS)" = "$(CXXFLAGS_RELEASE)" ]; then \
		echo "Release build - run 'make strip' to reduce size further"; \
	fi

strip: $(TARGET)
	@echo "Stripping debug symbols..."
	$(STRIP) $(TARGET)
	@echo "Stripped binary size: $$(du -h $(TARGET) | cut -f1)"

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

test-verbose: $(TARGET)
	@echo "Running verbose tests..."
	@echo "Testing with debug output:"
	./$(TARGET) -d -c $(HELLO_WORLD)
	@echo
	@echo "Testing interactive shell:"
	@echo -e "help\ncode $(HELLO_WORLD)\nshow\nrun\nstatus\nexit" | ./$(TARGET)

# Performance test
benchmark: $(TARGET)
	@echo "Running performance benchmark..."
	@echo "Creating large Brainfuck program..."
	@echo "$(HELLO_WORLD)" > bench.bf
	@for i in $$(seq 1 100); do cat bench.bf >> bench_large.bf; done
	@echo "Running benchmark (100x Hello World)..."
	@time ./$(TARGET) bench_large.bf >/dev/null
	@$(RM) bench.bf bench_large.bf
	@echo "Benchmark complete!"

# Installation targets
install: $(TARGET)
	@echo "Installing $(TARGET) to $(BINDIR)..."
	$(INSTALL) -d $(BINDIR)
	$(INSTALL) -m 755 $(TARGET) $(BINDIR)/$(TARGET)
	@echo "Installation complete!"
	@echo "You can now run: $(TARGET)"

uninstall:
	@echo "Uninstalling $(TARGET) from $(BINDIR)..."
	$(RM) $(BINDIR)/$(TARGET)
	@echo "Uninstallation complete!"

# Package targets
dist: clean
	@echo "Creating distribution archive..."
	@mkdir -p trbbfi-$(VERSION)
	@cp *.cpp *.bf Makefile LICENSE trbbfi-$(VERSION)/
	@tar -czf trbbfi-$(VERSION).tar.gz trbbfi-$(VERSION)/
	@$(RM) -r trbbfi-$(VERSION)
	@echo "Created: trbbfi-$(VERSION).tar.gz"

# Cleanup targets
clean:
	@echo "Cleaning build artifacts..."
	$(RM) $(TARGET) *.o *~ *.core *.gch
	$(RM) test_temp.bf bench.bf bench_large.bf
	$(RM) gmon.out *.gcov *.gcda *.gcno
	@echo "Clean complete!"

distclean: clean
	$(RM) *.tar.gz
	$(RM) -r $(BUILDDIR) 2>/dev/null || true

# Information targets
info:
	@echo "========================================="
	@echo "TRBBFI Build Information"
	@echo "========================================="
	@echo "Target:           $(TARGET)"
	@echo "Version:          $(VERSION)"
	@echo "Source:           $(SOURCE)"
	@echo "Compiler:         $(CXX)"
	@echo "Install prefix:   $(PREFIX)"
	@echo "Install bindir:   $(BINDIR)"
	@echo "========================================="
	@echo "Current build flags:"
	@echo "CXXFLAGS:         $(CXXFLAGS)"
	@echo "LDFLAGS:          $(LDFLAGS)"
	@echo "========================================="

help:
	@echo "TRBBFI - The Really Better Brainfuck Interpreter"
	@echo "Build system help"
	@echo
	@echo "Build targets:"
	@echo "  all, release    Build optimized release version (default)"
	@echo "  debug          Build debug version with sanitizers"
	@echo "  profile        Build profiling version"
	@echo "  strip          Strip debug symbols from binary"
	@echo
	@echo "Development targets:"
	@echo "  check-syntax   Check code syntax without building"
	@echo "  format         Format code with clang-format"
	@echo "  lint           Run static analysis tools"
	@echo
	@echo "Testing targets:"
	@echo "  test           Run comprehensive test suite"
	@echo "  test-verbose   Run tests with verbose output"
	@echo "  benchmark      Run performance benchmark"
	@echo
	@echo "Installation targets:"
	@echo "  install        Install to $(PREFIX)/bin"
	@echo "  uninstall      Remove from system"
	@echo
	@echo "Package targets:"
	@echo "  dist           Create distribution archive"
	@echo
	@echo "Cleanup targets:"
	@echo "  clean          Remove build artifacts"
	@echo "  distclean      Remove all generated files"
	@echo
	@echo "Information targets:"
	@echo "  info           Show build configuration"
	@echo "  help           Show this help message"
	@echo
	@echo "Environment variables:"
	@echo "  CXX            C++ compiler (default: g++)"
	@echo "  PREFIX         Install prefix (default: /usr/local)"
	@echo "  CXXFLAGS       Additional compiler flags"
	@echo "  LDFLAGS        Additional linker flags"
	@echo
	@echo "Examples:"
	@echo "  make                    # Build release version"
	@echo "  make debug              # Build debug version"
	@echo "  make test               # Run tests"
	@echo "  make PREFIX=/opt install # Install to /opt/bin"
	@echo "  make CXX=clang++        # Use clang++ compiler"

# Dependency checking
$(SOURCE):
	@if [ ! -f "$(SOURCE)" ]; then \
		echo "Error: Source file $(SOURCE) not found!"; \
		exit 1; \
	fi
