
sysLog("开始运行")
require "controller"
init("0",1)
--[[
有3个函数需要加在自己封装的点击方法和延迟方法里
_addToTouchDown_()--加在touchdown之前
_addToTouchUp_()--加在touchUp之后
_addToDelay_()--加在mSleep前后都行
]]


function click(x,y)
	_addToTouchDown_()--加在touchdown之前
	touchDown(1,x,y)

	mSleep(50)

	touchUp(1,x,y)
	mSleep(10)
	_addToTouchUp_()--加在touchUp之后
end

function delay(Second)
	--_addToDelay_()--前后无所谓
	mSleep(Second*1000)
	_addToDelay_()--前后无所谓
end



--[[            黑板创建                 ]]
local 黑板=Blackboard:new()--新建一个黑板



--[[            黑板变量初始化                 ]]
黑板:setValue("启动时间",mTime())--在黑板上存一些变量
黑板:setValue("已刷次数",0)
黑板:setValue("战斗开始时间",0)
黑板:setValue("当前游戏场景","不知道什么鬼界面")
黑板:setValue("功能","刷御魂")
黑板:setValue("体力",100)
黑板:setValue("是否买体力",true)
黑板:setValue("要刷次数",10)
黑板:setValue("要刷多久",150*1000)

sysLog("黑板初始化完毕")


--[[            场景和流程的创建和绑定                 ]]
local 主流程=Sequence:new()--新建主运行流程


local 进入御魂=黑板:createScene()--创建一个场景
local 返回主界面=黑板:createScene()--创建一个场景
主流程:addScene(进入御魂)--在主流程内添加"进入御魂"场景
主流程:addScene(返回主界面)--在主流程内添加"进入御魂"场景
local 进入御魂关卡=黑板:createScene()--创建一个场景
local 体力不足=黑板:createScene()--创建一个场景
local 御魂流程=Sequence:new()--新建御魂的运行流程
进入御魂:addSequence(御魂流程)--把御魂流程绑定到进入御魂场景上
御魂流程:addScene(进入御魂关卡)--在御魂流程内添加"进入御魂关卡"场景
御魂流程:addScene(体力不足)--在御魂流程内添加"进入御魂关卡"场景
local 御魂结算流程=Sequence:new()--新建御魂的运行流程
local 御魂关卡结算=黑板:createScene()--创建一个场景
local 等待战斗结束=黑板:createScene()--创建一个场景
御魂结算流程:addScene(御魂关卡结算)--在御魂结算流程内添加"御魂关卡结算场景"
御魂结算流程:addScene(等待战斗结束)--把御魂流程绑定到进入御魂场景上
进入御魂关卡:addSequence(御魂结算流程)--把御魂流程绑定到进入御魂场景上

sysLog("场景流程初始化完毕")



--[[             场景的触发器设定               ]]

返回主界面:getStartTrigger():setRule(
	function(blackboard)
		return blackboard:getValue("当前游戏场景")~="主界面" and (blackboard:getValue("功能")=="刷御魂" and blackboard:getValue("已刷次数")<blackboard:getValue("要刷次数") and mTime()<blackboard:getValue("要刷多久")+blackboard:getValue("启动时间"))
	end
	)
进入御魂:getStartTrigger():setRule(
	function(blackboard)
		return blackboard:getValue("功能")=="刷御魂" and blackboard:getValue("当前游戏场景")=="主界面" and blackboard:getValue("已刷次数")<blackboard:getValue("要刷次数") and mTime()<blackboard:getValue("要刷多久")+blackboard:getValue("启动时间") 
	end
	)
进入御魂关卡:getStartTrigger():setRule(
	function(blackboard)
		return blackboard:getValue("当前游戏场景")=="御魂关卡选择" and blackboard:getValue("已刷次数")<blackboard:getValue("要刷次数") and mTime()<blackboard:getValue("要刷多久")+blackboard:getValue("启动时间")
	end
	)
体力不足:getStartTrigger():setRule(
	function(blackboard)
		return blackboard:getValue("当前游戏场景")=="体力不足"
	end
	)
等待战斗结束:getStartTrigger():setRule(
	function(blackboard)
		return blackboard:getValue("当前游戏场景")=="战斗内" and mTime()<blackboard:getValue("要刷多久")+blackboard:getValue("启动时间")
	end
	)
御魂关卡结算:getStartTrigger():setRule(
	function(blackboard)
		return blackboard:getValue("当前游戏场景")=="战斗结束" and mTime()<blackboard:getValue("要刷多久")+blackboard:getValue("启动时间")
	end
	)

sysLog("触发器设定完毕")
--[[             场景内的行为设定               ]]

返回主界面:getDoingBehavior():setServer(
	function(blackboard)
		sysLog(string.format("从\"%s\"游戏场景返回了\"主界面\"",blackboard:getValue("当前游戏场景")))
		blackboard:setValue("当前游戏场景","主界面")
	end
	)
进入御魂:getDoingBehavior():setServer(
	function(blackboard)
		sysLog(string.format("进入了\"%s\"Scene,界面即将转换为\"%s\"","进入御魂","御魂关卡选择"))
		blackboard:setValue("当前游戏场景","御魂关卡选择")
	end
	)
进入御魂关卡:getDoingBehavior():setServer(
	function(blackboard)
		sysLog(string.format("进入了\"%s\"Scene,当前体力%d,尝试进入战斗","进入御魂关卡",blackboard:getValue("体力")))
		if blackboard:getValue("体力")>16 then
			blackboard:setValue("当前游戏场景","战斗内")
		else
			blackboard:setValue("当前游戏场景","体力不足")
		end
	end
	)
体力不足:getDoingBehavior():setServer(
	function(blackboard)
		sysLog(string.format("进入了\"%s\"Scene,当前体力%d,是否可以买体力%s","体力不足",blackboard:getValue("体力"),tostring(blackboard:getValue("是否买体力"))))
		if blackboard:getValue("是否买体力") then
			blackboard:setValue("体力",blackboard:getValue("体力")+50)--买体力
			sysLog("购买了50点体力")
			blackboard:setValue("当前游戏场景","御魂关卡选择")
		else
			sysLog("体力不足,退出运行")
			lua_exit()
		end
	end
	)
等待战斗结束:getDoingBehavior():setServer(
	function(blackboard)
		sysLog(string.format("进入了\"%s\"Scene","等待战斗结束"))
		delay(2)
		sysLog(string.format("战斗结束,游戏进入战斗结束场景"))
		blackboard:setValue("当前游戏场景","战斗结束")
	end
	)
御魂关卡结算:getDoingBehavior():setServer(
	function(blackboard)
		blackboard:setValue("体力",blackboard:getValue("体力")-16)--扣体力
		blackboard:setValue("已刷次数",blackboard:getValue("已刷次数")+1)--加次数
		sysLog(string.format("进入了\"%s\"Scene,扣除16点体力,已刷次数%d","御魂关卡结算",blackboard:getValue("已刷次数")))
		blackboard:setValue("当前游戏场景","御魂关卡选择")
	end
	)

sysLog("行为设定完毕")


主流程:run()




