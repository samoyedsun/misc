/*
 **************************************
 * author:      MaZhao              
 * date:        2022.11.16/15:46 
 * describe:    
 **************************************
 */

#include <lua.h>
#include <lauxlib.h>
#include <lualib.h>

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

static struct StudentTag
{
	char *strName;
	char *strNum;
	int iSex;
	int iAge;
};

static int Student(lua_State *L)
{
	size_t iBytes = sizeof(struct StudentTag);
	struct StudentTag *pStudent;
	pStudent = (struct StudentTag *)lua_newuserdata(L, iBytes);

	// set element
	luaL_getmetatable(L, "Student");
	lua_setmetatable(L, -2);

	return 1;
}

static int GetName(lua_State *L)
{
	struct StudentTag *pStudent = (struct StudentTag *)luaL_checkudata(L, 1, "Student");
	lua_pushstring(L, pStudent->strName);
	return 1;
}

static int SetName(lua_State *L)
{
	struct StudentTag *pStudent = (struct StudentTag *)luaL_checkudata(L, 1, "Student");
	const char *pName = luaL_checkstring(L, 2);
	luaL_argcheck(L, pName != NULL && pName != "", 2, "Wrong Parameter");

	pStudent->strName = (char *)pName;
	return 0;
}

// 注册函数luaopen_student_libs
int luaopen_student_libs(lua_State *L)
{
    luaL_newmetatable(L, "StudentClass");
    
    // 将-1位h刚刚创建的元表复制一份压到栈顶
    lua_pushvalue(L, -1);

    // 将栈顶的元表
    lua_setfield(L, -2, "__index");
    
    return 0;
}

static const luaL_Reg lua_reg_libs[] = {
    { "Student", luaopen_student_libs },
    { NULL, NULL }
};

static int new_obj(lua_State *L)
{
    printf("================newobj\n");
    return 0;
}

void test()
{
    lua_State *L = NULL;
    int var = 999999999;
    L = luaL_newstate();
    luaL_openlibs(L);

    {
        //size_t iBytes = sizeof(struct StudentTag);
        //struct StudentTag *pStudent;
        //pStudent = (struct StudentTag *)lua_newuserdata(L, iBytes);
        //lua_pushstring(L, "world");
        printf("globaltableidx:%d\n", LUA_RIDX_GLOBALS);
        printf("registryindex:%d\n", LUA_REGISTRYINDEX);

        lua_newtable(L);
        int table_pos = lua_gettop(L);

        /*
        // create metatable
        int r = luaL_newmetatable(L, "Student");
        int metatable_pos = lua_gettop(L);
        // init metatable 
        lua_pushliteral(L, "__metatable");
        lua_pushvalue(L, table_pos);
        lua_settable(L, metatable_pos);
        lua_pushliteral(L, "__index");
        lua_pushvalue(L, table_pos);
        lua_settable(L, metatable_pos);
        */

        lua_newtable(L);
        int mt_pos = lua_gettop(L);
        lua_pushliteral(L, "__call");
        lua_pushcfunction(L, new_obj);
        lua_pushliteral(L, "new");
        lua_pushvalue(L, -2);
        lua_settable(L, table_pos);
        lua_settable(L, mt_pos);
        lua_setmetatable(L, table_pos);



        int pos = lua_gettop(L);
        printf("pos:%d\n", pos);
        // set element
        //luaL_getmetatable(L, "Student");
        //lua_pushvalue(L, -1);
        //lua_setmetatable(L, -2);
    }

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
    test();
    return 0;
}
