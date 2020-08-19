#include "../common.h"

void copy_file(const char* src_file, const char* dst_file)
{
    int fd_src = open(src_file, O_RDONLY);
    if(fd_src < 0)
    {
        printf("源文件不存在\n");
        exit(-2);
    }

#if 0
    // 尝试以截断方式打开文件
    int fd_dst = open(dst_file, O_WRONLY|O_TRUNC);
    if(fd_dst == -1)
    {
        // 尝试创建文件
        fd_dst = open(dst_file, O_WRONLY|O_CREAT, 0777);
        if(fd_dst < 0)
        {
            printf("目标文件打开失败，请检查权限\n");
            exit(-3);
        }
    }
#endif

    // 直接删除原来的目标文件，再创建文件
    unlink(dst_file);
    int fd_dst = open(dst_file, O_WRONLY|O_CREAT, 0777);
    if(fd_dst < 0)
    {
        printf("目标文件打开失败，请检查权限\n");
        exit(-3);
    }



    // 拷贝文件
    // 一次拷贝4096个字节，循环拷贝
    char buf[4096];
    while(1)
    {
        int read_bytes = read(fd_src, buf, sizeof(buf));
        if(read_bytes == 0) // 表示读完了
        {
            break;
        }

        int write_bytes = write(fd_dst, buf, read_bytes);
        if(write_bytes != read_bytes)
        {
            printf("硬盘空间不足\n");
            exit(-4);
        }
    }

    close(fd_src);
    close(fd_dst);
}


void copy_prop(const char* src_file, const char* dst_file)
{
    // 获取源文件的时间属性
    struct stat buf;
    stat(src_file, &buf);

    // 修改目标文件的属性
    struct utimbuf t;
    t.actime = buf.st_atime;
    t.modtime = buf.st_mtime;
    utime(dst_file, &t);

    // chmod
    chmod(dst_file, buf.st_mode);
}

int main(int argc, char* argv[])
{
    // 异常判断
    if(argc < 3)
    {
        printf("非法的参数\n");
        exit( -1);
    }

    const char* src_file = argv[1];
    const char* dst_file = argv[2];

    if(strcmp(src_file, dst_file) == 0)
    {
        return 0;
    }

    copy_file(src_file, dst_file);
    copy_prop(src_file, dst_file);

    return 0;
}
