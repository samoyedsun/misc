
#include "../common.h"

// ./13packet.bin -p aaa.packet ...
// ./13packet.bin -u aaa.packet

// filenamelen[2] filename[n] filelen[8] [atime] [mtime] [mode-type] filecontent

int find_last_slash(const char* path)
{
    int len = strlen(path);
    for(int i=len; i>=0; --i)
    {
       if(path[i] == '/')
          return i; 
    }

    return -1;
}

void packet_path_info(FILE* out, const char* path, const char* savepath)
{
    struct stat buf;
    lstat(path, &buf);

    int last_slash_index = find_last_slash(path); 

    char save_path[1024];
    sprintf(save_path, "%s/%s", savepath, path+last_slash_index+1);

    short filenamelen = strlen(save_path)+1;
    fwrite(&filenamelen, sizeof(short), 1, out);

    fwrite(save_path, filenamelen, 1, out);

    // 如果是个目录，这个长度是不是0？
    uint64_t filelen = buf.st_size;
    fwrite(&filelen, sizeof(uint64_t), 1, out);

    fwrite(&buf.st_mode, sizeof(buf.st_mode), 1, out);
}

void packet_one_file(FILE* out, const char* filename, const char* savepath)
{
    packet_path_info(out, filename);

    char buf[1024];
    FILE* in = fopen(filename, "r");

    while(1)
    {
        int ret = fread(buf, 1, 1024, in);
        if(ret== 0)
        {
            break;
        }
        fwrite(buf, ret, 1, out);
    }
    fclose(in);
}

void packet_one_dir(FILE* out, const char* dirname, const char* savepath)
{
    DIR* dir = opendir(dirname);
    struct dirent* entry;

    packet_path_info(out, path, savepath);

    while(1)
    {
        entry = readdir(dir);
        if(entry == NULL)
            break;
        if(strcmp(entry.d_name, ".") == 0)
            continue;
        if(strcmp(entry.d_name, "..") == 0)
            continue;

        if(entry.d_type == DT_REG)
        {
            char full_path[1024];
            sprintf(full_path, "%s/%s", dirname, entry.d_name);
            packet_one_file(out, full_path, savepath);
        }
        else if(entry.d_type == DT_DIR)
        {
            char save_path[1024];
            sprintf(save_path, "%s/%s", savepath, entry.d_name);

            char full_path[1024];
            sprintf(full_path, "%s/%s", dirname, entry.d_name);
            packet_one_dir(out, full_path, save_path);
        }
    }
}

void packet_one_path(FILE* out, const char* path, const char* savepath)
{
    struct stat buf;
    lstat(path, &buf);

    if(S_ISREG(buf.st_mode))
    {
        // 打包一个文件
        packet_one_file(out, path, savepath);
    } 
    else if(S_ISDIR(buf.st_mode))
    {
        // 打包一个目录
        packet_one_dir(out, path, savepath);
    }
    else if(S_ISLNK(buf.st_mode))
    {

    }
}

int packet(int argc, char* argv[])
{
    const char* target = argv[2]; 
    unlink(target);

    FILE* fp = fopen(target, "w+");

    for(int i=3; i<argc; ++i)
    {
        packet_one_path(fp, argv[i], ".");
    }

    fclose(fp);
    return 0;
}

int unpack(char* argv[])
{

}

int main(int argc, char* argv[])
{
    if(strcmp(argv[1], "-p") == 0)
    {
        return packet(argc, argv);
    }
    else if(strcmp(argv[1], "-u") == 0)
    {
        return unpack(argv);
    }
    printf("unknown option\n");
    return 1;
}
