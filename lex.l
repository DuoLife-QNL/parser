%{
    #include <stdio.h>
    #include "parser.tab.h"
    #define ERROR -1
%}

line    \n
blanks  [ \t]
end     [$]
digit   [0-9]
num     {digit}+(\.{digit}+)?(e[+\-]?{digit}+)?

%%

{blanks}    ;
"("         {return LP;}
")"         {return RP;}
"+"         {return PLUS;}
"-"         {return MINUS;}
"*"         {return TIMES;}
"/"         {return DIV;}
"$"         {return END;}
{num}       {printf("num = %s\n", yytext); return NUM;}
.           {return ERROR;}

%%

int yywrap(void){
    return 1;
}