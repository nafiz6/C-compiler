%{


#include<iostream>
#include<cstdlib>
#include<cstring>
#include<cmath>
#include "1605074_SymbolTable.cpp"
#include<vector>

#include <sstream>

using namespace std;

int yyparse(void);
int yylex(void);


//FILE* logout;= fopen("log.txt","w");
FILE* error = fopen("log.txt","w");
FILE* code = fopen("code.asm","w");
FILE* codeOptimized = fopen("optimized-code.asm","w");

extern FILE *yyin;
extern int line_count;

SymbolTable *table = new SymbolTable();


int error_count=0;

int uniqueId=1;
int buckets=10;

int labelCount=0;
int tempCount=0;
int maxParam=0;



vector<SymbolInfo*> variables;
vector<SymbolInfo*> nontempvariables;

char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	SymbolInfo *si = new SymbolInfo(t, "temp");
	variables.push_back(si);
	return t;
}

char *newParam(int i)
{
	char *t= new char[4];
	strcpy(t,"param");
	char b[3];
	sprintf(b,"%d", i);
	strcat(t,b);
	return t;
}

string declaration_type;
string return_type;
string currFunc;
vector<string > parameter_list;
vector<string > parameter_list_tempName;
vector<string > parameter_list_type;
vector<SymbolInfo* > functions_list;



void yyerror(char *s)
{
	fprintf(error, "\nError at line no %d: %s\n\n", line_count, s);
	parameter_list.clear();
	parameter_list_type.clear();
	error_count++;
}


%}
%define api.value.type {SymbolInfo*}

%token IF ELSE FOR WHILE DO BREAK;
%token INT CHAR FLOAT DOUBLE
%token VOID RETURN CASE SWITCH DEFAULT CONTINUE
%token ADDOP MULOP INCOP RELOP ASSIGNOP LOGICOP BITOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON PRINTLN
%token CONST_FLOAT	CONST_INT CONST_CHAR ID STRING

%left ADDOP
%left MULOP
%right ASSIGNOP

%nonassoc INCOP NOT
%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE



%%

start : program{
		table->printCurr();
		fprintf(error, "\n Total Lines: %d\n\n", line_count);
		fprintf(error, "\nTotal Errors: %d", error_count);
//		fprintf(logout, "\nTotal Errors: %d", error_count);

		$$->code = ".MODEL SMALL\n";
		$$->code += ".STACK 100H\n";
		$$->code += ".DATA\n";

		$$->code+="returnTemp DW ?\n";

		//FOR
		for (int i=0;i<variables.size();i++){
			if (variables[i]->getArrSize()==-1){
				$$->code+=variables[i]->symbol + " DW ?\n";
			}
			else{
				char b[3];
				sprintf(b,"%d", variables[i]->getArrSize());
				$$->code+=variables[i]->symbol + " DW " + string(b) + " DUP (?)\n";
			}
		}

		for (int i=1;i<=maxParam;i++){
			$$->code+=string(newParam(i)) + " DW ?\n";
		}


		$$->code += ".CODE\n\
MAIN PROC\n\
;init ds\n\
mov ax, @DATA\n\
mov ds, ax\n\n";
		for (int i=0;i<functions_list.size();i++){
			if (functions_list[i]->getName()=="main")$$->code+= functions_list[i]->code;
		}
		$$->code+= "MOV AH, 4CH\n\
INT 21H\n\
MAIN ENDP\n";

//PROC HERE
for (int i=0;i<functions_list.size();i++){
	if (functions_list[i]->getName()=="main")continue;
	$$->code+= functions_list[i]->getName() + " PROC\n";
	$$->code+= functions_list[i]->code;
	$$->code+= "ret\n";
	$$->code+= functions_list[i]->getName() + " ENDP\n";
}

//PRIINT


$$->code+= "PROC print\n\
MOV BX, 10\n\
CMP AX, 0\n\
JGE NOTNEGATIVE\n\
NEG AX\n\
MOV CX, AX\n\
MOV DL, '-'\n\
MOV AH, 2\n\
INT 21H\n\
MOV AX, CX\n\
NOTNEGATIVE:\n\
MOV CX, 0\n\
CMP AX, 0\n\
JNE PUSHREM\n\
MOV AH, 2\n\
MOV DL, '0'\n\
INT 21H\n\
JMP PRINTEND\n\
PUSHREM:\n\
MOV DX, 0\n\
DIV BX\n\
PUSH DX\n\
INC CX\n\
CMP AX, 0\n\
JNE PUSHREM\n\
PRINTREM:\n\
POP DX\n\
ADD DL, '0'\n\
MOV AH, 2\n\
INT 21H\n\
LOOP PRINTREM\n\
PRINTEND:\n\
MOV dl, 10\n\
MOV ah, 02h\n\
INT 21h\n\
MOV dl, 13\n\
MOV ah, 02h\n\
INT 21h\n\
ret\n\
PRINT ENDP\n";

$$->code+="END MAIN\n";

//OPTIMIZEE


std::stringstream ss($$->code);
std::string lines;
std::vector<std::string> splittedStrings;
while (std::getline(ss, lines, '\n'))
{
 	splittedStrings.push_back(lines);
}

vector<int> indexToDelete;



string optimizedCode="";


for (int i=0;i<splittedStrings.size()-1;i++){
	string line1 = splittedStrings[i];
	string line2 = splittedStrings[i+1];
	if (line1.substr(0,3)=="mov" && line2.substr(0,3)=="mov"){
		i++;
		int commaPos=0;
		for ( std::string::iterator it=line1.begin(); it!=line1.end(); ++it){
			if (*it==',')break;
			commaPos++;
		}
		string d1,s1,d2,s2;
		d1= line1.substr(4,commaPos-4);
		s1= line1.substr(commaPos+2, line1.length()-commaPos);
		commaPos=0;
		for ( std::string::iterator it=line2.begin(); it!=line2.end(); ++it){
			if (*it==',')break;
			commaPos++;
		}

		d2= line2.substr(4,commaPos-4);
		s2= line2.substr(commaPos+2, line1.length()-commaPos);
		if (s1==d2 && d1==s2){
			indexToDelete.push_back(i+1);
			optimizedCode+=line1+"\n";
		}
		else{
			optimizedCode+=line1+"\n";
			optimizedCode+=line2+"\n";
		}


	}
	else{
		optimizedCode+=line1+ "\n";

	}
}

fprintf(codeOptimized, optimizedCode.c_str());

fprintf(code, $$->code.c_str());
	}
	;

