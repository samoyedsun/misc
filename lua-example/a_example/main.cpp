/*
 ************************************
 * author:      MaZhao              
 * date:        2016.12.14/20:08    
 * describe:    加载并执行lua脚本   
 ************************************
 */
#include <iostream>
#include <cstdlib>
using namespace std;

#ifdef __cplusplus
extern "C"
{
#endif

/*
 * Comments:
 * 头文件lua.h定义了Lua提供的基础函数.  * 其中包括创建一个新的Lua环境的函数（如lua_open(lua5.2废弃)）,
 * 调用Lua函数(如lua_pcall)的函数,读取、写入Lua环境的全局变量
 * 的函数,注册可以被Lua代码调用的新函数的函数，等等.
 * 所有在Lua.h中被定义的都有一个lua_前缀.
 */
#include <lua.h>
/*
 * Comments:
 * 头文件lauxlib.h定义了辅助库(auxlib)提供的函数.
 * 同样所有在其中定义的函数等都以luaL_打头（例如luaL_loadbuffer）.
 * 辅助库利用lua.h中提供的基础函数提供了更高层次上的抽象;
 * 所有Lua标准库都使用auxlib。基础API致力于economy and orthogonality,
 * 相反auxlib致力于实现一般任务的使用性。当然，基于你的程序的需要
 * 而创建其他的抽象也是非常容易的，需要铭记在心里的是，auxlib没有
 * 存取Lua内部的权限。它完成它的所有的工作都是通过正式的基础API.
 */
#include <lauxlib.h>
/*
 * 为了lua保持Lua的苗条，所有的标准库以单独的包提供，
 * 所以如果你不需要就不会强求你使用他们.头文件lualib.h定义了
 * 打开这些库的函数.例如,调用luaopen_io，以创建io table并注册I/O函数
 * (io.read, io.write等等)到Lua环境中.
 */
#include <lualib.h>

#ifdef __cplusplus
}
#endif

//这是luaL_newstate()中默认的内存分配方式，可对其进行修改
//然后配合lua_newstate(lua_Alloc f, void *ud) 进行使用
void *myl_alloc(void *ud, void *ptr, size_t osize, size_t nsize)
{
    (void)ud; (void)osize; /*not used*/
    if (nsize == 0)
    {
        free(ptr);
        return NULL;
    }
    else
    {
        return realloc(ptr, nsize);
    }
}

void test()
{
   //typedef struct lua_State lua_State;
   //一个不透明的结构，它指向一条线程并间接（通过该线程）引用了
   //整个Lua解释器的状态.Lua库是完全可重入的：他没有任何全局变量。
   //状态机所有的信息都可以通过这个结构访问到。
   lua_State *L = NULL;

   //这里的内存分配方式可以自定义，不过一般我们用默认的足够
   //L = lua_newstate(&myl_alloc, NULL);
   L = luaL_newstate();
   if (L == NULL)
   {
       cout << "由于内存有限，无法创建线程或状态机!" << endl;
   }

   //打开状态机中所有lua标准库,如果不打开可以加载但是无法执行
   luaL_openlibs(L);

   //加载并且运行指定文件，她是用下列宏定义出来的：
   //(luaL_loadfile(L, filename) || lua_pcall(L, 0, LUA_MULTRET, 0))
   //如果调用成功，L内便保存了这个脚本的所有变量的状态。(这句话暂时还不理解)
   luaL_dofile(L, "conf.lua");
   
   //这个是只加载不执行
   //int retload = luaL_loadfile(L, "b.lua");
   
   //销毁指定lus_State结构
   //销毁指定Lua状态机中的所有对象(如果有垃圾收集相关的元方法的话，会调用)
   //并且释放状态机中使用的所有动态内存。
   //在一些平台上，你可以不必调用这个函数，因为当宿主程序结束的时候，
   //所有的资源就自然被释放掉了。另一方面，长期运行的程序，
   //比如一个后台程序或是一个网站服务器，会创建多个Lua状态机。
   //那么就应该在不需要的时候赶紧关闭他们.
   lua_close(L);
}

int main()
{
   cout << "==========华丽丽的begin==========" << endl;
   test();
   cout << "==========华丽丽的end============" << endl;
   return 0;
}
