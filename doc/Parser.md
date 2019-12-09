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

## 附：程序源码
### lex.l
```lex
%{
    #include <stdio.h>
    #include "parser.tab.h"
    #define ERROR -1
%}

line    \n
blanks  [ \t]
end     [$\r]
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
{end}         {return END;}
{num}       {printf("num = %s\n", yytext); return NUM;}
.           {return ERROR;}

%%

int yywrap(void){
    return 1;
}
```
### parser.y
```yacc
%{
    #define ACC 1
    #include <stdio.h>
    extern int yylex();
    int yyerror(const char *s);
    int success = 1;
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
    if (success == 1)
        printf("Parsing done.\n");
    return 0;
}

int yyerror(const char *msg)
{
	extern int yylineno;
	printf("Parsing Failed\nLine Number: %d %s\n",yylineno,msg);
    success = 0;
	return 0;
}
```

# LL(1)语法分析程序
在用利用yacc进行语法分析之后，又利用LL(1)文法的分析算法，用C编写了LL(1)语法分析程序
## 程序设计说明
### 词法分析
由于词法分析器实验并未使用C语言编写，故此处并未对常数进行完整的解析，仅仅支持无符号整数（不支持小数），做以示例
### 语法分析
在语法分析中，定义如下数据结构：
* 符号栈
* 输入缓冲区
* 输出（使用到的产生式）
* 分析表

其中，分析表通过如下算法构造：
#### 消左递归
改写后的文法如下：
```
E -> TP
P -> +TP | -TP | e
T -> FQ
Q -> *FQ | /FQ | e
F -> (E) | n  
```
#### FIRST集合与FOLLOW集合
FIRST集合构造如下：
|非终结符 |FIRST   
|---|---|
|E  | ( n  
|P  |  + - e    
|T  |  ( n 
|Q  |  * / e 
|E  |  ( n   
FOLLOW集合构造如下：
|非终结符 |FOLLLOW   
|---|---|
|E  | $ )
|P  | $ )
|T  | + - ) $
|Q  | + - ) $
|E  | + - * / ) $
#### 由FIRST集和FOLLOW集推导出LL(1)分析表
将产生式标号并在相应位置填入产生式对应的序号，错误返回-1，同步信号量返回-2
|+|-|*|/|(|)|n|$
|---|---|---|---|---|---|---|---|
|E|-1|-1|-1|-1|0|-2|0|-2
|P|1|2|-1|-1|-1|3|-1|3
|T|-2|-2|-1|-1|4|-2|4|-2
|Q|7|7|5|6|-1|7|-1|7
|F|-2|-2|-2|-2|8|-2|9|-
#### 由分析表进行书中的主算法

