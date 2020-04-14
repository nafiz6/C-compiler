int func(int a){
	if (a==1){
	return 1;	
	}
	if (a==2){
	return 1;
	}
	int c;
	int d;
	c = func(a-1);
	d = func(a-2);
	return c + d;
}

int main(){
    int a,b;
    a=15;
    println(a);
    int d;
    d=func(a);
    println(d);
    return 0;
}
