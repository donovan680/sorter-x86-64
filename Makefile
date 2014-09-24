sorter: sorter.o sorter.asm
	ld sorter.o print.o -o sorter

nodebug: sorter.asm sorter-nodebug.o print.o
	ld sorter-nodebug.o print.o -o sorter

sorter-nodebug.o: sorter.asm print.o
	as sorter.asm -o sorter-nodebug.o

sorter.o: sorter.asm print.o
	as --gstabs sorter.asm -o sorter.o

print.o: print.asm
	as --gstabs print.asm -o print.o

clean:
	rm *.o sorter