program : program unit {
		//fprintf(logout, "At line no: %d program : program unit\n", line_count);
		string str = $1->getName().c_str();
		str+= "\n";
		str+= $2->getName().c_str();
		$$ = new SymbolInfo(str, "program");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		$$->code = $1->code + $2->code;

	}
	| unit  {//fprintf(logout, "At line no: %d program : unit\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());
	}
	;

unit : var_declaration {
		//fprintf(logout, "At line no: %d unit : var_declaration\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());
	}
    | func_declaration {
		//fprintf(logout, "At line no: %d unit : func_declaration\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());
	}
    | func_definition {
		//fprintf(logout, "At line no: %d unit : func_definition\n", line_count);
	 	//fprintf(logout, "\n%s\n\n", $1->getName().c_str());
	}
	| error SEMICOLON {
		$$ = new SymbolInfo("","");
	}
	;

func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON {
		//fprintf(logout, "At line no: %d func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON\n", line_count);
		if (table->insert($2->getName().c_str(), "ID")){
			SymbolInfo *si = table->lookup($2->getName().c_str());
			si->setFunc();
			si->setVarType($1->getName().c_str());
			for (int i=0; i<parameter_list_type.size(); i++){
				si->paramsType.push_back(parameter_list_type[i]);
			}
		}
		else{
			fprintf(error, "\nError at line %d: ID previously declared\n\n", line_count);
			error_count++;
		}
		parameter_list.clear();
		parameter_list_type.clear();

		string str = $1->getName().c_str();
		str+= " ";
		str+= $2->getName().c_str();
		str+= " (";
		str+= $4->getName().c_str();
		str+= ");";
		$$ = new SymbolInfo(str, "func_declaration");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON {
		//fprintf(logout, "At line no: %d func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON\n", line_count);
		if (table->insert($2->getName().c_str(), "ID")){
			SymbolInfo *si = table->lookup($2->getName().c_str());
			si->setFunc();
			si->setVarType($1->getName().c_str());
		}
		else{
			fprintf(error, "\nError at line %d: ID previously declared\n\n", line_count);
			error_count++;
		}

		string str = $1->getName().c_str();
		str+= " ";
		str+= $2->getName().c_str();
		str+= "();";
		$$ = new SymbolInfo(str, "func_declaration");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
	}
	;

func_definition : type_specifier ID LPAREN parameter_list RPAREN {
		SymbolInfo *si = table->lookup($2->getName().c_str());
		if (si==NULL){
			table->insert($2->getName().c_str(), "ID");
			si = table->lookup($2->getName().c_str());
			si->setFunc();
			si->setDef();
			si->setVarType($1->getName().c_str());
			for (int i=0; i<parameter_list_type.size(); i++){
				si->paramsType.push_back(parameter_list_type[i]);
			}
		}
		else if (!si->isFunc() || si->isDefined()){
			fprintf(error, "\nError at line %d: Function ID previously defined\n\n",line_count);
			error_count++;
		}
		else if (parameter_list_type.size()!=si->paramsType.size()){
			fprintf(error, "\nError at line %d: Invalid number of arguments\n\n", line_count);
			error_count++;
		}
		else if (si->getVarType()!=$1->getName()){
			fprintf(error, "\nError at line %d: Invalid return type\n\n", line_count);
			error_count++;
		}
		else {
			bool err=false;
			int sz = parameter_list_type.size();
			for (int i=0;i<sz;i++){
				if (parameter_list_type[i]!=si->paramsType[i]){
					err=true;
				}
			}
			if (err){
				fprintf(error, "\nError at line %d: Invalid argument type\n\n", line_count);
				error_count++;
			}
			else{
				si->setDef();

			}
		}
		return_type = $1->getName().c_str();
		currFunc = $2->getName().c_str();
	} compound_statement {
		//fprintf(logout, "At line no: %d func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement\n", line_count);

		string str = $1->getName().c_str();
		str+= " ";
		str+= $2->getName().c_str();
		str+= "(";
		str+= $4->getName().c_str();
		str+= ")\n";
		str+= $7->getName().c_str();
		$$ = new SymbolInfo(str, "func_declaration");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());


		$$->code = $7->code;
		SymbolInfo* si = new SymbolInfo($2->getName(), "func");
		si->code = $7->code;
		functions_list.push_back(si);

	}
	| type_specifier ID LPAREN RPAREN {
		SymbolInfo *si = table->lookup($2->getName().c_str());
		if (si==NULL){
				table->insert($2->getName().c_str(), "ID");
				si = table->lookup($2->getName().c_str());
				si->setFunc();
				si->setDef();
				si->setVarType($1->getName().c_str());
		}
		else if (si->isDefined()){
				fprintf(error, "\nError at line %d: Function ID previously defined\n\n",line_count);
				error_count++;
		}
		else if (si->paramsType.size()!=0){
				fprintf(error, "\nError at line %d: Invalid number of arguments\n\n", line_count);
				error_count++;
		}
		else if (si->getVarType()!=$1->getName()){
				fprintf(error, "\nError at line %d: Invalid return type\n\n", line_count);
				error_count++;
		}
		else{
				si->setDef();
		}

		return_type = $1->getName().c_str();
		currFunc = $2->getName().c_str();
	} compound_statement {//fprintf(logout, "At line no: %d func_definition : type_specifier ID LPAREN RPAREN compound_statement\n", line_count);
		string str = $1->getName().c_str();
		str+= " ";
		str+= $2->getName().c_str();
		str+= "()";
		str+= $6->getName().c_str();
		$$ = new SymbolInfo(str, "func_declaration");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		$$->code = $6->code;
		SymbolInfo* si = new SymbolInfo($2->getName(), "func");
		si->code = $6->code;
		functions_list.push_back(si);

	}
	;


