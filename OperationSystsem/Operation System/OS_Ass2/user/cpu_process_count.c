#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main(int argc, char **argv)
{
    if(argc > 1)
        printf("%d\n",cpu_process_count(atoi(argv[1])));
    else
        printf("Invalid argument. Enter a postive integer\n");

    exit(0);
}