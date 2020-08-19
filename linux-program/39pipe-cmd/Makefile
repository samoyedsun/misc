
target := $(shell pwd)
target := $(notdir $(target))
target := $(target).bin

# 定义伪目标
.PHONY: all clean install uninstall

all: $(target)

srcs := $(shell ls *.cpp)
objs := $(srcs:.cpp=.o)
deps := $(srcs:.cpp=.d)

include ../def.mk
-include $(deps)
# include $(deps)相当与增加以下依赖
#1.o: 1.cpp 1.h
#2.o: 2.cpp
#3.o: 3.cpp
#4.o: 4.cpp
#5.o: 5.cpp


%.o: %.cpp
	$(CC) -c -o $@ $< $(CPPFLAGS) $(CFLAGS) $(CXXFLAGS)
# 1.o: 1.cpp
#    gcc -c -o $@ $^

$(target): $(objs)
	$(CC) -o $@ $^ $(LIBS)

clean:
	$(RM) *.o
	$(RM) *.d
	$(RM) $(target)

install:
	$(CP) $(target) /usr/bin

uninstall:
	$(RM) /usr/bin/$(target)

%.d: %.cpp
	$(CC) -MM $< > $@