parameter_list  : parameter_list COMMA type_specifier ID {
		//fprintf(logout, "At line no: %d parameter_list  : parameter_list COMMA type_specifier ID\n ", line_count);
		parameter_list.push_back($4->getName().c_str());
		parameter_list_type.push_back($3->getName().c_str());
		string str = $1->getName().c_str();
		str+= ", ";
		str+= $3->getName().c_str();
		str+=" ";
		str+= $4->getName().c_str();
		$$ = new SymbolInfo(str, "parameter_list");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
	}
	| parameter_list COMMA type_specifier {
		//fprintf(logout, "At line no: %d parameter_list  : parameter_list COMMA type_specifier\n ", line_count);
		parameter_list_type.push_back($3->getName().c_str());
		string str = $1->getName().c_str();
		str+= ", ";
		str+= $3->getName().c_str();
		$$ = new SymbolInfo(str, "parameter_list");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
	}
 	| type_specifier ID {//fprintf(logout, "At line no: %d parameter_list  : type_specifier ID\n", line_count);
		parameter_list.push_back($2->getName().c_str());
		parameter_list_type.push_back($1->getName().c_str());
		string str = $1->getName().c_str();
		str += " ";
		str+= $2->getName().c_str();
		$$ = new SymbolInfo(str, "parameter_list");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());


	}
	| type_specifier {
		parameter_list_type.push_back($1->getName().c_str());
		//fprintf(logout, "At line no: %d parameter_list  : type_specifier\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());

		//WHAT TO DO FOR PARAMS
	}
 	;


compound_statement : LCURL {
		table->enterScope();
		for (int i=0; i<parameter_list_type.size();i++){
			table->insert(parameter_list[i], "ID");
			SymbolInfo *si = table->lookup(parameter_list[i]);
			si->setVarType(parameter_list_type[i]);

			if (i+1>maxParam)maxParam++;
			string p = newParam(i+1);
			si->symbol = p;

		}
		parameter_list.clear();
		parameter_list_type.clear();

	} statements RCURL {

		//fprintf(logout, "At line no: %d compound_statement : LCURL statements RCURL\n", line_count);
		string str = "{\n";
		str+= $3->getName().c_str();
		str+= "\n}";
		$$ = new SymbolInfo(str, "compound_statement");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		table->printAll();
		table->exitScope();

		$$->code = $3->code;



	}
 	| LCURL RCURL {
		//fprintf(logout, "At line no: %d compound_statement : LCURL RCURL\n", line_count);
		//fprintf(logout, "\n{ }\n\n");
		$$ = new SymbolInfo("{ }\n", "");
	}

 	;

var_declaration : type_specifier declaration_list SEMICOLON {
		//fprintf(logout, "At line no: %d var_declaration : type_specifier declaration_list SEMICOLON\n", line_count);
		string str = $1->getName().c_str();
		str+=" ";
		str+= $2->getName().c_str();
		str+=";";
		$$ = new SymbolInfo( str, "var_declaration");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());

		$$->code = $2->code;

	}
 	;

type_specifier	: INT  {
		//fprintf(logout, "At line no: %d type_specifier : INT\n", line_count);
		$$ = new SymbolInfo("int", "INT");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		declaration_type = "int";
	}
 	| FLOAT	{//fprintf(logout, "At line no: %d type_specifier : FLOAT\n", line_count);
		$$ = new SymbolInfo("float", "FLOAT");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		declaration_type = "float";
	}
 	| VOID {//fprintf(logout, "At line no: %d type_specifier : VOID\n", line_count);
		$$ = new SymbolInfo("void", "VOID");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		declaration_type = "void";
	}
 	;

