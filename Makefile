BIN = parser
parser: lex.l parser.y
	bison -d parser.y
	flex lex.l
	gcc -o $(BIN) parser.tab.c lex.yy.c

.PHONY: clean

clean:
	@- $(RM) *.tab.c *.tab.h *.yy.c $(BIN)