# 利用yacc自动生成语法分析程序
## 实验题目要求
对于指定的文法，利用YACC自动生成语法分析程序，调用LEX自动生成的词法分析程序，在对输入的算术表达式进行分析的过程中，依次输出所采用的产生式
## 程序编写环境
1. ubuntu 18.04
2. 依赖工具：flex, bison
## 运行方法
1. 安装所有依赖工具：

       sudo apt install flex, bison
2. 生成目标程序

        make

    会生成 lex.yy.c , parser.tab.c , parser.tab.h , parser
    其中parser即为目标程序
3. 运行程序

        ./parser
## 输入
### 表达式输入方式：输入一个代数表达式，以$符号标志结束
例：
```
3+5*(3*(2.4+8.3e-2))$ 
```
### 接受的输入
接受的文法：
```
E -> E + T|E - T|T
T -> T * F|T / F|F
F -> (E)|num
```
为了使文法接受项目唯一，将原文法改造如下：
```
S -> E
E -> E + T|E - T|T
T -> T * F|T / F|F
F -> (E)|num
```

其中num词法的正则表达式如下：
```
{digit}+(\.{digit}+)?(e[+\-]?{digit}+)?
```
其中digit为0-9的单个数字

即接受无符号常数（整数/小数），支持指数的表达形式

## 源码说明
### flex与bison协同工作
#### Flex与Bison
* Flex和Bison分别从lex和yacc发展而来
* Flex是一种生成扫描器的工具，可以识别文本中的词汇模式，用于编写词法分析
* Bison(GNU bison)用于自动生成语法分析器程序，把LALR形式的上下文无关文法描述转换为可做语法分析的C或C++程序。Bison基本兼容Yacc，并做了一些改进。它一般与flex一起使用。

#### 协同工作方式简述
Bison用于进行语法分析， 需要定义出引用到的```%token```，这些```%token```由词法分析程序（由Flex协助生成）识别并返回结果，本次实验中再语法分析程序中```%token```定义如下：
```
%token PLUS MINUS TIMES DIV LP RP NUM END
```
Flex编写的词法分析程序识别到上```%token```时，执行对应的C动作，最后将对应的```%token```宏定义作为返回值返回，如此便实现了Flex与Bison的协同工作

### 使用Flex编写词法分析器
#### 声明部分
##### C语言声明
```C
#include <stdio.h>
#include "parser.tab.h"
#define ERROR -1
```
* 当识别出数字时，希望打印出调试信息，即数字的值为多少，故需要包含标准输入输出
* 由于Flex中需要使用再Bison中定义的```%token```，故需要将使用Bison生成的C程序的头文件包含进来，其中包括这些```%token```的定义
* 当识别出错误词法时，返回-1

##### 记号声明部分
```lex
line    \n
blanks  [ \t]
end     [$\r]
digit   [0-9]
num     {digit}+(\.{digit}+)?(e[+\-]?{digit}+)?
```
定义各种记号，其中，数字部分定义为无符号数，并支持指数的识别

#### 词法识别部分
```lex
{blanks}    ;
"("         {return LP;}
")"         {return RP;}
"+"         {return PLUS;}
"-"         {return MINUS;}
"*"         {return TIMES;}
"/"         {return DIV;}
{end}         {return END;}
{num}       {printf("num = %s\n", yytext); return NUM;}
.           {return ERROR;}
```
当识别到某个在本题中需要用到的记号（由语法分析器定义）时，在随后需要执行的C语言动作中，返回定义好的相对应```%token```的值

### 使用Bison编写语法分析器
#### 声明部分
##### C语言声明
```C++
#define ACC 1
#include <stdio.h>
extern int yylex();
int yyerror(const char *s);
int success = 1;
```
* 由于引用了来自其它目标程序的函数```yylex()```，故需要声明出来
* 为了判断文法解析是否成功，设置标志位```success```

##### 语法分析程序声明
```yacc
%token PLUS MINUS TIMES DIV LP RP NUM END
%start s
```
* ```%token```标志语法分析器中引用的记号，由词法分析器返回结果
* ```%start```标志文法的起始符号

#### 语法解析部分
```
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
```
* 其中，识别出每个产生式后执行打印的动作，即输出使用到的产生式
* 当最终归约到起始符号时，返回成功接收标记

#### C程序部分
```C++
int main(){
    yyparse();
    if (success == 1)
        printf("Parsing done.\n");
    return 0;
}

int yyerror(const char *msg){
    extern int yylineno;
    printf("Parsing Failed\nLine Number: %d %s\n",yylineno,msg);
    success = 0;
    return 0;
}
```
* 主程序开始即调用语法分析函数```yyparse()```，分析成功后输出```Parsin done.```标志
* 对于错误的处理，输出错误的行位置（由于每次程序运行识别一个句子，故行位置通常为1）以及错误信息

### 使用Makefile生成目标文件
Makefile中内容如下
```Makefile
BIN = parser
OBJ = parser.tab.c lex.yy.c
parser: lex.l parser.y
	bison -d parser.y
	flex lex.l
	gcc -o $(BIN) $(OBJ)

.PHONY: clean

clean:
	@- $(RM) *.tab.c *.tab.h *.yy.c $(BIN)
```
## 测试用例
表达式
```
3+5*(3*(2.4+8.3e-2))$ 
```
输出结果
```
num = 3
F -> num
T -> F
E -> T
num = 5
F -> num
T -> F
num = 3
F -> num
T -> F
num = 2.4
F -> num
T -> F
E -> T
num = 8.3e-2
F -> num
T -> F
E -> E + T
F -> (E)
T -> T * F
E -> T
F -> (E)
T -> T * F
E -> E + T
S -> E
Parsing done.
```
