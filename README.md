# cocos2dx-2048

### 用cocos2dx-lua 编写2048游戏 

* cocos2dx版本:3.13
* 排行榜服务器代码[rankserver]: https://github.com/ahuang007/skynet-rankserver
* 目标： 
    - 入门cocos
    - 不断完善项目,让项目使用cocos2dx的尽可能多的组件
    - 打出手机包
* 准备优化：
	- 公共弹出框
		- 一局结束提示重新开始
	- 代码优化：
		- scene和layer分离
		- 网络模块拆分
* 准备新增：
	- 简单的注册以及登录
	    - 界面用cocostudio编辑 尝试用csb
	    - 玩家可以选择填写昵称 
	    - 选择头像
	- 排行榜修改
	    - 排行榜可以滑动
	    - 支持头像(url)
	- 增加音效 (普通合并音效 合并出1024以上的音效)
	- 增加背景音乐(舒缓的纯音乐)
	- 合并1024以上的出现粒子效果
