# 程序编写环境
1. ubuntu 18.04
2. 依赖工具：flex, bison
# 运行方法
1. 安装所有依赖工具：

       sudo apt install flex, bison
2. 生成目标程序

        make

    会生成 lex.yy.c , parser.tab.c , parser.tab.h , parser
    其中parser即为目标程序
3. 运行程序

        ./parser
# 输入
1. 表达式输入方式：输入一个代数表达式，以$符号标志结束

       例：
       ```
       3+5*(3*(2.4+8.3e-2))$ 
       ```
2. 接受的输入

       接受的文法：
       ```
       E -> E + T|E - T|T
       T -> T * F|T / F|F
       F -> (E)|num
       ```
       其中num词法的正则表达式如下：
               {digit}+(\.{digit}+)?(e[+\-]?{digit}+)?
       其中digit为0-9的单个数字

       即接受无符号常数（整数/小数），支持指数的表达形式
