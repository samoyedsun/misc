#include "../common.h"
#include <curl/curl.h>

int main(int argc, char* argv[])
{
    // 使用curl来访问web服务器
    //
    curl_global_init(CURL_GLOBAL_NOTHING);

    CURL* curl = curl_easy_init();

    FILE* fp = stdout;

    // 设置参数
    curl_easy_setopt(curl, CURLOPT_URL, "http://127.0.0.1/cgi-bin/a.out?user=user&pass=1111");
    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    curl_easy_setopt(curl, CURLOPT_HEADERDATA, fp);

    CURLcode ret = curl_easy_perform(curl);

    curl_easy_clear(curl);

    return 0;
}


















