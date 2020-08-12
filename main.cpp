#include <iostream>
#include <vector>
#include <algorithm>

#include <cstdlib>
#include <ctime>
#include <sys/time.h>

#define LOW_UID 1
#define HIG_UID 100000
#define TARGET_USER_ID 9999
#define TARGET_USER_AMOUNT_NEARBY 5

typedef struct userInfo{
	int uid;	//用户ID
	int ce;		//战斗力
} UserInfo;

void initUserInfoVec(std::vector<UserInfo>& userInfoVec)
{
	for (int uid = LOW_UID; uid < HIG_UID; ++uid)
	{
		UserInfo userInfoTmp = {.uid = uid, .ce = rand()};
		userInfoVec.push_back(userInfoTmp);
	}
}

int getCeByUid(const std::vector<UserInfo>& userInfoVec, int uid)
{
	for (auto& it : userInfoVec)
	{
		if (it.uid == uid)
		{
			return it.ce;
		}
	}
	return 0;
}

long get_time_for_millisecond()
{
	struct timeval tv;
    	gettimeofday(&tv, NULL);
	return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

int main()
{
	srand((int)time(NULL));
	std::vector<UserInfo> userInfoVec;
	initUserInfoVec(userInfoVec);

	// TODO:
	// 1.获取目标用户的战斗力
	// 2.在用户信息列表中获取5个与目标用户战斗力差值最小的用户
	//   每获取一个就将其放到列表最前面, 最后列表最前面的5个就是我们要找的战斗力与目标用户最相近的用户.

	long t_start, t_end;
        t_start = get_time_for_millisecond();
	int target_user_id = TARGET_USER_ID;
	int target_user_ce = getCeByUid(userInfoVec, target_user_id);
	for (int exclude_offset= 0; exclude_offset < TARGET_USER_AMOUNT_NEARBY; ++exclude_offset)
	{
		int diff_value_tmp = -1;
		UserInfo* userInfoPtr = NULL;
		for (int j = exclude_offset; j < userInfoVec.size(); j++)
		{
			UserInfo *it = &userInfoVec[j];
			if (target_user_id == it->uid)
				continue;
			int a = it->ce;
			int b = target_user_ce;
			int diff_value = (a > b) ? (a - b) : (b - a);
			if (-1 == diff_value_tmp)
			{
				diff_value_tmp = diff_value;
				userInfoPtr = it;
			} else
			{
				if (diff_value < diff_value_tmp)
				{
					diff_value_tmp = diff_value;
					userInfoPtr = it;
				}
			}
		}
		UserInfo userInfoTmp = {
			.uid = userInfoPtr->uid,
			.ce = userInfoPtr->ce
		};
		userInfoPtr->uid = userInfoVec[exclude_offset].uid;
		userInfoPtr->ce = userInfoVec[exclude_offset].ce;
		userInfoVec[exclude_offset].uid = userInfoTmp.uid;
		userInfoVec[exclude_offset].ce = userInfoTmp.ce;
	}
        t_end = get_time_for_millisecond();

	std::cout << "--------------------------" << std::endl;
	std::cout << "处理耗时:" << t_end - t_start << "ms" << std::endl;
	std::cout << "--------------------------" << std::endl;
	std::cout << "目标玩家:" << std::endl;
	std::cout << "--------------------------" << std::endl;
	std::cout << "UID:" << target_user_id << "\t战斗力:" << target_user_ce << std::endl;
	std::cout << "--------------------------" << std::endl;
	std::cout << "相接近的5个玩家:" << std::endl;
	std::cout << "--------------------------" << std::endl;
	for (int i = 0; i < TARGET_USER_AMOUNT_NEARBY; ++i)
	{
		int a = userInfoVec[i].ce;
		int b = target_user_ce;
		int diff_value = (a > b) ? (a - b) : (b - a);
		std::cout << "UID:" << userInfoVec[i].uid << "\t";
		std::cout << "战斗力:" << userInfoVec[i].ce << "\t";
		std::cout << "相对目标玩家战斗力差值:" << diff_value << std::endl;
	}
	return 0;
}
