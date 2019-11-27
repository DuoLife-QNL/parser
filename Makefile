parser: lex.l parser.y
	bison -d parser.y
	flex lex.l
	gcc -o parser parser.tab.c lex.yy.c