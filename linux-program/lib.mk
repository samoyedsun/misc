
#target := $(shell pwd)
#target := $(notdir $(target))
target := libmylib.a

# 定义伪目标
.PHONY: all clean install uninstall

all: $(target)

srcs := $(shell ls *.cpp)
objs := $(srcs:.cpp=.o)
deps := $(srcs:.cpp=.d)

-include $(deps)
# include $(deps)相当与增加以下依赖
#1.o: 1.cpp 1.h
#2.o: 2.cpp
#3.o: 3.cpp
#4.o: 4.cpp
#5.o: 5.cpp

%.d: %.cpp
	gcc -MM $< > $@

%.o: %.cpp
	gcc -c -o $@ $< $(CPPFLAGS) $(CFLAGS) $(CXXFLAGS)
# 1.o: 1.cpp
#    gcc -c -o $@ $^

$(target): $(objs)
	$(AR) cr $@ $^ 

clean:
	$(RM) *.o
	$(RM) *.d
	$(RM) $(target)

