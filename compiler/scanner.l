%option noyywrap
%x STRING
%x COMMENT
%x SCOMMENT

%{
#include "1605074_SymbolTable.cpp"
//#define YYSTYPE SymbolInfo*
#include "y.tab.h"

int line_count=1;
int errors = 0;
string str = "";
string sToken = "";
int stateStartLine =0;



%}

WHITESPACE [ \t\f\r\v]+
SPECIAL "\n" | "\t" | "\a" | "\f" | "\r" | "\b" | "\v" | "\0"
LETTER [a-zA-Z]
DIGIT [0-9]
NEWLINE \n

%%

{NEWLINE} {line_count++;

					}

"if"	{
			return IF;
		}

"else"	{
			return ELSE;

		}

"for"	{
			return FOR;

		}

"while"	{
			return WHILE;
		}

"do"	{
			return DO;
		}

"break"	{
			return BREAK;
		}

"int"	{
			return INT;
		}

"char"	{
			return CHAR;
		}
"float"	{
			return FLOAT;
		}

"double"	{
			return DOUBLE;
		}

"void"	{
			return VOID;
		}

"return"	{
			return RETURN;
		}

"case"	{
			return CASE;
		}

"switch"	{
			return SWITCH;
		}

"default"	{
			return DEFAULT;
		}

"continue"	{
			return CONTINUE;
		}



"+"		|

"-"		{
			SymbolInfo *s = new SymbolInfo(yytext, "ADDOP");
			yylval = (YYSTYPE) s;
			return ADDOP;
			}



"*"		|

"/"   |

"%"		{
			SymbolInfo *s =  new SymbolInfo(yytext, "MULOP");
			yylval = (YYSTYPE) s;
			return MULOP;
		  }



"++"	|

"--"	{
			SymbolInfo *s = new SymbolInfo(yytext, "INCOP");
			yylval = (YYSTYPE) s;
			return INCOP;
			}

"println" {
			return PRINTLN;
}

"<"			|
"<="    |
">"     |
">="    |
"=="    |
"!="    {
			SymbolInfo *s = new SymbolInfo(yytext, "RELOP");
			yylval = (YYSTYPE) s;
			return RELOP;
			}



"="		{
			return ASSIGNOP;
	  	}



"&&"	|

"||"	{
			SymbolInfo *s = new SymbolInfo(yytext, "LOGICOP");
			yylval = (YYSTYPE) s;
			return LOGICOP;
			}



"&"			|
"|"     |
"^"     |
"<<"    |
">>"    {
			SymbolInfo *s = new SymbolInfo(yytext, "BITOP");
			yylval = (YYSTYPE) s;
			return BITOP;
			}



"!"		{
			return NOT;
			}



"("		{
			return LPAREN;
			}



")"		{
			return RPAREN;
			}



"{"		{
			return LCURL;
			}



"}"		{
			return RCURL;
			}



"["		{
			return LTHIRD;
			}



"]"		{
			return RTHIRD;
			}



","		{
			return COMMA;
			}



";"		{
			return SEMICOLON;
			}




({DIGIT}*\.{DIGIT}+)|(({DIGIT}*\.{DIGIT}+)|{DIGIT}+)E[-+]?{DIGIT}+ {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_FLOAT");
								yylval = (YYSTYPE) s;
								return CONST_FLOAT;

            }

{DIGIT}*\.{DIGIT}*\.[\.0-9]*(E[-+]?{DIGIT}+)?   {
                         fprintf(error,"\nLine no %d: Too many decimal point error \n\n",line_count);
                         errors++;
                        }

{DIGIT}+E  |
{DIGIT}+E[-+]?[0-9\.E]*\.[\.0-9E]* |
{DIGIT}+E[-+]?[0-9\.E]*E[\.0-9E]*  {
                                fprintf(error, "\nLine no %d :  Ill formed number error \n\n", line_count);
                                errors++;

                              }

