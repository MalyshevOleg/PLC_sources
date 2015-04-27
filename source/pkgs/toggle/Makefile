CFLAGS ?= -g
 
all: toggle
 
toggle: toggle.o
	$(CC) $(LDFLAGS) -o $@ $^
 
toggle.o: toggle.c
	$(CC) $(CFLAGS) -c -o $@ $<
 
clean: FRC
	rm -f toggle toggle.o
