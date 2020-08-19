#include <dirent.h>
#include <sys/types.h>
#include <stdio.h>

// #2 定义两个参数的目的是为了更好的递归
void show_dir(const char* path, const char* dirname)
{
    // #3 拼接目录路径
    char full_path[1024];
    sprintf(full_path, "%s/%s", path, dirname);

    // #4 打开目录
    // 把目录中的所有项目，全部读取到内存
    // 并且有一个指针，指向第一个项目
    DIR* dir = opendir(full_path);
    
    struct dirent* entry;
    while(1)
    {
        // #5 读取项目，指针自动往后移动
        entry = readdir(dir);
        if(entry == NULL)
            break;
        if(*entry->d_name == '.')
            continue;

        if(entry->d_type == DT_DIR)
        {
            // 针对目录，需要递归再处理
            show_dir(full_path, entry->d_name);
        }
        else
        {
            // 输出信息
            printf("%s, 0x%02x\n", entry->d_name, entry->d_type);
        }
    }

    // 关闭打开的目录
    closedir(dir);
}


int main()
{
    const char* path = ".";
    const char* dirname = "";

// 遍历目录函数，方便递归
    show_dir(path, dirname);
    return 0;
}

int main1()
{
    // 打开folder
    DIR* dir = opendir(".");
    if(dir == NULL)
    {
        perror("opendir");
        return 0;
    }

    // 遍历目录的文件项
    struct dirent* entry;
    while(1)
    {
        // directory entry
        entry = readdir(dir);
        if(entry == NULL)
            break;

        // .和..还有隐藏文件被忽略
        if(*entry->d_name == '.')
            continue;

        printf("%s, 0x%02x\n", entry->d_name, entry->d_type);
    }

    closedir(dir);

    return 0;

}
