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


int main(int argc, char* argv[])
{
    if(argc < 2)
    {
        printf("无效参数\n");
        exit(1);
    }

    const char* cvs_file = argv[1];
    const char* html_file = "output.html";

    FILE* fp_cvs = fopen(cvs_file, "r");

    unlink(html_file);
    int fd_html = open(html_file, O_WRONLY|O_CREAT, 0777);

    write_file_header(fd_html);

    int header = 1;
    while(1)
    {
        char buf[4096];
        char* p = fgets(buf, sizeof(buf), fp_cvs);
        if(p == NULL)
            break;

        write_line_header(fd_html);
        if(header)
        {
            p = strtok(buf, ",");
            while(p)
            {
                char aa[1024];
                sprintf(aa, "<th>%s</th> ", p);
                write(fd_html, aa, strlen(aa));

                p = strtok(NULL, ",");
            }   

            const char* p1 = "<th>level</th>";
            write(fd_html, p1, strlen(p1));

            header = 0;
        }
        else
        {
            float score[7];
            p = strtok(buf, ",");
            int i = 0;
            while(p)
            {
                char aa[1024];
                sprintf(aa, "<td>%s</td> ", p);
                write(fd_html, aa, strlen(aa));

                score[i++] = atof(p);

                p = strtok(NULL, ",");

            }

            // A+, A, B+, B, C, D, E
            float sum = score[6];
            char level[3];
            memset(level, 0, sizeof(level));
            if(sum >= 425)
            {
                level[0] = 'A';
                for(i=1; i<6; ++i)
                {
                    if(score[i] < 85)
                    {
                        break;
                    }
                }

                if(i==6)
                {
                    level[1] = '+';
                }
            }
            else if(sum >= 350)
            {
                level[0] = 'B';
                for(i=1; i<6;++i)
                {
                    if(score[i] < 70)
                    {
                        break;
                    }        
                }
                if(i==6)
                {
                    level[1] = '+';
                }
            }
            else
            {
                level[0] = 'C';
            }

            char aa[1024];
            sprintf(aa, "<td>%s</td>", level);
            write(fd_html, aa, strlen(aa));

        }
        write_line_footer(fd_html);
    }

    write_file_footer(fd_html);
    fclose(fp_cvs);
    close(fd_html);

    return 0;
}

