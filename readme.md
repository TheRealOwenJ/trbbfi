# TRBBFI - The Really Better BrainFuck Interpreter

TRBBFI is a BrainFuck interpreter written in C++ that aims to be the best BrainFuck interpreter for everyone.
It also supports Windows and Linux.

## Usage
To open the shell, run:
```bash
trbbfi
```
and then
```bash
help
```
for all the commands.

If you want to just use the command, without opening the shell, run:
```bash
trbbfi -h
```
for all the commands.

## Manually Building

NOTE: The windows documentation is coming soon! You just need to use msys2 mingw-w64!

To manually build TRBBFI, follow these steps:

Install make and g++, if you haven't already:
```bash
sudo apt-get install make g++
```
or your os' way of installing them.

Clone the repository:
```bash
git clone https://github.com/TheRealOwenJ/trbbfi.git
```

Navigate to the project directory:
```bash
cd trbbfi
```

Build the project using make:
```bash
make
```

If you want to install it as an app, run:
```bash
sudo make install
```
