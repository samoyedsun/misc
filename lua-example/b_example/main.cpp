/*
 **************************************
 * author:      MaZhao              
 * date:        2016.12.15/10:53   
 * describe:    C++调用lua全局函数,变量  
 **************************************
 */
#include <iostream>
using namespace std;

#ifdef __cplusplus
extern "C"
{
#endif

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

#ifdef __cplusplus
}
#endif

#define FILEPATH "conf.lua"

void test()
{
    lua_State *L = NULL;
    int var1 = 520110;
    string var2 = "cpp_mazhao";

    L = luaL_newstate();
    luaL_openlibs(L);

    //c++调用lua必须先加载
    luaL_dofile(L, FILEPATH);

    //入栈
    lua_getglobal(L, "splitJoint");
    lua_getglobal(L, "var_num");
    lua_getglobal(L, "var_str");
    lua_pushnumber(L, var1);
    lua_pushstring(L, var2.c_str());

    //调用一个函数
    //首先，要调用的函数入栈；接着，把需要传递给这个函数的参数正序压栈；
    //这是指第一个参数首先压栈。最后调用一下lua_call;
    //lua_call的第二个参数是压入栈的参数的个数,
    //调用完毕后所有参数以及函数本身都会出栈。而函数的返回值这时则被压栈
    //lua_call的第三个参数是将要被调整的返回值的个数。如果设置为LUA_MULTRET,
    //这种情况下，所有的返回值都被压入堆栈中，函数返回值将按正序压栈，
    //因此在调用会最后一个返回值将被放在栈顶.
    lua_call(L, 4, 3);

    //从栈中获取返回值
    if (lua_isstring(L, 1))
    {
        cout << lua_tostring(L, 1) << endl;
    }
    if (lua_isnumber(L, 2))
    {
        cout << lua_tonumber(L, 2) << endl;
    }
    if (lua_isstring(L, 3))
    {
        cout << lua_tostring(L, 3) << endl;
    }
   
    lua_close(L);
}

int main(int argc, char *argv[])
{
    cout << "==========华丽丽的begin==========" << endl;
    test();
    cout << "==========华丽丽的end============" << endl;
    return 0;
}