declaration_list : declaration_list COMMA ID {
		if (table->currScopeTable->lookup($3->getName().c_str())==NULL){
			table->insert($3->getName().c_str(), "ID" );
			SymbolInfo* si = table->lookup($3->getName().c_str());
			si->setVarType(declaration_type.c_str());


			char b[3];
			sprintf(b,"%d", table->currScopeTable->uid);

			si->symbol = $3->getName()+"_" + string(b);
			SymbolInfo* sym = new SymbolInfo(si->symbol, "ID" );
			variables.push_back(sym);
			nontempvariables.push_back(sym);
	}
		else{
			fprintf(error, "\nError at line no %d: Variable has been declared previously\n\n", line_count);
			error_count++;
		}
		//fprintf(logout, "At line no: %d declaration_list : declaration_list COMMA ID\n", line_count);

		string str = $1->getName().c_str();
		str+= ", ";
		str+= $3->getName().c_str();
		$$ = new SymbolInfo(str, "declaration_list");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());


		//DONE
	}
 	| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD {
		if (table->currScopeTable->lookup($3->getName().c_str())==NULL){
			table->insert($3->getName().c_str(), "ID");
			SymbolInfo* si = table->lookup($3->getName().c_str());
			si->setVarType(declaration_type.c_str());
			si->setArrSize(atoi($5->getName().c_str()));

			char b[3];
			sprintf(b,"%d", table->currScopeTable->uid);

			si->symbol = $3->getName()+"_" + string(b);
			SymbolInfo* sym = new SymbolInfo(si->symbol, "ID" );

			sym->setArrSize(atoi($5->getName().c_str()));
			variables.push_back(sym);
			nontempvariables.push_back(sym);

		}
		else{
			fprintf(error, "\nError at line no %d: Variable has been declared previously\n\n", line_count);
			error_count++;
		}

		//fprintf(logout, "At line no: %d declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD\n", line_count);

		string str = $1->getName().c_str();
		str+= ", ";
		str+= $3->getName().c_str();
		str+= "[";
		str+= $5->getName().c_str();
		str+= "]";
		$$ = new SymbolInfo(str, "declaration_list");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



		//DONE
	}
 	| ID {
		if (table->currScopeTable->lookup($1->getName().c_str())==NULL){
			table->insert($1->getName().c_str(), "ID" );
			SymbolInfo* si = table->lookup($1->getName().c_str());
			si->setVarType(declaration_type.c_str());
			char b[3];
			sprintf(b,"%d", table->currScopeTable->uid);

			si->symbol = $1->getName()+"_" + string(b);
			SymbolInfo* sym = new SymbolInfo(si->symbol, "ID" );


			variables.push_back(sym);
			nontempvariables.push_back(sym);

		}
		else{
			fprintf(error, "\nError at line no %d: Variable has been declared previously\n\n", line_count);
			error_count++;
		}
			//fprintf(logout, "At line no: %d declaration_list : ID\n", line_count);
			//fprintf(logout, "\n%s\n\n", $1->getName().c_str());



			//DONE
	}
 	| ID LTHIRD CONST_INT RTHIRD {
		if (table->currScopeTable->lookup($1->getName().c_str())==NULL){
			table->insert($1->getName().c_str(), "ID");
			SymbolInfo* si = table->lookup($1->getName().c_str());
			si->setVarType(declaration_type.c_str());
			si->setArrSize(atoi($3->getName().c_str()));

			char b[3];
			sprintf(b,"%d", table->currScopeTable->uid);

			si->symbol = $1->getName()+"_" + string(b);
			SymbolInfo* sym = new SymbolInfo(si->symbol, "ID" );

			sym->setArrSize(atoi($3->getName().c_str()));
			variables.push_back(sym);
			nontempvariables.push_back(sym);
		}
		else{
			fprintf(error, "\nError at line no %d: Variable has been declared previously\n\n", line_count);
			error_count++;
		}

		//fprintf(logout, "At line no: %d declaration_list : ID LTHIRD CONST_INT RTHIRD\n", line_count);
		string str = $1->getName().c_str();
		str+= "[";
		str+= $3->getName().c_str();
		str+= "]";
		$$ = new SymbolInfo(str, "declaration_list");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());

		//DONE
	}
 	;

statements : statement {
		//fprintf(logout, "At line no: %d statements : statement\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());
		$$ = new SymbolInfo($1->getName().c_str(), "statement");



		$$->code = $1->code;
		$$->symbol = $1->symbol;

		//DONE
	}
	| statements statement {
		//fprintf(logout, "At line no: %d statements : statements statement\n", line_count);
	 	string str = $1->getName().c_str();
	 	str+= "\n";
	 	str+= $2->getName().c_str();
	 	$$ = new SymbolInfo(str, "parameter_list");
	 	//fprintf(logout, "\n%s\n\n", $$->getName().c_str());


		$$->code = $1->code + $2->code;
		$$->symbol = $1->symbol;

		//DONE
	}
	   ;

