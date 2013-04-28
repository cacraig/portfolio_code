#include <stdio.h>
#include <stdlib.h>
#include <sys/time.h>
#include <pthread.h>
#include <assert.h>

/*
*Colin Craig
*Problem 4, Homework 4
*11/1/11
*
*Life.c
*
*To compile: gcc Life.c -o Life.out -lpthread
*
*To Execute: ./Life.out <filename> <Number of Generations> 
*/




int** grid;
int** a_grid;
int m,n;

 typedef struct{

  int r;    
  int c;      
}param;

/*
*void* run_thread(void *args)
*
*@param - arguments containing the current row, and column position.
*
*Takes the current position of grid[r][c] and calculates the number of surrounding neighbors that are alive. It then sets a corresponding *
*cell in a_grid[r][c] to either 1 or 0 depending on the circumstances.
*
*/


void *
run_thread(void *args) {

		int num_alive=0;    //number of alive (1) neighbors
		param *temp = args; //temporary param struct to hold arguments
		int r= temp->r;     //rows
                int c= temp->c;     //columns


if(r==0 && c==0){num_alive=grid[r+1][c+1]+grid[r][c+1]+grid[r+1][c];} // Top left
else if(r==0 && c==(n-1)){num_alive=grid[r][c-1]+grid[r+1][c-1]+grid[r+1][c];}//Top right
else if(r==(m-1) && c==0){num_alive=grid[r-1][c]+grid[r-1][c+1]+grid[r][c+1];}//Bottom Left
else if(r==(m-1) && c==(n-1)){num_alive=grid[r-1][c]+grid[r-1][c-1]+grid[r][c-1];}//Bottom right

else if(r==0){num_alive=grid[r+1][c]+grid[r][c+1]+grid[r][c-1]+grid[r+1][c-1]+grid[r+1][c+1];}//North edge
else if(c==0){num_alive=grid[r-1][c]+grid[r+1][c]+grid[r][c+1]+grid[r-1][c+1]+grid[r+1][c+1];}//West Edge
else if(r==(m-1)){num_alive=grid[r-1][c]+grid[r][c+1]+grid[r][c-1]+grid[r-1][c-1]+grid[r-1][c+1];}//South Edge
else if(c==(n-1)){num_alive=grid[r-1][c]+grid[r+1][c]+grid[r][c-1]+grid[r-1][c-1]+grid[r+1][c-1];}//East Edge

else{num_alive=grid[r-1][c]+grid[r+1][c]+grid[r][c+1]+grid[r][c-1]+grid[r-1][c-1]+grid[r-1][c+1]+grid[r+1][c-1]+grid[r+1][c+1];}//Interior Cell

/*
*A 1 cell value stays 1 if exactly two or three neighbors are 1 valued.
*A 1 cell value becomes 0 if less than two or greater than three neighbors are 1 valued.
*A 0 cell value becomes 1 if exactly three neighbors are 1 valued.
*A 0 cell value stays 0 if less than three or greater than three neighbors are 1 valued.
*/

if(grid[r][c]==1){
	if(num_alive==2 || num_alive==3){a_grid[r][c]=1;}
	if(num_alive>3){a_grid[r][c]=0;}
	if(num_alive<2){a_grid[r][c]=0;}}
if(grid[r][c]==0){
	if(num_alive==3){a_grid[r][c]=1;}
	else{a_grid[r][c]=0;}}
	
	pthread_exit(0);
}

int
main(int argc, char *argv[]) {
     int k,i, j,rc,f,q;
     int num_generations;
     char* temp;
     long lSize;
     char* buffer;
     size_t result;
     pthread_t **my_threads;
     param argument;

     temp=argv[2];
     num_generations=temp[0]-'0'; //get number of generations. Probably could have used atoi() but I like ASCII math.

      FILE * pFile;
      pFile = fopen(argv[1],"rb");
      
 	// obtain file size:
  	fseek (pFile , 0 , SEEK_END);
  	lSize = ftell (pFile);
  	rewind (pFile);

  	// allocate memory to contain the whole file:
  	buffer = (char*) malloc (sizeof(char)*lSize);
  	if (buffer == NULL) {fputs ("Memory error",stderr); exit (2);}

  	// copy the file into the buffer:
  	result = fread (buffer,1,lSize,pFile);
  	if (result != lSize) {fputs ("Reading error",stderr); exit (3);}

  	/* the whole file is now loaded in the memory buffer. */

  	// terminate
  	fclose (pFile);

	char f_buffer[1000];

	//Get m and n values; remove these values, and store the rest into f_buffer
	j=0;i=0;
	while(i<2){
		if(buffer[j]!=' ' && i==0){
		m=buffer[j]-'0';
		i++;
		j++;}
		if(buffer[j]!=' ' && i==1){
		n=buffer[j]-'0';
		i++;
		j++;}
		else{j++;}}
				
	j=0;
	//filter out spaces.
	for(i=4;i<lSize;i++){
		if(buffer[i]!=' '&&buffer[i]!='\n'){
			f_buffer[j]=buffer[i];
			j++;}}
	
	//get mxn grid; convert chars to ints
	
	grid= (int**) malloc(m*sizeof(int*));     //allocate x-memory for grid[x][n]
	a_grid=(int**) malloc(m*sizeof(int*));    //allocate x-memory for a_grid[x][n]
	
	for (i = 0; i < m; i++){
   	grid[i] = (int*) malloc(n*sizeof(int));}  //allocate y-memory for grid[m][y]

	for (i = 0; i < m; i++){
   	a_grid[i] = (int*) malloc(n*sizeof(int));}//allocate y-memory for a_grid[m][y]

	int buff_count=0; //count of buffer position

	/*Initialize Grids*/
	printf("Start Grid: \n");
	for(i=0;i<m;i++){
		for(j=0;j<n;j++){
			grid[i][j]=f_buffer[j+buff_count]-'0';  
			a_grid[i][j]=f_buffer[j+buff_count]-'0';
			printf("%i",grid[i][j]); 		//print starting grid
		}buff_count=buff_count+n;printf("\n");}
	

	/*allocate thread grid*/
	my_threads = (pthread_t**)malloc(m*sizeof(pthread_t*));//Allocate x-memory for thread ID array
	for(i=0;i<m;i++){
		my_threads[i]=(pthread_t*) malloc(n*sizeof(pthread_t));}//Allocate y-memory for thread ID array

	/*Create Threads*/
	for(i=0;i<num_generations;i++){

		printf("Generation: %i \n",i+1); //Current generation

		for(q=0;q<m;q++){for(f=0;f<n;f++){grid[q][f]=a_grid[q][f];}}//Set grid = a_grid;
		
		for(j=0;j<m;j++){
			for(k=0;k<n;k++){
			argument.r = j;
			argument.c = k;
			rc= pthread_create(&my_threads[j][k],PTHREAD_CREATE_JOINABLE,run_thread, &argument); //Create Thread
			assert(rc==0);
			f=0;while(f<5){usleep(1);++f;}//Wait for thread 
			}
		}printf("\n");
	/*join all threads*/
		for(f=0;f<m;f++){
			for(q=0;q<n;q++){
			rc=pthread_join(my_threads[f][q], NULL);
			assert(rc==0);}}

	/*Print out Result Grid*/
	for(j=0;j<m;j++){
	for(k=0;k<n;k++){
	printf("%i",a_grid[j][k]);}printf("\n");}
	printf("\n");

	}

     free (buffer);
     return 0;
         
}
