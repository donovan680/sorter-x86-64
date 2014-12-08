DEBUG=

sorter: sorter.o parsing.o alloc.o file_handling.o print.o sorter.asm
	ld sorter.o print.o parsing.o alloc.o file_handling.o -o sorter

%.o: %.asm
	as $(DEBUG) $< -o $@

clean:
	rm -f *.o sorter

