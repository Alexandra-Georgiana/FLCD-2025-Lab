%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <io.h>

#define YY_NO_UNISTD_H
#define isatty _isatty
#define fileno _fileno

FILE* yyin;

typedef struct {
    char token[256];
    int index;
} ST;

typedef struct {
    char token[256];
    int stIndex;
} PIF;

ST SymbolTable[1000];
int stLen = 0;

PIF PIFList[2000];
int pifLen = 0;

int lineNumber = 1;
int errorFound = 0;

int addToST(char* token) {
    for (int i = 0; i < stLen; i++)
        if (strcmp(SymbolTable[i].token, token) == 0)
            return SymbolTable[i].index;

    strcpy(SymbolTable[stLen].token, token);
    SymbolTable[stLen].index = stLen;
    return stLen++;
}

void addToPIF(char* token, int stIndex) {
    strcpy(PIFList[pifLen].token, token);
    PIFList[pifLen].stIndex = stIndex;
    pifLen++;
}

void printST() {
    FILE* f = fopen("ST_hash.txt", "w");
    if (!f) return;
    
    fprintf(f, "--- SYMBOL TABLE ---\n");
    for (int i = 0; i < stLen; i++)
        fprintf(f, "%s -> %d\n", SymbolTable[i].token, SymbolTable[i].index);
    fclose(f);
}

void printPIF() {
    FILE* f = fopen("PIF.txt", "w");
    if (!f) return;
    
    fprintf(f, "--- PROGRAM INTERNAL FORM ---\n");
    for (int i = 0; i < pifLen; i++)
        fprintf(f, "%s -> %d\n", PIFList[i].token, PIFList[i].stIndex);
    fclose(f);
}
%}

LETTER          [a-zA-Z]
DIGIT           [0-9]
IDENTIFIER      {LETTER}({LETTER}|{DIGIT}|"_")*
NUMBER          {DIGIT}+("."{DIGIT}+)?

%%
"input"         { addToPIF("input", -1); }
"print"         { addToPIF("print", -1); }
"if"            { addToPIF("if", -1); }
"else"          { addToPIF("else", -1); }
"while"         { addToPIF("while", -1); }
"function"      { addToPIF("function", -1); }
"return"        { addToPIF("return", -1); }
"var"           { addToPIF("var", -1); }

"sqrt"          { addToPIF("sqrt", -1); }
"abs"           { addToPIF("abs", -1); }
"pow"           { addToPIF("pow", -1); }
"sin"           { addToPIF("sin", -1); }
"cos"           { addToPIF("cos", -1); }
"tan"           { addToPIF("tan", -1); }

"=="            { addToPIF("==", -1); }
"<>"            { addToPIF("<>", -1); }
"<="            { addToPIF("<=", -1); }
">="            { addToPIF(">=", -1); }
[<>]            { addToPIF(yytext, -1); }

"^^"            { addToPIF("^^", -1); }
"%%"            { addToPIF("%%", -1); }
"@@"            { addToPIF("@@", -1); }
"+"             { addToPIF("+", -1); }
"-"             { addToPIF("-", -1); }
"*"             { addToPIF("*", -1); }
"/"             { addToPIF("/", -1); }
"%"             { addToPIF("%", -1); }
"^"             { addToPIF("^", -1); }

"="             { addToPIF("=", -1); }

";"             { addToPIF(";", -1); }
","             { addToPIF(",", -1); }
"("             { addToPIF("(", -1); }
")"             { addToPIF(")", -1); }
"{"             { addToPIF("{", -1); }
"}"             { addToPIF("}", -1); }

{IDENTIFIER}    { int idx = addToST(yytext); addToPIF("id", idx); }
{NUMBER}        { int idx = addToST(yytext); addToPIF("num", idx); }

[ \t\r]+        ;  /* ignore spaces */
\n              { lineNumber++; }

[^ \t\n\r(){}=,;+\-*/%^<>a-zA-Z0-9_][^ \t\n\r]*|[0-9]+[a-zA-Z][^ \t\n\r]*|[a-zA-Z][a-zA-Z0-9_]*[^a-zA-Z0-9_ \t\n\r(){}=,;+\-*/%^<>][^ \t\n\r]* {
    FILE* f = fopen("lexical_errors.txt", "w");
    if (f) {
        fprintf(f, "Lexical error at line %d: Invalid token '%s'\n", lineNumber, yytext);
        fclose(f);
    }
    errorFound = 1;
    printST();  
    printPIF(); 
    yyterminate();
}

%%

int yywrap() { return 1; }

int main(int argc, char** argv) {
    if (argc < 2) {
        printf("Usage: lexer <file>\n");
        return 1;
    }

    FILE* f = fopen(argv[1], "r");
    if (!f) {
        printf("Cannot open file %s\n", argv[1]);
        return 1;
    }

    yyin = f;
    yylex();

    if (!errorFound) {
        printST();
        printPIF();
    }

    return errorFound;
}
