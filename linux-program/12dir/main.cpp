#include <dirent.h>
#include <sys/types.h>
#include <stdio.h>
#include <string.h>


int main()
{
    DIR* dir = opendir(".");

#if 0
    struct dirent* entry = readdir(dir);
    printf("%s\n", entry->d_name);
    rewinddir(dir);

    entry = readdir(dir);
    printf("%s\n", entry->d_name);
#endif

    struct dirent* entry;
    long location;
    while(1)
    {
        location = telldir(dir);
        printf("location is %d\n", (int)location);

        entry = readdir(dir);
            
        printf("%s\n", entry->d_name);
        if(entry == NULL)
            break;
            
        //if(strcmp(entry->d_name, "main.d") == 0)
        //{
        //    break;
       // }
       //

    }

    rewinddir(dir);
    seekdir(dir, location);
    entry = readdir(dir);

    printf("%s\n", entry->d_name);

    closedir(dir);
    return 0;
}

