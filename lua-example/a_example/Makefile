bin:main.o
	g++ -o bin main.o -llua -ldl
	rm main.o
main.o:main.cpp
	g++ -c main.cpp

clean:
	rm bin
