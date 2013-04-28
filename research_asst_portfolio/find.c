#include <stdio.h>
#include <stdlib.h>

/*
*Colin Craig
*CSC-246
*Homework #3
*Problem #2
*
*find.c
*
*To compile: gcc find2.c -o find.out
*
*To Execute: ./find2.out <search_word> <1-5 file names> 
*/


void find_something(char* s_word, char* file);


int main (int argc, char * argv [ ]) 
{
   
   int i,id;
   char* search_word; //word to search for
   char* file[10]; //array for filenames

   search_word=argv[1]; // search word obtained from arguement

   for (i = 2; i < argc; i++ ) { //i=2 because the first 2 arguements are the execute command, and the search word
	id=fork();

       	if(id==0){ //if child process
	file[i]=argv[i]; //filename to search obtained from arguement
	find_something(search_word,file[i]);
	}
	
   }
	
   if(id!=0){ //if parent, wait for child to die
	wait(NULL);}

	return 0;
   
}

/*
*Finds the word in a file, and ouputs the line it appears on to the screen. 
*
*@param1 - word to search for
*@param2 - file to search in
*
*/

void find_something(char* s_word, char* file){
	char command[100];//buffer for command construction
	sprintf(command,"grep %s %s",s_word,file); // "grep %s %s >&results.txt" for output to file results.txt
	system(command); //execute grep "search_word" "file_to_search" 
	exit(1);
}