statement : var_declaration  {
		//fprintf(logout, "At line no: %d statement : var_declaration\n", line_count);
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());

		$$ = $1;
		$$->code = "";
		$$->symbol = $1->symbol;

		//DONE
	}
	| expression_statement {
		//fprintf(logout, "At line no: %d statement : expression_statement\n", line_count);
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



		$$->code = $1->code;
		$$->symbol = $1->symbol;

		//DONE
	}
	| compound_statement {
		//fprintf(logout, "At line no: %d statement : compound_statement\n", line_count);
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		$$=$1;

		$$->code = $1->code;
		$$->symbol = $1->symbol;

		//DONE


	}
	| FOR LPAREN expression_statement expression_statement expression RPAREN statement	{
		//fprintf(logout, "At line no: %d statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement\n", line_count);
		string str = "for ( ";
		str += $3->getName().c_str();
		str+= " ";
		str+= $4->getName().c_str();
		str+= " ";
		str+= $5->getName().c_str();
		str+= " ) ";
		str+= $7->getName().c_str();
		$$ = new SymbolInfo(str, "statement");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());


		$$->code+=$3->code;
		char *label1=newLabel();
		char *label2=newLabel();
		$$->code+= string(label1) + ":\n";
		$$->code+=$4->code;
		$$->code+= "mov ax, " + $4->symbol+"\n";
		$$->code+= "cmp ax, 0\n";
		$$->code+= "je " + string(label2)+ "\n";
		$$->code+=$7->code;
		$$->code+=$5->code;
		$$->code+="jmp " + string(label1) + "\n";
		$$->code+= string(label2) + ":\n";

		//DONE


 	}
	| IF LPAREN expression RPAREN statement  %prec LOWER_THAN_ELSE{
		//fprintf(logout, "At line no: %d statement : IF LPAREN expression RPAREN statement\n", line_count);
		string str = "if ( ";
		str += $3->getName().c_str();
		str+= " ) ";
		str+= $5->getName().c_str();
		$$ = new SymbolInfo(str, "statement");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



		$$->code = $3->code;
		char *label=newLabel();
		$$->code+="mov ax, "+$3->symbol+"\n";
		$$->code+="cmp ax, 0\n";
		$$->code+="je "+string(label)+"\n";
		$$->code+=$5->code;
		$$->code+=string(label)+":\n";

		$$->symbol="if";

		//DONE
	}
	| IF LPAREN expression RPAREN statement ELSE statement {
		//fprintf(logout, "At line no: %d statement : IF LPAREN expression RPAREN statement ELSE statement\n", line_count);
		string str = "if ( ";
		str += $3->getName().c_str();
		str+= " ) ";
		str+= $5->getName().c_str();
		str+= " else ";
		str+= $7->getName().c_str();
		$$ = new SymbolInfo(str, "statement");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



		$$->code = $3->code;
		char *label1=newLabel();	//else
		char *label2=newLabel();	//end
		$$->code+="mov ax, "+$3->symbol+"\n";
		$$->code+="cmp ax, 0\n";
		$$->code+="je "+string(label1)+"\n";   //expression is false, goto else
		$$->code+=$5->code;
		$$->code+="jmp " + string(label2) + "\n";  //skip to end to not execute else part
		$$->code+=string(label1)+":\n";
		$$->code+=$7->code;		//else code
		$$->code+=string(label2)+":\n";

		$$->symbol="if";


		//DONE

	 }
	| WHILE LPAREN expression RPAREN statement {
		//fprintf(logout, "At line no: %d statement : WHILE LPAREN expression RPAREN statement\n", line_count);
		string str = "while ( ";
		str += $3->getName().c_str();
		str+= " ) ";
		str+= $5->getName().c_str();
		$$ = new SymbolInfo(str, "statement");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



		char *label1=newLabel();
		char *label2=newLabel();
		$$->code += string(label1) + ":\n";
		$$->code+=$3->code;
		$$->code += "mov ax, " + $3->symbol+"\n";
		$$->code+= "cmp ax, 0\n";
		$$->code += "je " + string(label2) + "\n";
		$$->code+= $5->code;
		$$->code+= "jmp " + string(label1) + "\n";
		$$->code += string(label2) + ":\n";

		//DONE


	 }
	| PRINTLN LPAREN ID RPAREN SEMICOLON {
		//fprintf(logout, "At line no: %d statement : PRINTLN LPAREN ID RPAREN SEMICOLON\n", line_count);
		if (table->lookup($3->getName().c_str())==NULL){
			fprintf(error, "\nError at line %d: Variable not declared\n\n", line_count);
			error_count++;
		}

		string str = "println(";
		str += $3->getName().c_str();
		str+= ");";
		$$ = new SymbolInfo(str, "statement");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());

		SymbolInfo* si = table->lookup($3->getName());
	//	$$->code = (string)println($3->symbol);

		$$->code += "push ax\n";
		$$->code += "push bx\n";
		$$->code += "push cx\n";
		$$->code += "push dx\n";
		$$->code += "mov ax, " + si->symbol + "\n";
		$$->code += "call print\n";
		$$->code += "pop dx\n";
		$$->code += "pop cx\n";
		$$->code += "pop bx\n";
		$$->code += "pop ax\n";

		//DO LATER

	}
	| RETURN expression SEMICOLON {
		//fprintf(logout, "At line no: %d statement : RETURN expression SEMICOLON\n", line_count);
		string str = "return ";
		str += $2->getName().c_str();
		str+= ";";
		$$ = new SymbolInfo(str, "statement");

		if ($2->getVarType()!=return_type && !($1->getVarType()=="float" && $3->getVarType()=="int")){
			fprintf(error, "\nError at line %d: Return type mismatch\n\n",line_count);
			error_count++;
		}
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		$$->code += $2->code;
		$$->code+= "mov ax, " + $2->symbol + "\n";
		$$->code+= "mov returnTemp, ax\n";
		if (currFunc!="main"){
		$$->code+= "ret\n";
	}




 	}
	| error SEMICOLON {
		$$ = new SymbolInfo("","");
	}
	;

expression_statement : SEMICOLON {
		//fprintf(logout, "At line no: %d expression_statement : SEMICOLON\n", line_count);
		$$ = new SymbolInfo(";", "statement");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());


		$$->code = "";

		//DONE

	}
	| expression SEMICOLON {
		//fprintf(logout, "At line no: %d expression_statement : expression SEMICOLON\n", line_count);
		string str = $1->getName().c_str();
		str+= ";";
		$$ = new SymbolInfo(str, "expression_statement");
		$$->setVarType($1->getVarType().c_str());
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



		$$->code = $1->code;
		$$->symbol = $1->symbol;

		//DONE

 	}
	;


variable : ID	{
		//fprintf(logout, "At line no: %d variable : ID\n", line_count);
		$$=table->lookup($1->getName().c_str());
		if ($$==NULL){
			fprintf(error, "\nError at line %d: Variable not declared\n\n", line_count);
 			error_count++;
			$$=$1;
		 	$$->setVarType("null");

		}
		else if ($$->getArrSize()!=-1){
		 	fprintf(error, "\nError at line %d: Array needs index\n\n", line_count);
 			error_count++;
		}

		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());


		//??
	}
	| ID LTHIRD expression RTHIRD {
		//fprintf(logout, "At line no: %d variable : ID LTHIRD expression RTHIRD\n", line_count);
		string str = $1->getName().c_str();
	 	str+= "[";
	 	str+= $3->getName().c_str();
	 	str+= "]";
	 	$$ = new SymbolInfo(str, "variable");
		SymbolInfo* si = table->lookup($1->getName().c_str());
		if (si==NULL){
		 	fprintf(error, "Error at line %d: Variable not declared", line_count);
			error_count++;
		}
		else{
			$$->setVarType(si->getVarType());
			$$->setArrSize(si->getArrSize());
			if ($$->getArrSize()==-1){
			 	fprintf(error, "\nError at line %d: Variable cannot have an index\n\n", line_count);
	 			error_count++;
			}
		}
		if ($3->getVarType()!="int"){
			fprintf(error, "\nError at line no %d: Array index must be an int\n\n", line_count);
	 		error_count++;
	 	}
	 //	fprintf(logout, "\n%s\n\n", $$->getName().c_str());


		$$->symbol=si->symbol;
		$$->code+=$3->code + "mov bx, " + $3->symbol + "\nadd bx, bx\n";

		//WHAT TO DO WITH ARRAY
 	}
	;

 expression : logic_expression  {
	 //	fprintf(logout, "At line no: %d expression : logic_expression\n", line_count);
 	//	fprintf(logout, "\n%s\n\n", $1->getName().c_str());


		$$=$1;
		$$->code = $1->code;
		$$->symbol = $1->symbol;

		//DONE
	}
    | variable ASSIGNOP logic_expression {//fprintf(logout, "At line no: %d expression : variable ASSIGNOP logic_expression\n", line_count);
		string str = $1->getName().c_str();
		string vartype = $1->getVarType().c_str();
		str+= " = ";
  		str+= $3->getName().c_str();
  		$$ = new SymbolInfo(str, "expression");

		if ($1->getVarType() != $3->getVarType() && $1->getVarType()!="null"){

			if (!($1->getVarType()=="float" && $3->getVarType()=="int")){

				fprintf(error, "\nError at line no %d: Type mismatch\n\n", line_count);
				error_count++;
			}
		}
		if ($1->getVarType()== "void" || $3->getVarType()=="void"){
		 	fprintf(error, "\nError at line no %d: Void function cannot be part of expression\n\n", line_count);
			error_count++;
		}


		$$->code = $3->code + $1->code;
		$$->symbol = $1->symbol;
		$$->code += "mov ax, " + $3->symbol + "\n";
		if ($1->getArrSize()==-1){		//NOT ARRAY
			$$->code += "mov " + $1->symbol + ", ax\n";
		}
		else{
			$$->code+= "mov " + $1->symbol+"[bx], ax\n";
			char *temp=newTemp();
			$$->code+="mov "+string(temp) + ", ax\n";
			$$->symbol = temp;
			//WHAT TO DO WITH ARRAY ASSIGNOP
		}


//  		fprintf(logout, "\n%s\n\n", $$->getName().c_str());


  	}
	;

