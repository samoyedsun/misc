/*
 **************************************
 * author:      MaZhao              
 * date:        2016.12.15/15:20  
 * describe:    lua调用C++函数,变量 
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

#define PATHFILE "conf.lua"

//lua调用c函数的类型
//为了正确的和lua通讯，c函数必须使用下列协议。
//这个协议定义了参数以及返回值传递方法：
//c函数通过Lua中的栈来接收参数，第一个参数在索引1的地方，
//而最后一个参数在索引lua_gettop(L)处，当需要向lua返回值的时候，
//c函数只需要把它们以正序压到堆栈上（第一个返回值最先压入），
//然后返回这些返回值的个数。在这些返回值之下的都会被lua丢掉。
//和c调用lua函数一样，从lua中调用c函数也可以有很多返回值.
static int sampleFunc(lua_State *L)
{
   int n = lua_gettop(L); 

   lua_Number sum = 0.0;
   int i;
   for (i = 1; i <= n; i++)
   {
       if(!lua_isnumber(L, i))
       {
           lua_pushliteral(L, "incorrect argument");
           lua_error(L);
       }
       sum += lua_tonumber(L, i);
   }

   lua_pushnumber(L, sum/n);
   lua_pushnumber(L, sum);
   return 2;
}

void test()
{
    lua_State *L = NULL;
    int var = 999999999;
    L = luaL_newstate();
    luaL_openlibs(L);

    //将函数压栈供lua调用
    lua_pushcfunction(L, sampleFunc);
    //设置一个lua可调用的全局函数名
    lua_setglobal(L, "sampleFunc");
    //将变量压栈供lua使用
    lua_pushnumber(L, var);
    //设置一个lua可调用的全局变量名
    lua_setglobal(L, "var");
    //最后加载并执行lua脚本就可以看到效果
    luaL_dofile(L, PATHFILE);

    lua_close(L);
}
int main()
{
    cout << "==========华丽丽的begin==========" << endl;
    test();
    cout << "==========华丽丽的end============" << endl;
    return 0;
}
