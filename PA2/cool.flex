/*
 *  The scanner definition for COOL.
 */
%option noyywrap
/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
#define ERROR_HANDLE \
    BEGIN(INITIAL);\
    return ERROR;

#define CHK_STRING_LEN \
    if (string_buf_ptr - string_buf >= MAX_STR_CONST) \
    { \
      char ch;\
      cool_yylval.error_msg = "String constant too long"; \
      while((ch = yyinput()) != '\"' && ch != EOF) \
        continue; \
      ERROR_HANDLE   \
    }

int comment_line = 0;
%}
%x DASH_COMMENT
%x MUTILINE_COMMENT
%x STRING
/*
 * Define names for regular expressions here.
 */

DARROW          =>
CLASS     (?i:class)
ELSE      (?i:else)
FI        (?i:fi)
IF        (?i:if)
IN        (?i:in)
INHERITS  (?i:inherits)
LET       (?i:let)
LOOP      (?i:loop)
POOL      (?i:pool)
THEN      (?i:then)
WHILE     (?i:while)
CASE      (?i:case)
ESAC      (?i:esac)
OF        (?i:of)
NEW       (?i:new)
ISVOID    (?i:isvoid)
NOT       (?i:not)
TRUE      (t(?i:rue))
FALSE     (f(?i:alse))

DIGIT     [0-9]
INT       {DIGIT}+
LETTER    [a-zA-Z]
ID        ({LETTER}|{DIGIT}|_)
TYPEID    [A-Z]{ID}*
OBJID     [a-z]{ID}*

WHITESPACE  [\ \t\b\f\r\v]*
SINGLE_OPERATOR      [\<\=\+/\-\*\.~\,;\:\(\)@\{\}]

%%

 /*
  *  Nested comments
  */
"--"    { BEGIN(DASH_COMMENT); }
<DASH_COMMENT>.
<DASH_COMMENT><<EOF>> { BEGIN(INITIAL); }
<DASH_COMMENT>\n      { BEGIN(INITIAL); curr_lineno++; }

<MUTILINE_COMMENT,INITIAL>"(*" { 
  if(! comment_line++)
    BEGIN(MUTILINE_COMMENT); 
}

<MUTILINE_COMMENT>"*)" {
  if(!--comment_line)
    BEGIN(INITIAL);
}

<MUTILINE_COMMENT>.

<MUTILINE_COMMENT><<EOF>>	{
  cool_yylval.error_msg = "EOF in comment";
  ERROR_HANDLE
}

<MUTILINE_COMMENT>\n     {curr_lineno++;}

<INITIAL>"*)"	{
  cool_yylval.error_msg = "Unmatched *)";
  return ERROR;
}

 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return DARROW; }
"<-"                  { return ASSIGN; }
"<="                  { return LE; }

{SINGLE_OPERATOR}     { return *yytext;}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}     { return CLASS; }
{FI}        { return FI;    }
{IF}        { return IF;    }
{ELSE}      { return ELSE;  }
{IN}        { return IN;    }
{INHERITS}  { return INHERITS;}
{LET}       { return LET;   }
{LOOP}      { return LOOP;  }
{POOL}      { return POOL;  }
{THEN}      { return THEN;  }
{WHILE}     { return WHILE; }
{CASE}      { return CASE;  }
{ESAC}      { return ESAC;  }
{OF}        { return OF;    }
{NEW}       { return NEW;   }
{ISVOID}    { return ISVOID;}
{WHITESPACE}
{NOT}       { return NOT;   }
{TRUE} {
  cool_yylval.boolean = true;
  return BOOL_CONST;
}
{FALSE} {
  cool_yylval.boolean = false;
  return BOOL_CONST;
}
{INT}   {
  cool_yylval.symbol = inttable.add_string(yytext);
  return INT_CONST;
}
{TYPEID}  {
  cool_yylval.symbol = idtable.add_string(yytext);
  return TYPEID;
}
{OBJID} { 
  cool_yylval.symbol = idtable.add_string(yytext); 
  return OBJECTID; 
}

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
"\""    { 
  string_buf_ptr = string_buf; 
  BEGIN(STRING);
}
<STRING>.	{
  *string_buf_ptr++ = *yytext;
  CHK_STRING_LEN
}
<STRING>\\[t]	{
  *string_buf_ptr = '\t';
  CHK_STRING_LEN
}
<STRING>\\[b]	{
  *string_buf_ptr = '\b';
  CHK_STRING_LEN
}
<STRING>\\[f]	{
  *string_buf_ptr = '\f';
  CHK_STRING_LEN
}
<STRING>\\[n]	{
  *string_buf_ptr = '\n';
  CHK_STRING_LEN
}
<STRING>\\\n   { 
  curr_lineno++;
  CHK_STRING_LEN
}
<STRING>\n	{
  cool_yylval.error_msg = "Unterminated string constant";
  curr_lineno++;
  ERROR_HANDLE
}
<STRING>\\[0]	{
  char ch;
  for(ch = yyinput(); ch != '\n' && ch != EOF && ch!='\"' ; ch = yyinput());
  cool_yylval.error_msg = "String contains null character.";
  ERROR_HANDLE
}
<STRING><<EOF>>  {
  cool_yylval.error_msg = "EOF in string constant";
  ERROR_HANDLE
}
<STRING>'\"'  {
  BEGIN(INITIAL);
  *string_buf_ptr = '\0';
  cool_yylval.symbol = stringtable.add_string(string_buf);
  return STR_CONST;
}

\n { curr_lineno++; }

\\ {
  cool_yylval.error_msg = "\\ should not appear outside String";
  return ERROR; 
}

. {
  cool_yylval.error_msg = "unexpected error";
  return ERROR; 
}

%%