logic_expression : rel_expression {
		//fprintf(logout, "At line no: %d logic_expression : rel_expression\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());



		$$->code = $1->code;
		$$->symbol = $1->symbol;

		//DONE
	}
	| rel_expression LOGICOP rel_expression {
		//fprintf(logout, "At line no: %d logic_expression : rel_expression LOGICOP rel_expression\n", line_count);

		string str = $1->getName().c_str();
  		str+= " ";
  		str+= $2->getName().c_str();
  		str+= " ";
  		str+= $3->getName().c_str();
  		$$ = new SymbolInfo(str, "logic_expression");
		$$->setVarType("int");
		if ($1->getVarType()== "void" || $3->getVarType()=="void"){
		 	fprintf(error, "\nError at line no %d: Void function cannot be part of expression\n\n", line_count);
			error_count++;
		}

  		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



		$$->code = $1->code + $3->code;

		char* temp = newTemp();
		char* label1 = newLabel();		// &&Didnt match ||matched
		char* label2 = newLabel();		//end


		if ($2->symbol=="&&"){
			$$->code += "mov ax, " + $1->symbol + "\n";
			$$->code += "cmp ax, 1\n";
			$$->code += "jne " + string(label1) + "\n";  //jump if $1 zero

			$$->code += "mov ax, " + $3->symbol + "\n";
			$$->code += "cmp ax, 1\n";
			$$->code += "jne " + string(label1) + "\n";  //jmp if $3 zero

			$$->code += "mov " + string(temp) + ", 1\n";		//both 1
			$$->code += "jmp " + string(label2) + "\n";

			$$->code+= string(label1) + ":\nmov " + string(temp) + ", 0\n";
			$$->code+= string(label2) + ":\n";
			$$->symbol = temp;



		}
		else if ($2->symbol=="||"){

			$$->code += "mov ax, " + $1->symbol + "\n";
			$$->code += "cmp ax, 1\n";
			$$->code += "je " + string(label1) + "\n";  //jump if $1 one

			$$->code += "mov ax, " + $3->symbol + "\n";
			$$->code += "cmp ax, 1\n";
			$$->code += "je " + string(label1) + "\n";  //jmp if $3 one

			$$->code += "mov " + string(temp) + ", 0\n";		//both 0
			$$->code += "jmp " + string(label2) + "\n";

			$$->code+= string(label1) + ":\nmov " + string(temp) + ", 1\n";
			$$->code+= string(label2) + ":\n";
			$$->symbol = temp;


		}

		//DONE
  	}
	;

rel_expression	: simple_expression  {
		//fprintf(logout, "At line no: %d rel_expression : simple_expression\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());


		$$->code = $1->code;
		$$->symbol = $1->symbol;

		//DONE
	}
	| simple_expression RELOP simple_expression {
	//	fprintf(logout, "At line no: %d rel_expression : simple_expression RELOP simple_expression\n", line_count);
		string str = $1->getName().c_str();
		str+= " ";
		str+= $2->getName().c_str();
		str+= " ";
		str+= $3->getName().c_str();
		$$ = new SymbolInfo(str, "rel_expression");
		$$->setVarType("int");
		if ($1->getVarType() == "void" || $3->getVarType()=="void"){
			fprintf(error, "\nError at line no %d: Void function cannot be part of expression\n\n", line_count);
			error_count++;
		}

		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



		$$->code = $1->code + $3->code;
		$$->code+="mov ax, " + $1->symbol+"\n";
		$$->code+="cmp ax, " + $3->symbol+"\n";
		char *temp=newTemp();
		char *label1=newLabel();
		char *label2=newLabel();
		if($2->symbol=="<"){
			$$->code+="jl " + string(label1)+"\n";
		}
		else if($2->symbol=="<="){
			$$->code+="jle " + string(label1)+"\n";
		}
		else if($2->symbol==">"){
			$$->code+="jg " + string(label1)+"\n";
		}
		else if($2->symbol==">="){
			$$->code+="jge " + string(label1)+"\n";
		}
		else if($2->symbol=="=="){
			$$->code+="je " + string(label1)+"\n";
		}
		else{
			$$->code+="jne " + string(label1)+"\n";
		}

		$$->code+="mov "+string(temp) +", 0\n";
		$$->code+="jmp "+string(label2) +"\n";
		$$->code+=string(label1)+":\nmov "+string(temp)+", 1\n";
		$$->code+=string(label2)+":\n";
		$$->symbol=temp;

		//DONE

	}
	;

