# PA 2

​	For this assignment, you are to write a lexical analyzer, also called a *scanner*, using a *lexical analyzer* *generator* (C++ flex). 

​	You will describe the set of tokens for Cool in an appropriate input format, and the analyzer generator will generate the actual code C++ for recognizing tokens in Cool programs

# Flex

> Flex allows you to implement a lexical analyzer by writing rules that match on user-defined regular
> expressions and performing a specified action for each matched pattern.Flex compiles your rule file (e.g., “lexer.l”) to C source code implementing a finite automaton recognizing
> the regular expressions that you specify in your rule file.
>
> Before you start on this assignment, make sure to read Section 10 and Figure 1 of the Cool manual; then study the different tokens defined in cool-parse.h

```cpp
//flex格式
%{
Declarations
%}
Definitions
%%
Rules
%%
User subroutines
//%{ %}围住的部分会被原封不动的复制到Flex生成的词法分析器代码靠近前面的地方
```

## Definitions

```cpp
name definition //声明格式
DIGIT    [0-9]
ID       [a-z][a-z0-9]*
```

%top块类似 '%{' ... '%}'，但它将块中的代码重定位到生成的文件的顶部(在所有flex定义之前)，%top在定义预处理器宏或包含文件时十分有用。允许多个块并保留顺序

```cpp
%top{
    /* This code goes at the "top" of the generated file. */
    #include <stdint.h>
    #include <inttypes.h>
}
```

## Rule

```cpp
pattern action//rule section格式
```

### patterns

正则表达式扩展集合

`(?r-s:pattern)`：r和s这两个参数可以为空或者`i` `s` `x`，i表示大小写不明敏感，s表示通过`.`匹配单字节的任意字符，x会忽略注释和空白符

**pattern 匹配过程：分析输入来寻找与pattern匹配的字符串，若找到多个匹配字符串，则匹配文本最多的，若找到多个长度相同的匹配字符串，则按照flex输入文件中最先列出的规则选择**

确定匹配后在全局字符指针yytext中提供与该匹配相对应的文本（token），并在全局int变量yyleng中提供长度。然后执行pattern对应的action，扫描剩余输入寻找下一个匹配。

### action

能够包含任意的C代码，包括return语句（将一个值返回给任何调用`yylex()`的程序）

每次调用yylex()，将从上次中断的地方继续处理token，直到文件的末尾或执行返回

可以修改yytext、yyleng

ECHO 拷贝yytext到scanner的输出...

## Format of the User Code Section

用户代码部分仅逐字复制到lex.yy.c。它作为scanner的辅助函数使用。此部分的出现是可选的；如果不存在，则输入文件中的第二个”%%”可以被省略。

## Comments in the Input

介于`/ *`和`* /`之间的任何内容都被认为是注释。

## Generated Scanner

flex的输出是lex.yy.c,包括扫描程序(scanning routine) yylex(),许多用于匹配token的表，一些辅助函数和宏定义。

每次yylex调用，都会从全局输入yyin(默认为stdin)中顺序扫描token，直到到达文件末尾(此时返回0)，或者遇到一个执行”return”语句的action。

如果yylex()由于在某个action上执行了return而停止扫描，则可以再次调用scanner，并且它将从中断处继续扫描。

## Start Condition 

**包含comments和string示例**

flex提供了有条件的激活规则机制，任何以`<sc>`前缀的pattern，仅在scanner处于名为sc的开始状态时，才处于活动状态。

**%s : *inclusive* start conditions** (处于被排除的状态时，其他前置条件对应的pattern依旧生效)

**%x : *exclusive* start conditions**（处于被排除的状态时，其他前置条件对应的pattern不生效）

**`BEGIN(x)`**回到前置x状态 (INITIAL)

## Values Available To the User

`char *yytext`当前token，可指针可数组

`int yyleng` 当前token长度

`FILE *yyin` 默认情况下为flex读取的文件

`void yyrestart( FILE *new_file )` 将yyin指向心的输入文件

`FILE *yyout`执行ECHO的文件

`YY_START` 返回与当前开始条件相对应的整数值，与BEGIN配合返回开始条件

## Interfacing with Yacc

flex的主要用途之一是与yacc解析器生成器一起使用。 yacc解析器应当调用`yylex()`来查找下一个输入token。yylex应返回下一个token的类型，并将所有关联的值放入全局变量`yylval`中。

# Cool Lexical Structure 

## integer

**non-empty strings of digits 0-9**

## Identifier

**consisting of letters, digits, and underscore character**

Type identifier begin with a capital letter; object identifiers begin with a lower case letter

two other identifiers: self and SELF_TYPE

## String

**string are enclosed in double quotes "..."**. 

\c denote character 'c'

exception \b backspace; \t tab; \n newline; \f formfeed; 

