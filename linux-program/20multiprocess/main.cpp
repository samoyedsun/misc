#include "../common.h"

void child_process_main()
{
    
}

int create_child(int n)
{
    for(int i=0; i<n;++i)
    {
        pid_t pid = fork();
        if(pid == 0)
        {
            child_process_main();
            break;
        }
    }

}

int main1()
{
    create_child(13);
    return 0;
}

// a.out ls -al
int main(int argc, char* argv[])
{
    /*
     * a.out
     * ls
     * -al
     * */
    const char* cmd = argv[1]; 
    execvp(argv[1], argv+1);
    return 0;
}


