{DIGIT}+{LETTER}[0-9a-zA-Z]* {
                                fprintf(error,"\nLine no %d: Invalid suffix on numeric constant or invalid prefix on identifier \n\n",line_count);
                                errors++;
                              }





{DIGIT}+ 	{
						SymbolInfo *s = new SymbolInfo(yytext, "CONST_INT");
						yylval = (YYSTYPE) s;
						return CONST_INT;

			}


'([^'\n]|(\\'))*\n {
                fprintf(error, "\nLine no %d:  Unfinished character\n", line_count);
                errors++;
                line_count++;
            }


'.'  				{
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;


            }



(')(\\n)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;

            }


(')(\\t)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            }

(')(\\a)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            }

(')(\\f)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            }

(')(\\r)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            }

(')(\\b)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            }

(')(\\v)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            }

(')(\\0)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            }


(')(\\\\)(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            }


(')(\\)(')(') {
                SymbolInfo *s = new SymbolInfo(yytext, "CONST_CHAR");
							 	yylval = (YYSTYPE) s;
								return CONST_CHAR;
            	}

'..+'   {
            fprintf(error, "\nLine no %d :  Multi character sequence error\n\n", line_count);
            errors++;
        }





({LETTER}|[_])[a-zA-Z0-9_]* {
														SymbolInfo *s = new SymbolInfo(yytext, "ID");
													 	yylval = s;
														return ID;
													}

{WHITESPACE} {

						 }

\"    {
						str="\"";
						stateStartLine = line_count;
            BEGIN(STRING);
      }

<STRING>\" {
								str +="\"";
								SymbolInfo *s = new SymbolInfo(yytext, str.c_str());
							 	yylval = (YYSTYPE) s;
                BEGIN(INITIAL);
								return STRING;
            }

<STRING>\\\" {
								str += "\"";
             }


<STRING>[^\"\n\\"\n""\t""\a""\f""\r""\b""\v""\0""\\""\'"\\]+ {
								str += yytext;
                }

<STRING>\\(\r)?\n    { line_count++;}

<STRING>\n {

                fprintf(error, "\nLine no %d :  Unfinished string \n", stateStartLine);
                errors++;
                line_count++;
                BEGIN(INITIAL);
                //ERROR
            }

<STRING><<EOF>> {
                errors++;
                return 0;
                }


<STRING>\\n {
								str += '\n';
             }

<STRING>\\t {
								str += '\t';
             }

<STRING>\\\\ {
								str += '\\';
             }

<STRING>(\\)(') {
								str += '\'';
             }

<STRING>\\a {
								str += '\a';
             }

<STRING>\\f {
								str += '\f';
             }

<STRING>\\r {
								str += '\r';
             }

<STRING>\\b {
								str += '\b';
             }

<STRING>\\v {
								str += '\v';
            }

<STRING>\\0 {
								str += '\0';
             }

<STRING>\\ 	{
								str += '\\';
						}


"//"    {

            BEGIN(SCOMMENT);
        }

<SCOMMENT>.*(\\(\r)?\n)  {
                    line_count++;
                    }

<SCOMMENT>.*[^\\\n](\r)?\n {
                    line_count++;
                    BEGIN(INITIAL);
                    }




"/*"    {
						str = "/*";
						stateStartLine = line_count;
            BEGIN(COMMENT);
        }



<COMMENT>[^\*\n]*|\*[^/] {
									str += yytext;
                  }


<COMMENT>\n     {
								str += '\n';
                 line_count++;
                }

<COMMENT>"*/"  {
								str += "*/";
								BEGIN(INITIAL);
                }

<COMMENT><<EOF>>    {
                    fprintf(error, "\nLine no %d:  Unfinished comment\n\n", stateStartLine);
                    errors++;
                    return 0;


                    }

.				{
							fprintf(error, "\nLine no %d:  Unrecognized character\n\n", stateStartLine);
							errors++;
				}

%%
