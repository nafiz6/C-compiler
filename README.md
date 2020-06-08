# C-compiler
Takes a C file as input and parses it to assembly code (EMU-8086)

The [compiler directory](../../tree/master/compiler/) has the code for the project. The user input file is tokenized using lex and relevant information is stored in a SymbolTable. The tokens are then sent to a bison parser which generates a corresponding assembly code using bottom-up parsing (shift-reduce).

[a.out](../master/a.out) is the compiled binary file. To enter a custom .c file, simply run `a.out input.c`. 
A log.txt file is generated which will contain any details of errors.

The grammer can be found [here](../master/Grammar.pdf).Not all C functionalities are implemented in this compiler. This is just a basic represantion of how a general compiler may work.


You can also test the compiler online at [nafiz6.github.io/c-to-assembly](https://nafiz6.github.io/c-to-assembly.html)