simple_expression : term	{
		//fprintf(logout, "At line no: %d simple_expression : term\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());

		$$=$1;

		$$->code = $1->code;
		$$->symbol = $1->symbol;
		//DONE
}
	| simple_expression ADDOP term {
		//fprintf(logout, "At line no: %d simple_expression : simple_expression ADDOP term\n", line_count);
		string str = $1->getName().c_str();
		str+= " ";
		str+= $2->getName().c_str();
		str+= " ";
		str+= $3->getName().c_str();
		$$ = new SymbolInfo(str, "simple_expression");
		if ($1->getVarType()=="float" || $3->getVarType()=="float"){
			$$->setVarType("float");
		}
		else{
			$$->setVarType($1->getVarType().c_str());
		}

		if ($1->getVarType() == "void" || $3->getVarType()=="void"){
		 	fprintf(error, "\nError at line no %d: Void function cannot be part of expression\n\n", line_count);
			error_count++;
		}
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());

		$$->code = $1->code + $3->code;
		$$->code += "mov ax, " + $1->symbol + "\n";
		if ($2->symbol=="-"){
			$$->code += "sub ax, " + $3->symbol + "\n";

		}
		else{
			$$->code += "add ax, " + $3->symbol + "\n";

		}
		char * temp = newTemp();
		$$->code += "mov " + string(temp) + ", ax" + "\n";
		$$->symbol = temp;

		//DONE

	}
	;

term :	unary_expression {
		//fprintf(logout, "At line no: %d term : unary_expressions\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());
		$$=$1;

		$$->code = $1->code;
		$$->symbol = $1->symbol;

		//DONE
	}
    | term MULOP unary_expression { //fprintf(logout, "At line no: %d term : term MULOP unary_expression\n", line_count);
		string str = $1->getName().c_str();
		str+= " ";
		str+= $2->getName().c_str();
		str+= " ";
		str+= $3->getName().c_str();
		$$ = new SymbolInfo(str, "term");
		$$->setVarType($1->getVarType().c_str());
		if ($1->getVarType()=="float" || $3->getVarType()=="float"){
			$$->setVarType("float");
		}
		else{
		 	$$->setVarType($1->getVarType().c_str());
		}
		if ($2->getName()=="%" && ($1->getVarType()!="int" || $3->getVarType()!="int")){
		 	$$->setVarType("int");
			fprintf(error, "\nError at line no %d: Both operands of modulus must be integer\n\n", line_count);
 			error_count++;
		}
		if ($1->getVarType().c_str() == "void" || $3->getVarType().c_str()=="void"){
			fprintf(error, "\nError at line no %d: Void function cannot be part of expression\n\n", line_count);
			error_count++;
		}

		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());


		$$->code = $1->code + $3->code;
		$$->code += "mov ax, " + $1->symbol+"\n";
		$$->code += "mov bx, " + $3->symbol + "\n";
		char *temp=newTemp();
		if($2->symbol=="*"){
			$$->code += "mul bx\n";
			$$->code += "mov "+ string(temp) + ", ax\n";
		}
		else if($2->symbol=="/"){
			// clear dx, perform 'div bx' and mov ax to temp
			$$->code+= "mov dx, 0\n";
			$$->code += "div bx\n";
			$$->code += "mov "+ string(temp) + ", ax\n";


		}
		else{
			// clear dx, perform 'div bx' and mov dx to temp
			$$->code+= "mov dx, 0\n";
			$$->code += "div bx\n";
			$$->code += "mov "+ string(temp) + ", dx\n";

		}

		$$->symbol = temp;

		//DONE  IDIV? IMUL?

	}
    ;

unary_expression : ADDOP unary_expression {
		//fprintf(logout, "At line no: %d unary_expression : ADDOP unary_expression\n", line_count);
		string str = $1->getName().c_str();
		str+= $2->getName().c_str();
		$$ = new SymbolInfo(str, "unary_expression");
		$$->setVarType($2->getVarType().c_str());
		if ($$->getVarType().c_str() == "void"){
			fprintf(error, "\nError at line no %d: Void function cannot be part of expression\n\n", line_count);
			error_count++;
		}
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());


		$$->code = $2->code;
		$$->symbol = $2->symbol;

		if ($1->symbol=="-"){
			char *temp=newTemp();
			$$->code+= "mov ax, " + $2->symbol+"\n";
			$$->code += "neg ax\n";
			$$->code += "mov " + string(temp)+ ", ax\n";
			$$->symbol = temp;

		}

		//DONE

 	}
		| factor {
			//fprintf(logout, "At line no: %d unary_expression : factor\n", line_count);
			//fprintf(logout, "\n%s\n\n", $1->getName().c_str());

			$$=$1;
			$$->code = $1->code;
			$$->symbol = $1->symbol;

			//DONE
	}
		| NOT unary_expression{
			//fprintf(logout, "At line no: %d unary_expression : NOT unary_expression\n", line_count);
			string str = "!";
			str+= $2->getName().c_str();
			$$ = new SymbolInfo(str, "unary_expression");
			$$->setVarType("int");
			//fprintf(logout, "\n%s\n\n", $$->getName().c_str());



			$$->code = $2->code;
			char *temp=newTemp();
			$$->code+="mov ax, " + $2->symbol + "\n";
			$$->code+="not ax\n";

			$$->code+="mov "+$2->symbol+", ax\n";
			$$->code+="mov "+string(temp)+", ax\n";
			$$->symbol = temp;

			//DONE

	}
	;

