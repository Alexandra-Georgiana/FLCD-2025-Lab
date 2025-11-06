%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef struct Node {
    char token[256];
    int index;
    struct Node *left, *right;
} Node;

Node *root = NULL;
int stCount = 0;

Node* newNode(const char *token, int index) {
    Node *n = (Node*)malloc(sizeof(Node));
    if (!n) { fprintf(stderr, "Memory error\n"); exit(1); }
    strncpy(n->token, token, 255);
    n->token[255] = '\0';
    n->index = index;
    n->left = n->right = NULL;
    return n;
}

int addToST(const char *token) {
    Node **curr = &root;
    while (*curr != NULL) {
        int cmp = strcmp(token, (*curr)->token);
        if (cmp == 0)
            return (*curr)->index; /* already exists */
        else if (cmp < 0)
            curr = &((*curr)->left);
        else
            curr = &((*curr)->right);
    }

    *curr = newNode(token, stCount);
    return stCount++;
}

void printSTRec(Node *n, FILE *f) {
    if (n == NULL) return;
    printSTRec(n->left, f);
    fprintf(f, "%s -> %d\n", n->token, n->index);
    printSTRec(n->right, f);
}

void printST_stdout() {
    printf("\n--- SYMBOL TABLE (in-order) ---\n");
    printSTRec(root, stdout);
}

void printST_file(const char *filename) {
    FILE *f = fopen(filename, "w");
    if (!f) return;
    fprintf(f, "--- SYMBOL TABLE ---\n");
    printSTRec(root, f);
    fclose(f);
}

typedef struct {
    char token[256];
    int stIndex;
} PIF;

PIF PIFList[5000];
int pifLen = 0;

void addToPIF(const char* token, int stIndex) {
    strncpy(PIFList[pifLen].token, token, 255);
    PIFList[pifLen].token[255] = '\0';
    PIFList[pifLen].stIndex = stIndex;
    pifLen++;
}

void printPIF_stdout() {
    printf("\n--- PROGRAM INTERNAL FORM ---\n");
    for (int i = 0; i < pifLen; i++)
        printf("%s -> %d\n", PIFList[i].token, PIFList[i].stIndex);
}

void printPIF_file(const char *filename) {
    FILE *f = fopen(filename, "w");
    if (!f) return;
    fprintf(f, "--- PROGRAM INTERNAL FORM ---\n");
    for (int i = 0; i < pifLen; i++)
        fprintf(f, "%s -> %d\n", PIFList[i].token, PIFList[i].stIndex);
    fclose(f);
}

int lineNumber = 1;
int errorFound = 0;

void report_lexical_error(const char *tok) {
    FILE* f = fopen("lexical_errors.txt", "w");
    if (f) {
        fprintf(f, "Lexical error at line %d: Invalid token '%s'\n", lineNumber, tok);
        fclose(f);
    }
    errorFound = 1;
}

typedef struct {
    char from[16];
    char symbol[32]; /* use string for symbol to allow "letter", "digit", "." etc. */
    char to[16];
} Transition;

typedef struct {
    char name[16];
    int isFinal;
} State;

typedef struct {
    State states[10];
    int stateCount;
    Transition trans[256];
    int transCount;
    char startState[16];
} FA;

void addState(FA* fa, const char* name, int isFinal) {
    if (fa->stateCount >= 10) return;
    strncpy(fa->states[fa->stateCount].name, name, 15);
    fa->states[fa->stateCount].name[15] = '\0';
    fa->states[fa->stateCount].isFinal = isFinal;
    fa->stateCount++;
}

void addTransition(FA* fa, const char* from, const char* symbol, const char* to) {
    if (fa->transCount >= 256) return;
    strncpy(fa->trans[fa->transCount].from, from, 15);
    fa->trans[fa->transCount].from[15] = '\0';
    strncpy(fa->trans[fa->transCount].symbol, symbol, 31);
    fa->trans[fa->transCount].symbol[31] = '\0';
    strncpy(fa->trans[fa->transCount].to, to, 15);
    fa->trans[fa->transCount].to[15] = '\0';
    fa->transCount++;
}

