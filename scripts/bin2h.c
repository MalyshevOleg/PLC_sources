#include <stdio.h>


unsigned char buf[16];
int xlt[16] = {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F'};

int main(int argc, char* argv[])
{
  int e=0, i, f=0;
  
  FILE *f1=NULL,*f2=NULL;

  if(argc<3) {
    printf("\nUsage: bin2h in out");
    return -1;
  }
  
  if((f1=fopen(argv[1],"r+b"))==NULL) e++;
  else if((f2=fopen(argv[2],"w+b"))==NULL) e=2;
  else {
    fputs("static unsigned char spk_logo[] ={\n",f2);
    while ((e=fread(buf,1,16,f1))>0) {
      putc('\t',f2);
      for(i=0;i<e;i++) {
        if(e<16 && i==e-1) f++;
        fputs("0x",f2);
        putc(xlt[buf[i]>>4],f2);
        putc(xlt[buf[i]&0x0f],f2);
        if(!f) putc(',',f2);
      }
      putc('\n',f2);
    }
    fputs("};",f2);
    e=0;
  }
  if(e) printf("\nCannot open: %s",argv[e]);
  fclose(f2);
  fclose(f1);
  return 0;
}
