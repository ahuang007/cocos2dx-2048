# cocos2dx-2048

### 用cocos2dx-lua 编写2048游戏 

* cocos2dx版本:3.13
* 账号服务器代码[accountserver]: https://github.com/ahuang007/skynet-accountserver
* 排行榜服务器代码[rankserver]: https://github.com/ahuang007/skynet-rankserver
* 目标： 
    - 入门cocos
	- 打出手机包
    - 不断完善项目,让项目使用cocos2dx的尽可能多的组件
* 代码优化：
	- scene和layer分离
	- 网络模块拆分
	- 排行榜修改
		- 使用scoreview实现滑动效果
* 新增功能：
	- 公共弹出框
		- 一局结束提示重新开始	
	- 简单的注册以及登录
	    - 界面用cocostudio编辑 尝试用csb
	    - 玩家可以选择填写昵称 
	    - 可以选择头像id同时排行榜支持显示头像id
	- 增加设置功能
		- 设置下面有1 音量 2 排行榜 3 重置 
	- 合并1024以上的出现粒子效果