## 测试用例
输入
```
3+2*(4+23)
```
输出
```
Stack:          $E      Buffer:         3+2*(4+23)$     Production:     E -> TP
Stack:          $PT     Buffer:         3+2*(4+23)$     Production:     T -> FQ
Stack:          $PQF    Buffer:         3+2*(4+23)$     Production:     F -> num                                                          
Stack:          $PQn    Buffer:         3+2*(4+23)$                                                                                       
Stack:          $PQ     Buffer:         +2*(4+23)$      Production:     Q -> e
Stack:          $P      Buffer:         +2*(4+23)$      Production:     P -> +TP
Stack:          $PT+    Buffer:         +2*(4+23)$                                                                                        
Stack:          $PT     Buffer:         2*(4+23)$       Production:     T -> FQ                                                           
Stack:          $PQF    Buffer:         2*(4+23)$       Production:     F -> num                                                          
Stack:          $PQn    Buffer:         2*(4+23)$                                                                                         
Stack:          $PQ     Buffer:         *(4+23)$        Production:     Q -> *FQ                                                          
Stack:          $PQF*   Buffer:         *(4+23)$                                                                                          
Stack:          $PQF    Buffer:         (4+23)$         Production:     F -> (E)                                                   
Stack:          $PQ)E(  Buffer:         (4+23)$                                                                                           
Stack:          $PQ)E   Buffer:         4+23)$          Production:     E -> TP                                                        
Stack:          $PQ)PT  Buffer:         4+23)$          Production:     T -> FQ                 
Stack:          $PQ)PQF Buffer:         4+23)$          Production:     F -> num                                                          
Stack:          $PQ)PQn Buffer:         4+23)$                                                                                            
Stack:          $PQ)PQ  Buffer:         +23)$           Production:     Q -> e 
Stack:          $PQ)P   Buffer:         +23)$           Production:     P -> +TP
Stack:          $PQ)PT+ Buffer:         +23)$                                                                                             
Stack:          $PQ)PT  Buffer:         23)$            Production:     T -> FQ
Stack:          $PQ)PQF Buffer:         23)$            Production:     F -> num 
Stack:          $PQ)PQn Buffer:         23)$                                                                                              
Stack:          $PQ)PQ  Buffer:         )$              Production:     Q -> e            
Stack:          $PQ)P   Buffer:         )$              Production:     P -> e                            
Stack:          $PQ)    Buffer:         )$                                                                                                
Stack:          $PQ     Buffer:         $               Production:     Q -> e                            
Stack:          $P      Buffer:         $               Production:     P -> e                                    
Stack:          $       Buffer:         $ 
```
## 附件：程序源码
```C++
#include<iostream>
#include<vector>
#include<string.h>
#include<iomanip>
using namespace std;
/* 先消除左递归(n表示数字)
    E -> TP
    P -> +TP | -TP | e
    T -> FQ
    Q -> *FQ | /FQ | e
    F -> (E) | n   

        first    follow
    E    ( n       $ )
    P    + - e     $ )
    T    ( n       + - ) $
    Q    * / e     + - ) $
    E    ( n       + - * / ) $
*/ 
#define N_num 5 
#define T_num 8 
#define G_num 10
#define Len 10
#define ERROR -1
#define SYNCH -2

vector<char> buffer;//输入缓冲区
vector<char> stack;  //符号栈
int ptr = 0;

char grammar[G_num][Len] = {"E~TP", "P~+TP", "P~-TP", "P~e","T~FQ", "Q~*FQ", "Q~/FQ", "Q~e","F~(E)","F~n"};
char ter[T_num] = {'+','-','*','/','(',')','n','$'}; //终结符
char nter[N_num] = {'E','P','T','Q','F'}; //非终结符
char first[N_num][Len] = {"(n", "+-e", "(n", "*/e", "(n"}; //first集合
char follow[N_num][Len] = {"$)","$)","+-$)","+-$)","+-*/$)"}; //follow集合
int analysis_table[N_num][T_num]; //预测分析表


int is_N(char c){//判断c是否是非终结符
    if (c=='E' || c=='P' || c=='T' || c=='Q' || c=='F')
        return 1;
    else
        return 0;
}

int is_T(char c){//判断c是否是终结符
    if (c=='+' || c=='-' || c=='*' || c=='/' || c=='(' || c==')' || c=='n' || c=='$')
        return 1;
    else
        return 0;    
}

int is_digit(char c){
    if( c >= '0' && c <= '9' ){
        return 1;
    }else
        return 0;
}

int T_No(char c){
    for (int i = 0; i < T_num; i++){
        if(c == ter[i])
            return i;
    }
    return -1;
}
int N_No(char c){
    for (int i = 0; i < N_num; i++){
        if(c == nter[i])
            return i;
    }
    return -1;
}

int in_first(char N ,char T){//判断终结符T是否在非终结符N的first集中
    int i = N_No(N);
    for (int j = 0; first[i][j] != '\0';j++){
        if(T == first[i][j])
            return 1;
    }
    return 0;
}

int in_follow(char N ,char T){//判断终结符T是否在非终结符N的follow集中
    int i = N_No(N);
    for (int j = 0; follow[i][j] != '\0'; j++){
        if(T == follow[i][j]){
            return 1;
        }
    }
    return 0;
}

//构造预测分析表
void create_table(){
    int row, col;
    char N, sym;
    for (int i = 0; i < N_num; i++){//初始化预测分析表
        for (int j = 0; j < T_num; j++)
        {
            analysis_table[i][j] = ERROR;
        }
    }

    for (int i = 0; i < G_num;i++){//遍历所有文法，文法序号为i
        N = grammar[i][0];//文法的左部
        sym = grammar[i][2];//文法右边的第一个符号

        if(is_T(sym)){//如果sym是终结符
            row = N_No(N);
            col = T_No(sym);
            analysis_table[row][col] = i;
        }else if(is_N(sym)){//如果sym是非终结符
            for (int j = 0; j < T_num;j++){//j是第几个终结符，列
                if(in_first(sym,ter[j])){//判断第j个非终结符是否属于sym的first集
                    row = N_No(N);
                    col = j;
                    analysis_table[row][col] = i;
                }
            }
        }else if(sym == 'e'){//如果sym为空
            for (int j = 0; j < T_num;j++){//j是第几个非终结符，列
                if(in_follow(N,ter[j])){//判断第j个非终结符是否属于左部的follow集
                    row = N_No(N);
                    col = j;
                    analysis_table[row][col] = i;
                }
            }
        }
    }

    for (int i = 0; i < N_num;i++){//置同步量信息
        for (int j = 0; j < T_num;j++){
            if (analysis_table[i][j] == ERROR && in_follow(nter[i], ter[j])){
                analysis_table[i][j] = SYNCH;
            }
        }
    }
}

void get_buffer(){
    string s;
    cout << "Please input the expression:" << endl;
    cin >> s;
    for (int i = 0; s[i] != '\0';i++){
        buffer.push_back(s[i]);
    }
    buffer.push_back('$');
}

void output_stack(){
    cout << left<<setw(16) << "Stack: ";
    for (int i = 0; i < stack.size();i++){
        cout << stack[i];
    }
    cout << "\t";
}

void output_buffer(int p){
    cout << left<<setw(16) << "Buffer: ";
    for (int i = p; i < buffer.size(); i++)
    {
        cout << buffer[i] ;
    }
    cout << "\t";
}

void printf_production(int i){
    cout << left<<setw(16) << "Production: ";
    switch (i)  //根据产生式的标号打印出对应是输出产生式 
	{
        case 0:
            printf ("E -> TP");
            break;
        case 1:
            printf ("P -> +TP");
            break;
        case 2:
            printf ("P -> -TP");
            break;
        case 3:
            printf ("P -> e");
            break;
        case 4:
            printf ("T -> FQ");
            break;
        case 5:
            printf ("Q -> *FQ");
            break;
        case 6:
            printf ("Q -> /FQ");
            break;
        case 7:
            printf ("Q -> e");
            break;
        case 8:
            printf ("F -> (E)");
            break;
        case 9:
            printf ("F -> num");
            break;
        default:
            break; 
    }
    
}
void digit_to_n(int p){//若识别到数字，略去紧随其后的全部数字直到一个符号为止
     for (int i = p; i < buffer.size();i++){
            if(is_digit(buffer[i])){
                buffer[i] = 'n';
                i++;
                while(is_digit(buffer[i])){
                    buffer.erase(buffer.begin() + i);
                }
            }
            break;
        }
}

//预测分析过程
void analysis(){

    char X;//X是栈顶符号
    char a;//缓冲区指针所指向+-*/e()
    int row, col;
    int pn;//文法产生式对应的序号


    do{

        output_stack();
        output_buffer(ptr);

        X = stack.back();
        a = buffer[ptr];

        if(is_T(X)){//栈顶是终结符号，不管是否与a匹配，将X弹出，ptr前移

            if(is_digit(a)){//缓冲区指针ptr指向数字，将数字转换成‘n’
                 digit_to_n(ptr);
                 a = buffer[ptr];
            } 
            if(X==a){
                stack.pop_back();
                ptr++; 
            }else{
                stack.pop_back();
                ptr++;
                cout << "wrong" << endl;
            }

        }else{//栈顶符号是非终结符

            if(is_digit(a)){//缓冲区指针ptr指向数字，将数字转换成‘n’
                //  digit_to_n(ptr);
                //  a = buffer[ptr];
                a = 'n';
            }

            row = N_No(X);
            col = T_No(a);

            if(analysis_table[row][col]!=ERROR && analysis_table[row][col]!= SYNCH){//分析表中有对应的文法
                stack.pop_back();
                pn = analysis_table[row][col];
                if(grammar[pn][2] != 'e'){//若产生式的右边不是ε，则将其倒序压入
                    int k;
                    for (k = 2; grammar[pn][k] != '\0'; k++);  //将对应产生式的右边逆序压入栈中 
                    for (k--; k >= 2; k--)
                        stack.push_back(grammar[pn][k]);            
                }
                printf_production(pn);
            }else if(analysis_table[row][col]==ERROR){//分析表项为空，ptr前移，跳过当前输入字符（串） 
                ptr++;
                cout << "BLANK jump" << endl;
            }else if(analysis_table[row][col]==SYNCH){//分析表项M[X][a]为同步信息，则弹出栈顶符
                stack.pop_back();
                cout << "SYNCH POP " << X << endl;
            }
        }
        cout << endl;
    } while (X != '$');
}


int main(){

    //初始化符号栈，压入'$'以及初始符号'E'
    stack.push_back('$');
    stack.push_back('E');

    create_table();  
    get_buffer();
    analysis();
}
```
# 程序设计心得
1. 经过词法分析器和语法分析器两次程序设计之后，对于lex和yacc的使用有了一定的了解，可以通过这两个工具解决其它遇到的文本处理问题
2. 使用C++编写LL(1)文法分析算法的过程中，对课本上算法的数据结构及其实现有了更深刻的理解