FA buildIdentifierFA() {
    FA fa;
    fa.stateCount = 0;
    fa.transCount = 0;
    strncpy(fa.startState, "q0", 15); fa.startState[15] = '\0';

    addState(&fa, "q0", 0);
    addState(&fa, "q1", 1);

    addTransition(&fa, "q0", "letter", "q1");
    addTransition(&fa, "q1", "letter", "q1");
    addTransition(&fa, "q1", "digit", "q1");
    addTransition(&fa, "q1", "_", "q1");

    return fa;
}

FA buildNumberFA() {
    FA fa;
    fa.stateCount = 0;
    fa.transCount = 0;
    strncpy(fa.startState, "q0", 15); fa.startState[15] = '\0';

    addState(&fa, "q0", 0);
    addState(&fa, "q1", 1);
    addState(&fa, "q2", 0);
    addState(&fa, "q3", 1);

    addTransition(&fa, "q0", "digit", "q1");
    addTransition(&fa, "q1", "digit", "q1");
    addTransition(&fa, "q1", ".", "q2");
    addTransition(&fa, "q2", "digit", "q3");
    addTransition(&fa, "q3", "digit", "q3");

    return fa;
}

void printFA(FA *fa, const char* name) {
    printf("\nFA %s\n", name);
    printf("States: ");
    for (int i = 0; i < fa->stateCount; i++)
        printf("%s%s ", fa->states[i].name, fa->states[i].isFinal ? "(F)" : "");
    printf("\nStart state: %s\n", fa->startState);
    printf("Transitions:\n");
    for (int i = 0; i < fa->transCount; i++)
        printf("  %s --%s--> %s\n", fa->trans[i].from, fa->trans[i].symbol, fa->trans[i].to);
}

void transformFAToRG(FA *fa, const char* name) {
    printf("\nFA TO RG %s\n", name);
    for (int i = 0; i < fa->stateCount; i++) {
        const char* s = fa->states[i].name;
        printf("%s -> ", s);
        int printed = 0;

        for (int j = 0; j < fa->transCount; j++) {
            if (strcmp(fa->trans[j].from, s) == 0) {
                if (printed) printf(" | ");
                printf("%s %s", fa->trans[j].symbol, fa->trans[j].to);
                printed = 1;
            }
        }

        if (fa->states[i].isFinal) {
            if (printed) printf(" | ");
            printf("eps");
            printed = 1;
        }
        if (!printed) printf("(no productions)");
        printf("\n");
    }
}

%}

DIGIT       [0-9]
LETTER      [a-zA-Z]
IDENTIFIER  {LETTER}({LETTER}|{DIGIT}|"_")*
NUMBER      {DIGIT}+("."{DIGIT}+)?

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
"<"             { addToPIF("<", -1); }
">"             { addToPIF(">", -1); }

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

[ \t\r]+        ;  
\n              { lineNumber++; }


[^ \t\n\r(){}=,;+\-*/%^<>a-zA-Z0-9_]([^ \t\n\r]*) {
    report_lexical_error(yytext);
    printST_file("ST_hash.txt");
    printPIF_file("PIF.txt");
    yyterminate();
}

[0-9]+[a-zA-Z][^ \t\n\r]* {
    report_lexical_error(yytext);
    printST_file("ST_hash.txt");
    printPIF_file("PIF.txt");
    yyterminate();
}

[a-zA-Z][a-zA-Z0-9_]*[^a-zA-Z0-9_ \t\n\r(){}=,;+\-*/%^<>][^ \t\n\r]* {
    report_lexical_error(yytext);
    printST_file("ST_hash.txt");
    printPIF_file("PIF.txt");
    yyterminate();
}

%%


int yywrap(void) { return 1; }

extern FILE* yyin;

int main(int argc, char** argv) {
    if (argc < 2) {
        printf("Usage: lexer_with_fa_rg <source-file>\n");
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
        printST_stdout();
        printPIF_stdout();
        printST_file("ST_hash.txt");
        printPIF_file("PIF.txt");

        FA idFA = buildIdentifierFA();
        FA numFA = buildNumberFA();

        printFA(&idFA, "IDENTIFIER");
        transformFAToRG(&idFA, "IDENTIFIER");

        printFA(&numFA, "NUMBER");
        transformFAToRG(&numFA, "NUMBER");
    } else {
        printf("Lexical errors found. See lexical_errors.txt\n");
    }

    fclose(f);
    return errorFound ? 1 : 0;
}