factor	: variable	{
		//fprintf(logout, "At line no: %d factor : variable\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());
		$$= $1;

		if ($$->getArrSize()==-1){


		}
		else{
			char *temp=newTemp();
			$$->code+= "mov ax, " + $1->symbol+"[bx]\n";
			$$->code+= "mov " + string(temp) + ", ax\n";
			$$->symbol = temp;
		}


		//WHAT TO DO FOR ARRAY  DONE
	}
	| ID LPAREN argument_list RPAREN {
		//fprintf(logout, "At line no: %d factor : ID LPAREN argument_list RPAREN \n", line_count);
		string str = $1->getName().c_str();
		str+= "(";
		str+= $3->getName().c_str();
		str+= ")";
		$$ = new SymbolInfo(str, "factor");
	  	SymbolInfo *si = table->lookup($1->getName().c_str());
		if (si==NULL){
			fprintf(error, "\nError at line %d: Variable not declared\n\n",line_count);
			error_count++;
		}
		else{
			$$->setVarType(si->getVarType().c_str());
			if (!si->isFunc()){
				fprintf(error, "\nError at line %d: ID is not a function\n\n", line_count);
				error_count++;
			}
			else{
				int sz = si->paramsType.size();
				if (sz!=parameter_list_type.size()){
					fprintf(error, "\nError at line %d: Invalid number of arguments. Function requires %d arguments.\n\n", line_count, sz);
					error_count++;
				}
				else{
					bool err=false;
					for (int i=0;i<sz;i++){
						if (parameter_list_type[i]!=si->paramsType[i] && !(si->paramsType[i]=="float" && parameter_list_type[i]=="int")){
							err=true;
						}
					}
					if (err){
						fprintf(error, "\nError at line %d: Invalid argument type\n\n", line_count);
						error_count++;
					}
				}
			}
		}

		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());

		$$->code+=$3->code;

		for (int i=0;i<nontempvariables.size();i++){
			if (nontempvariables[i]->getArrSize()==-1 ){
				$$->code+="push " + nontempvariables[i]->symbol +"\n";
			}
		}
		
		$$->code += "push ax\n";
		$$->code += "push bx\n";
		$$->code += "push cx\n";
		$$->code += "push dx\n";




		for (int i=0;i<parameter_list_tempName.size();i++){
			$$->code += "push " + string(newParam(i+1)) + "\n";
			$$->code += "mov ax, " + parameter_list_tempName[i] +"\n";
			$$->code += "mov " + string(newParam(i+1)) + ", ax\n"  ;

		}
		$$->code += "CALL " + si->getName() + "\n";
		for (int i=0;i<parameter_list_tempName.size();i++){
			$$->code += "pop " + string(newParam(i+1)) + "\n";

		}
		$$->code += "pop dx\n";
		$$->code += "pop cx\n";
		$$->code += "pop bx\n";
		$$->code += "pop ax\n";

		for (int i=nontempvariables.size()-1;i>=0;i--){
			if (nontempvariables[i]->getArrSize()==-1){
				$$->code+="pop " + nontempvariables[i]->symbol +"\n";
			}
		}


		if (si->getVarType()!="void"){
			char *temp1=newTemp();
			$$->code+= "mov ax, returnTemp\n";
			$$->code+="mov " + string(temp1) + ", ax\n";
			$$->symbol = temp1;
		}
		parameter_list_tempName.clear();
		parameter_list_type.clear();

		//WHAT TO DO FOR FUNCTION

	}
	| LPAREN expression RPAREN {
		//fprintf(logout, "At line no: %d factor : LPAREN expression RPAREN\n", line_count);
		string str= "(";
		str+= $2->getName().c_str();
		str+= ")";
		$$ = new SymbolInfo(str, "factor");
		$$->setVarType($2->getVarType().c_str());
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());

		$$->code = $2->code;
		$$->symbol = $2->symbol;


		//DONE
	}
	| CONST_INT {
		$$=$1;
		$$->setVarType("int");
	  //	fprintf(logout, "At line no: %d factor : CONST_INT\n", line_count);
	//	fprintf(logout, "\n%s\n\n", $1->getName().c_str());

		//DONE
	}
	| CONST_FLOAT {
		$$=$1;
		$$->setVarType("float");
	//	fprintf(logout, "At line no: %d factor : CONST_FLOAT\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());

		//DONE
	}
	| variable INCOP {
		//fprintf(logout, "At line no: %d factor : variable INCOP\n", line_count);
		string str = $1->getName().c_str();
		str+= $2->getName().c_str();
		$$ = new SymbolInfo(str, "factor");
		$$->setVarType($1->getVarType().c_str());
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());

		$$->code=$1->code;
		char *temp=newTemp();

		//WHAT TO DO FOR ARRAY
		if ($1->getArrSize()==-1){

			$$->code="mov ax, " + $1->symbol + "\n";

		}
		else{
			$$->code+= "mov ax, " + $1->symbol+"[bx]\n";

		}
		if ($2->symbol=="++")$$->code+="inc ax\n";
		if ($2->symbol=="--")$$->code+="dec ax\n";
		$$->code+="mov "+ $1->symbol+", ax\n";
		$$->code+="mov "+string(temp)+", ax\n";
		$$->symbol = temp;


	}
	;

argument_list : arguments {
		//fprintf(logout, "At line no: %d argument_list : arguments\n", line_count);
		//fprintf(logout, "\n%s\n\n", $1->getName().c_str());


	}
	| {
		$$ = new SymbolInfo("", "");
	}
	;

arguments : arguments COMMA logic_expression {
		//fprintf(logout, "At line no: %d arguments : arguments COMMA logic_expression\n", line_count);
		string str = $1->getName().c_str();
		str+= ", ";
		str+= $3->getName().c_str();
		$$ = new SymbolInfo(str, "arguments");
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		parameter_list_type.push_back($3->getVarType().c_str());
		parameter_list_tempName.push_back($3->symbol);
		$$->code= $1->code + $3->code;

	}
	    | logic_expression {
		//fprintf(logout, "At line no: %d arguments : logic_expression\n", line_count);
		//fprintf(logout, "\n%s\n\n", $$->getName().c_str());
		parameter_list_type.push_back($1->getVarType().c_str());
		parameter_list_tempName.push_back($1->symbol);
		$$->code = $1->code;
	}
	;


%%
int main(int argc,char *argv[])
{
	FILE *fp;

	if((fp=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	yyin=fp;
	yyparse();

	return 0;
}
