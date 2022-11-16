bin:main.o
	g++ -o bin main.o -L../../../lua-5.4.4 -llua -ldl
	rm main.o

main.o:main.cpp
	g++ -c main.cpp -I../../../lua-5.4.4

clean:
	rm bin
