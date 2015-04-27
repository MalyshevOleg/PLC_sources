#include <unistd.h>
#include <stdio.h>
#include <string.h>

#define MAXLINE 128

#define MODE_OFF  0
#define MODE_ON   1
#define MODE_GET  2

/*
 Returns 1 if rc.timesync is uncommented
*/
int getmode(FILE *inp)
{
    char line[MAXLINE];

    while(fgets(line, MAXLINE, inp) != NULL)
        if (strstr(line,"timesync") != NULL)
            return line[0] != '#';
    return 0;
}

int main(int argc, char **argv)
{
    char line[MAXLINE];
    FILE* inp;
    FILE* otp;
    int mode;
    size_t slen;

    if (setuid(0) == -1)
    {
        perror("Can't become root");
        return 1;
    }

    if (argc == 2)
    {
        if (strncmp(argv[1],"off",3) == 0)
            mode = MODE_OFF;
        else if (strncmp(argv[1],"on",2) == 0)
            mode = MODE_ON;
        else
            mode = MODE_GET;
    }
    else
        mode = MODE_GET;

//    printf("UID:%d EUID=%d\n", getuid(), geteuid());

    if ((inp = popen("crontab -l", "r")) == NULL)
    {
        perror("Can't get data from 'crontab -l'");
        return 1;
    }

    if(mode == MODE_GET)
    {
        fputs(getmode(inp)?"on\n":"off\n", stdout);
        pclose(inp);
        return 0;
    }

    if ((otp = popen("crontab -", "w")) == NULL)
    {
        perror("Can't send data to 'crontab'");
        return 1;
    }

    while(fgets(line, MAXLINE, inp) != NULL)
    {
        if (strstr(line,"timesync") != NULL)
        {
            if (mode == MODE_OFF && line[0] != '#')
                fputc('#', otp);
            else if (mode == MODE_ON && line[0] == '#')
            {
                slen = strlen(line);
                memmove(line,line+1,slen-1);
                line[slen-1] = '\0';
            }
        }
        fputs(line, otp);
    }

    pclose(otp);
    pclose(inp);
    return 0;
}
