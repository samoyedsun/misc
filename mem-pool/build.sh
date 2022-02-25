#g++ main.cpp mem_pool.cpp mem_pool.h -o bin

# 预处理
g++ -E main.cpp -o main.i
g++ -E mem_pool.cpp -o mem_pool.i

# 编译
g++ -S main.i -o main.s
g++ -S mem_pool.i -o mem_pool.s

# 汇编
g++ -c main.s -o main.o
g++ -c mem_pool.s -o mem_pool.o

# 链接
g++ main.o mem_pool.o -o bin