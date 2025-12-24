# TRBBFI - The Really Better Brainfuck Interpreter

# =============================================================================
# Configuration
# =============================================================================

ifeq ($(OS),Windows_NT)
    IS_WINDOWS = 1
else
    IS_WINDOWS = 0
endif

CXX      ?= g++
STRIP    ?= strip
INSTALL  ?= install
RM       ?= rm -f

ifeq ($(IS_WINDOWS),1)
    DU  = echo
    SEQ = echo
else
    DU  = du -h
    SEQ = seq
endif

PREFIX   ?= /usr/local
BINDIR   = $(PREFIX)/bin

TARGET   = trbbfi
SOURCE   = trbbfi.cpp
VERSION  = 1.0

CXXFLAGS_BASE    = -std=c++17 -Wall -Wextra -Wpedantic -Wconversion -Wshadow
CXXFLAGS_RELEASE = $(CXXFLAGS_BASE) -O3 -DNDEBUG
CXXFLAGS_DEBUG   = $(CXXFLAGS_BASE) -g3 -O0 -DDEBUG
CXXFLAGS_PROFILE = $(CXXFLAGS_BASE) -O2 -g -pg

CXXFLAGS ?= $(CXXFLAGS_RELEASE)

LDFLAGS_DEBUG   =
LDFLAGS_PROFILE = -pg
LDFLAGS         ?=

HELLO_WORLD = "++++++++[>++++[>++>+++>+++>+<<<<-]>+>+>->>+[<]<-]>>.>---.+++++++..+++.>>.<-.<.+++.------.--------.>>+.>++."
HELLO_WORLD_2 = "+++++++++++[>+++++++>++++++++++>+++>+<<<<-]>++.>+.++++++..+++.>++.<<+++++++++++++++.>.+++.------.--------.>+.>."

.PHONY: all clean distclean debug release profile strip install uninstall test help

.DEFAULT_GOAL := all

all: release

release: CXXFLAGS=$(CXXFLAGS_RELEASE)
release: $(TARGET)

debug: CXXFLAGS=$(CXXFLAGS_DEBUG)
debug: LDFLAGS=$(LDFLAGS_DEBUG)
debug: clean $(TARGET)

profile: CXXFLAGS=$(CXXFLAGS_PROFILE)
profile: LDFLAGS=$(LDFLAGS_PROFILE)
profile: clean $(TARGET)

$(TARGET): $(SOURCE)
	@echo "Building $(TARGET)..."
	$(CXX) $(CXXFLAGS) $(LDFLAGS) -o $(TARGET) $(SOURCE)
	@echo "Build complete"
ifeq ($(IS_WINDOWS),0)
	@echo "Binary size: $$($(DU) $(TARGET) | cut -f1)"
endif

strip: $(TARGET)
ifeq ($(IS_WINDOWS),0)
	$(STRIP) $(TARGET)
	@echo "Stripped."
else
	@echo "Strip not supported on Windows."
endif

test: $(TARGET)
	@printf "Expected: Hello World!\nActual:   "
	@./$(TARGET) -c $(HELLO_WORLD)

install: $(TARGET)
	@echo "Installing to $(BINDIR)..."
	$(INSTALL) -d $(DESTDIR)$(BINDIR)
	$(INSTALL) -m 755 $(TARGET) $(DESTDIR)$(BINDIR)/$(TARGET)

uninstall:
	$(RM) $(DESTDIR)$(BINDIR)/$(TARGET)

clean:
	$(RM) $(TARGET) *.o *~ *.core *.gch

distclean: clean
	$(RM) *.tar.gz
	$(RM) -r build 2>/dev/null || true

help:
	@echo "Targets:"
	@echo "  make           build release"
	@echo "  make debug     build debug"
	@echo "  make profile   build with profiling"
	@echo "  make test      run basic test"
	@echo "  make install   install binary"
	@echo "  make clean     remove artifacts"
