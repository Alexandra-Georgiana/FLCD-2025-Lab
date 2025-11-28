%{
#include <stdio.h>
#include <stdlib.h>
#include "st.h"

extern int yylex(void);
extern FILE *yyin;
extern int yylineno;
extern char *yytext;

void yyerror(const char *s) {
    /* If there was a lexical error on this same line, suppress duplicate syntax noise
       and record that parsing was impacted by a lexical error instead. */
    if (last_lex_error_line == yylineno) {
        if (syn_err_out) {
            fprintf(syn_err_out, "Lexical error on line %d; parser message suppressed (lexer found: see lexical_errors.txt)\n", yylineno);
        }
        fprintf(stderr, "Lexical error on line %d; parser message suppressed\n", yylineno);
        return;
    }
    if (syn_err_out) {
        fprintf(syn_err_out, "Syntax error at line %d: %s near '%s'\n", yylineno, s, yytext ? yytext : "");
    }
    fprintf(stderr, "Syntax error at line %d: %s near '%s'\n", yylineno, s, yytext ? yytext : "");
}

%}
%union { int idx; }
%token <idx> ID NUM
%token INPUT PRINT IF ELSE WHILE FUNCTION RETURN VAR
%token SQRT ABS POW SIN COS TAN

%left '+' '-'
%left '*' '/' '%'
%right '^'
%nonassoc EQ NEQ LT GT LE GE
%nonassoc ASSIGN

%start program
%%

program:
    statement_list { add_production("program -> statement_list"); }
;

statement_list:
      /* empty */ { add_production("statement_list -> /* empty */"); }
    | statement_list statement { add_production("statement_list -> statement_list statement"); }
;

statement:
            VAR ID ASSIGN expression ';' { add_production("statement -> VAR ID ASSIGN expression ;"); }
        | ID ASSIGN expression ';' { add_production("statement -> ID ASSIGN expression ;"); }
        | PRINT expression ';' { add_production("statement -> PRINT expression ;"); }
        | INPUT ID ';' { add_production("statement -> INPUT ID ;"); }
        | expression ';' { add_production("statement -> expression ;"); }
        | IF '(' expression ')' '{' statement_list '}' { add_production("statement -> IF ( expression ) { statement_list }"); }
        | IF '(' expression ')' '{' statement_list '}' ELSE '{' statement_list '}' { add_production("statement -> IF ( expression ) { statement_list } ELSE { statement_list }"); }
        | WHILE '(' expression ')' '{' statement_list '}' { add_production("statement -> WHILE ( expression ) { statement_list }"); }
        | FUNCTION ID '(' param_list_opt ')' '{' statement_list '}' { add_production("statement -> FUNCTION ID ( param_list_opt ) { statement_list }"); }
        | RETURN expression ';' { add_production("statement -> RETURN expression ;"); }
;

param_list_opt:
            /* empty */ { add_production("param_list_opt -> /* empty */"); }
        | param_list { add_production("param_list_opt -> param_list"); }
;

param_list:
            ID { add_production("param_list -> ID"); }
        | param_list ',' ID { add_production("param_list -> param_list , ID"); }
;

expression:
            term { add_production("expression -> term"); }
        | expression '+' term { add_production("expression -> expression + term"); }
        | expression '-' term { add_production("expression -> expression - term"); }
        | expression '*' term { add_production("expression -> expression * term"); }
        | expression '/' term { add_production("expression -> expression / term"); }
        | expression '^' term { add_production("expression -> expression ^ term"); }
        | expression EQ expression { add_production("expression -> expression EQ expression"); }
        | expression NEQ expression { add_production("expression -> expression NEQ expression"); }
        | expression LT expression { add_production("expression -> expression LT expression"); }
        | expression GT expression { add_production("expression -> expression GT expression"); }
        | expression LE expression { add_production("expression -> expression LE expression"); }
        | expression GE expression { add_production("expression -> expression GE expression"); }
;

term:
            ID { add_production("term -> ID"); }
        | NUM { add_production("term -> NUM"); }
        | '(' expression ')' { add_production("term -> ( expression )"); }
;

%%

int main(int argc,char **argv){
    if(argc<2){ printf("Usage: parser <source>\n"); return 1; }
    st_init();
    pif_out=fopen("PIF.txt","w");
    err_out=fopen("lexical_errors.txt","w");
    syn_err_out=fopen("syntax_errors.txt","w");
    prod_out=fopen("productions.txt","w");
    FILE *f=fopen(argv[1],"r");
    if(!f){ printf("Cannot open %s\n",argv[1]); return 1; }
    yyin=f;
    yyparse();
    fclose(f);
    st_hash_dump_stdout();
    printPIF_stdout();
    st_hash_dump("ST_bst.txt");
    printPIF_file("PIF.txt");
    st_destroy();
    fclose(pif_out);
    fclose(err_out);
    if(syn_err_out) fclose(syn_err_out);
    if(prod_out) fclose(prod_out);
    return 0;
}
