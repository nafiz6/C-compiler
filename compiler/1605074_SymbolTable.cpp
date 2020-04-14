#include <iostream>
#include<stdio.h>
#include<string>
#include<vector>

using namespace std;

extern int uniqueId;
extern int buckets;


//extern FILE* logout;
extern FILE* tokenout;
extern FILE* error;
extern FILE* code;
extern FILE* codeOptimized;

class SymbolInfo{
    string name, type, var_type;
    int arr_size = -1;
    bool func = false;
    bool defined = false;
public:
	string code="";
    vector<string > paramsType;
	string symbol;

    SymbolInfo *next;
    ~SymbolInfo(){
        if (next){
            delete(next);
            next=0;
        }
    }
    SymbolInfo(){};

    SymbolInfo(string n, string t){
        name = n;
        type = t;
		symbol = n;

    }
    int getArrSize() {return arr_size;}

    string getName() { return name;}

    string getType() { return type;}

    string getVarType() { return var_type;}

    void setArrSize(int a) { arr_size = a;}

    void setFunc(){func = true;}

    void setDef(){defined = true;}

    bool isFunc(){return func;}

    bool isDefined(){return defined;}

    void setName(string n) {
        this->name = n;
		this->symbol = n;
    }

    void setType(string t) {
        this->type = t;
    }

    void setVarType(string v){
        this->var_type = v;
    }
};

class ScopeTable{
public:
    int buckets=10;
    int uid;
    ScopeTable *parentScope;
    SymbolInfo **symbolInfo;


    ScopeTable(int n){
        buckets = n;
        parentScope=0;
        uid = uniqueId;
        uniqueId++;
        symbolInfo = new SymbolInfo*[n];
        for (int i=0;i<n;i++){
            symbolInfo[i]=0;
        }

    }

    ~ScopeTable(){
        parentScope = 0;
        for (int i=0;i<buckets;i++){
            if (symbolInfo[i]){
                delete(symbolInfo[i]);
                symbolInfo[i]=0;
            };
        }
        if (symbolInfo){
            delete(symbolInfo);
            symbolInfo=0;
        }
    }


    int hashFunction(string name) {
        int l = name.size();
        int h=0;
        for (int i=1;i<=l;i++){
            h+= (h<<4) + (int)(name[i-1]);
            long g = h & 0xF0000000L;
            if (g !=0) h ^= g >> 24;
            h &=~g;
        }
        h = abs(h);
        return h%(this->buckets);
    }

    bool insert(string n, string t){
        int h = hashFunction(n);

        SymbolInfo* currSymbolInfo = symbolInfo[h];


        int pos = 0;
        if (currSymbolInfo==0){
            SymbolInfo *si = new SymbolInfo();
            si->setName(n);
            si->setType(t);
            si->next = 0;
            symbolInfo[h]= si;
            //cout << "Inserted in ScopeTable #"<< uid << " at position "<< h << ", " <<pos << endl;
            return true;
        }
        while(currSymbolInfo!=0){
            pos++;
            if (currSymbolInfo->getName()==n){
                //fprintf(logout,"<%s: %s> already exists", currSymbolInfo->getName().c_str() , currSymbolInfo->getType().c_str() );

                //cout << "<" << currSymbolInfo->getName() << ": " << currSymbolInfo->getType() << "> already exists\n";
                return false;
            }
            if (currSymbolInfo->next==0){
                SymbolInfo *si = new SymbolInfo();
                si->setName(n);
                si->setType(t);
                currSymbolInfo->next = si;
              //  cout << "Inserted in ScopeTable #"<< uid << " at position "<< h << ", " << pos << endl;
                return true;
            }
            currSymbolInfo = currSymbolInfo->next;
        }
        return false;

    }

