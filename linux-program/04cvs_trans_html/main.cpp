#include "../common.h"
void write_file_header(int fd)
{
    const char * p = "<h1> scores </h1><table border=1>";
    write(fd, p, strlen(p));
}
void write_file_footer(int fd)
{
    const char * p = "</table>";
    write(fd, p, strlen(p));
}
void write_line_header(int fd)
{
    const char * p = "<tr>";
    write(fd, p, strlen(p));

}
void write_line_footer(int fd)
{
    const char * p = "</tr>";
    write(fd, p, strlen(p));
}

int is_plus(char* score[], int level)
{
    for(int i=1; i <= 5; ++i)
    {
        float s = atof(score[i]);
        if(s < level)
        {
            return 0;
        }
    }

    return 1;
}

// #6 计算level,根据总分和每科的分数，定级
void write_level(char* score[], int fd)
{
    float total = atof(score[6]);
    char level[3];
    memset(level, 0, 3);

    if(total >= 425)
    {
        *level = 'A';

        if(is_plus(score, 85))
        {
            level[1] = '+';
        }
    }
    else if(total >= 350)
    {
        *level = 'B';
        if(is_plus(score, 70))
        {
            level[1] = '+';
        }
    }
    else if(total >= 300)
    {
        *level = 'C';
        if(is_plus(score, 60))
        {
            level[1] = '+';
        }
    }
    else if(total >= 250)
    {
        *level = 'D';
        if(is_plus(score, 50))
        {
            level[1] = '+';
        }
    }
    else
    {
        *level = 'E';
    } 


    char buf[1024];
    sprintf(buf, "<td>%s</td>", level);

    write(fd, buf, strlen(buf));
}

// #5 转换一行，注意header问题
void trans_line(char* line, int fd, int header)
{
    char* p = strtok(line, ",");
    char* scores[7];
    int i = 0;
    while(p)
    {
        scores[i++] = p;

        char buf[1024];
        if(header == 1)
            sprintf(buf, "<th>%s</th>", p);
        else
            sprintf(buf, "<td>%s</td>", p);
        write(fd, buf, strlen(buf));

        p = strtok(NULL, ",");
    }

    if(header == 1)
    {
        const char* p1 = "<th>level</th>";
        write(fd, p1, strlen(p1));
    }
    else
    {
        write_level(scores, fd);
    }
}

// #4 逐行扫描，进行转换
void trans_file(FILE* fp_src, int fd_dst)
{
    int header = 1;
    while(1)
    {
        char buf[4096];
        char* p = fgets(buf, sizeof(buf), fp_src);
        if(p == NULL)
            break;

        write_line_header(fd_dst);
        trans_line(buf, fd_dst, header); 
        write_line_footer(fd_dst);

        if(header == 1)
            header = 0;
    }  
}

// #2 检查文件情况，并且打开文件
void trans_file(const char* cvs, const char* html)
{
    FILE* fp = fopen(cvs, "r");
    if(fp == NULL)
    {
        printf("error open source file\n");
        exit(1);
    }

    unlink(html);
    int fd = open(html, O_WRONLY|O_CREAT, 0777);
    if(fd < 0)
    {
        printf("error open dest file\n");
        exit(2);
    }

    write_file_header(fd);

    // #3 进行转换
    trans_file(fp, fd);

    write_file_footer(fd);

    close(fd);
    fclose(fp);
}

int main(int argc, char* argv[])
{
    if(argc < 2)
    {
        printf("参数无效\n");
        return 0;
    }

    const char* cvs_file = argv[1];
    const char* html_file = "output.html";

    // #1 转换入口函数
    trans_file(cvs_file, html_file);

    return 0;
}
