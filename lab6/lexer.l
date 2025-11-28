%{
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include "st.h"
#include "parser.tab.h"

%}

%option noyywrap
%option yylineno

DIGIT      [0-9]
LETTER     [a-zA-Z]
IDENTIFIER {LETTER}({LETTER}|{DIGIT}|_)*
NUMBER     {DIGIT}+(\.{DIGIT}+)?

%%

"input"         { addToPIF("INPUT",-1); return INPUT; }
"print"         { addToPIF("PRINT",-1); return PRINT; }
"if"            { addToPIF("IF",-1); return IF; }
"else"          { addToPIF("ELSE",-1); return ELSE; }
"while"         { addToPIF("WHILE",-1); return WHILE; }
"function"      { addToPIF("FUNCTION",-1); return FUNCTION; }
"return"        { addToPIF("RETURN",-1); return RETURN; }
"var"           { addToPIF("VAR",-1); return VAR; }

"sqrt"          { addToPIF("SQRT",-1); return SQRT; }
"abs"           { addToPIF("ABS",-1); return ABS; }
"pow"           { addToPIF("POW",-1); return POW; }
"sin"           { addToPIF("SIN",-1); return SIN; }
"cos"           { addToPIF("COS",-1); return COS; }
"tan"           { addToPIF("TAN",-1); return TAN; }

"=="            { addToPIF("==",-1); return EQ; }
"<>"            { addToPIF("<>",-1); return NEQ; }
"<="            { addToPIF("<=",-1); return LE; }
">="            { addToPIF(">=",-1); return GE; }
"<"             { addToPIF("<",-1); return LT; }
">"             { addToPIF(">",-1); return GT; }
"="             { addToPIF("=", -1); return ASSIGN; }

"+"             { addToPIF("+",-1); return '+'; }
"-"             { addToPIF("-",-1); return '-'; }
"*"             { addToPIF("*",-1); return '*'; }
"/"             { addToPIF("/",-1); return '/'; }
"%"             { addToPIF("%",-1); return '%'; }
"^"             { addToPIF("^",-1); return '^'; }
";"             { addToPIF(";",-1); return ';'; }
","             { addToPIF(",",-1); return ','; }
"("             { addToPIF("(",-1); return '('; }
")"             { addToPIF(")",-1); return ')'; }
"{"             { addToPIF("{",-1); return '{'; }
"}"             { addToPIF("}",-1); return '}'; }

{NUMBER} { int idx=st_hash_add(yytext); addToPIF("NUM", idx); yylval.idx=idx; return NUM; }
{IDENTIFIER} { int idx=st_hash_add(yytext); addToPIF("ID", idx); yylval.idx=idx; return ID; }

[ \t\r\n]+     ; 

.            { fprintf(err_out,"Lexical error at line %d: %s\n",yylineno,yytext); lex_error_count++; last_lex_error_line = yylineno; }
%%