    SymbolInfo* lookup(string n) {
        int h = hashFunction(n);
        SymbolInfo* currSymbolInfo = symbolInfo[h];
        int pos = 0;
        while (currSymbolInfo!=0){
            if (currSymbolInfo->getName()==n){
                //fprintf(logout, "Found in ScopeTable #%d at position %d, %d",uid, h, pos);
                return currSymbolInfo;
            }
            pos++;
            currSymbolInfo = currSymbolInfo->next;
        }
        return 0;

    }

    bool del(string n){
        int h = hashFunction(n);
        SymbolInfo* currSymbolInfo = symbolInfo[h];
        int pos = 0;

        if (currSymbolInfo==0){
            return false;
        }
        if (currSymbolInfo->getName()==n){
            symbolInfo[h] = currSymbolInfo->next;
            delete(currSymbolInfo);
            cout << "Found in ScopeTable #" << uid << " at position " << h << ", " << pos << endl;
            cout << "Deleted entry at " << h << ", " <<pos << " from ScopeTable #" << uid << endl;
            return true;

        }

        while (currSymbolInfo!=0){
            pos++;
            if (currSymbolInfo->next->getName()==n){
                SymbolInfo* oldNext = currSymbolInfo->next;
                SymbolInfo* newNext = oldNext->next;
                currSymbolInfo->next = newNext;
                delete(oldNext);
                cout << "Found in ScopeTable #" << uid << "at position " << h << ", " << pos << endl;
                cout << "Deleted entry at " << h << ", " <<"from ScopeTable #" << uid << endl;
                return true;
            }
            currSymbolInfo = currSymbolInfo->next;
        }
        return false;

    }


    void print() {
        //fprintf(logout, "\nScopeTable #%d\n",uid);
        for (int i=0;i<buckets;i++){
            SymbolInfo* curr = symbolInfo[i];
            if (curr==0) continue;
             //fprintf(logout, "%d --> ",i );
            while (curr!=0){
                 //fprintf(logout, "< %s: %s>  ", curr->getName().c_str(), curr->getType().c_str());
                curr = curr->next;
            }
               ////fprintf(logout, "\n" );
        }
      // fprintf(logout, "\n" );
    }

};



class SymbolTable{
public:
    ScopeTable* currScopeTable=0;


    SymbolTable(){
        enterScope();
    }

    ~SymbolTable(){
        if (currScopeTable){
            delete(currScopeTable);
            currScopeTable=0;
        }
    }


    void enterScope() {
        ScopeTable* newScope = new ScopeTable(buckets);
        newScope->parentScope = currScopeTable;
        currScopeTable = newScope;
        //fprintf(logout, "\nNew ScopeTable with id %d created\n\n", currScopeTable->uid);
        //cout << "New ScopeTable with id " << currScopeTable->uid << " created\n";
    }

    void exitScope() {
        if (currScopeTable==0){
            cout << "No scope remaining\n";
            return;
        }
    //    fprintf(logout, "\nScopeTable with id %d removed\n\n", currScopeTable->uid);
        ScopeTable *st = currScopeTable;
        currScopeTable = currScopeTable->parentScope;
        delete(st);
    }

    bool insert(string n, string t) {
        return currScopeTable->insert(n,t);
    }

    bool remove(string n) {
        ScopeTable* curr = currScopeTable;
        while (curr!=0){
            if (curr->del(n))return true;
            curr = curr->parentScope;
        }
        //cout << "Not found\n";
        return false;
    }

    SymbolInfo* lookup(string n) {
        ScopeTable* curr = currScopeTable;
        while (curr!=0){
            SymbolInfo* symbolInfo = curr->lookup(n);
            if (symbolInfo!=0)return symbolInfo;
            curr = curr->parentScope;
        }
        //cout << "Not found\n";
        return 0;
    }

    void printCurr() {
        currScopeTable->print();
    }

    void printAll() {
        ScopeTable* curr = currScopeTable;
        while (curr!=0){
            curr->print();
            //cout << endl;
            curr = curr->parentScope;
        }
    }

};
