%{
    #include <stdio.h>
    int yylex();
    int yyerror(const char *s);
    #define ACC 1
%}

%token PLUS MINUS TIMES DIV LP RP NUM END
%start s

%%
s   : e END         {printf("S -> E\n"); return ACC;}
    ;
e   : e PLUS t      {printf("E -> E + T\n");}
    | e MINUS t     {printf("E -> E - T\n");}
    | t             {printf("E -> T\n");}
    ;
t   : t TIMES f     {printf("T -> T * F\n");}
    | t DIV f       {printf("T -> T / F\n");}
    | f             {printf("T -> F\n");}
    ;
f   : LP e RP       {printf("F -> (E)\n");}
    | NUM           {printf("F -> num\n");}
    ;

%%

int main(){
    yyparse();
    printf("Parsing done.\n");
    return 0;
}

int yyerror(const char *msg)
{
	extern int yylineno;
	printf("Parsing Failed\nLine Number: %d %s\n",yylineno,msg);
	return 0;
}