\ non-escaped newline character may not appear in string; not contain EOF; not contain \0; 

## Comments

Any characters between two dashes "--" 

comments may also be written by enclosing text in (* ... *)

## Keywords

**class, else, false, fi, if, in, inherits, isvoid, let, loop, pool, then, while,case, esac, new, of, not, true**

true/false: first letter should be lowercase, trailing letters upper or lower case

##  White Space

consists of blank (ascii 32), \n (ascii 10), \f (formfeed ascii12), \r (carriage return ascii13), \t (tab ascii9), \v (vertical tab ascii11)

program ::= [[class; ]]$^+$
	class ::= class TYPE [inherits TYPE] { [[feature; ]]$^∗$}
feature ::= ID( [ formal [[, formal]]$^∗$] ) : TYPE { expr }
			  | ID : TYPE [ <- expr ]
formal ::= ID : TYPE
expr ::= ID <- expr
			| expr[@TYPE].ID( [ expr [[, expr]]$^∗$] )
			| ID( [ expr [[, expr]]$^∗$] )
			| if expr then expr else expr fi
			| while expr loop expr pool
			| { [[expr; ]]$^+$}
			| let ID : TYPE [ <- expr ] [[,ID : TYPE [ <- expr ] ]]$^∗$in expr
			| case expr of [[ID : TYPE => expr; ]]$^+$esac
			| new TYPE
			| isvoid expr
			| expr + expr
			| expr − expr
			| expr ∗ expr
			| expr / expr
			| ˜expr
			| expr < expr
			| expr <= expr
			| expr = expr
			| not expr
			| (expr)
			| ID
			| integer
			| string
			| true
			| false

# 构造过程

## Define names for regular expressions

integer、Identifier、**String（单独处理）**、**Comments（单独处理）**、Keywords、White Space

**keywords**: class, else, false (首字符小写), fi, if, in, inherits, isvoid, let, loop, pool, then, while,case, esac, new, of, not, true (首字符小写) `TRUE      (t(?i:rue))`，模仿true进行类似构造

**integer**: `DIGIT	[0-9]`数字，`INT	{DIGIT}+`任意 DIGIT 组合

**identifier**:` LETTER	[a-zA-Z]`大小写字母的集合，`ID		({LETTER}|{DIGIT}|_)`ID的部分由字母数字和_组成，TYPEID：类名称(大写)`TYPEID		[A-Z]{ID}*`/OBJID：变量名称(小写) `OBJID		[a-z]{ID}*`

**whitespace**：`WHITESPACE  [\ \t\b\f\r\v]*`

**operator**:  Figure 1``| expr + expr | expr − expr | expr ∗ expr | expr / expr | ˜expr | expr < expr | expr <= expr | expr = expr | (expr)`` 即`[\+\-\*/~\<\=\(\)]` 额外考虑`[;\,\:\{\}]`<=在 multiple-character operators中额外考虑。

## aciton构造

For class identifiers, object identifiers, integers, and strings, the semantic value should be a **Symbol** stored in the field **cool_yylval.symbol**
```cpp
{OBJID} { 
  cool_yylval.symbol = idtable.add_string(yytext); 
  return OBJECTID; 
}
{INT}  {
  cool_yylval.symbol = inttable.add_string(yytext); 
  return INT_CONST; 
}
{TRUE}	{
  cool_yylval.boolean = true ;
  return BOOL_CONST;
 }
```
**keywords**: 模仿 {CLASS}     { return CLASS; }构造。其中TRUE、FALSE需进行额外处理。

**identifier**: TYPEID、OBJID进行额外处理

**operator**: 使用`yytext返回本身`

**whitespace**: 不做处理捕捉后直接丢弃

**integer**: INT进行额外处理

## Comments

- Multi_comment

  嵌套层数记录，判断何时结束注释

  `(*` 开始Quote的状态

  `*)`返回初始化状态

  状态下，匹配到EOF进行报错

  匹配\n用于统计换行数

  舍弃所有注释内的字符

  单独判断`*)`单独出现的错误情况

- Dash_comment

  `--`开启Dash_comment状态

  将Dash_comment状态下所有字符全部不做处理舍弃

  Dash状态下匹配EOF及\n（统计换行）

## String 

判断字符串是否超出指定长度，若超出抛出异常，并接收完所有的字符

`“\“”`: 标志字符串开始
`“\””`: 标志字符串结束，加上\0作为字符串结尾

string中匹配`\b \t \n \f \n`将转义字符加入缓冲区，判断字符串长度

 匹配到`EOF`报错

匹配\0进行escaped判断

其余字符直接存入buf

## Error

处理异常的函数，初始化状态，返回ERROR

字符串外的`\`判断进行报错

对于未考虑到的情况进行报错
