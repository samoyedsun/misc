#include "../common.h"
#include <curl/curl.h>

int main(int argc, char* argv[])
{
    CURLcode ret = curl_global_init(CURL_GLOBAL_NOTHING);
    if(ret != CURLE_OK)
    {
        printf("global init error\n");
        return 0;
    }

    CURL* curl = curl_easy_init();
    if(curl == NULL)
    {
        printf("easy init error\n");
        return 0;
    }

    FILE* fp = stdout;

    curl_easy_setopt(curl, CURLOPT_URL, "http://127.0.0.1/cgi-bin/a.out");
    curl_easy_setopt(curl, CURLOPT_POST, 1);

    curl_easy_setopt(curl, CURLOPT_WRITEDATA, fp);
    curl_easy_setopt(curl, CURLOPT_HEADERDATA, fp);

    // POST的数据
    const char* data = "hello, this is post data";
    curl_easy_setopt(curl, CURLOPT_POSTFIELDS, data);

    ret = curl_easy_perform(curl);
    if(ret != CURLE_OK)
    {
        printf("perform error, ret=%d\n", (int)ret);
        return 0;
    }

    curl_easy_cleanup(curl);

    return 0;
}


















