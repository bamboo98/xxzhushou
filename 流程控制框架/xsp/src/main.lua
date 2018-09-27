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



--[[            黑板和流程创建                 ]]
local bk=Blackboard:new()--新建一个黑板
local seq1=Sequence:new()--新建一个运行流程
local scene1_seq=Sequence:new()--新建一个运行流程


--[[            黑板变量初始化                 ]]
bk:setValue("启动时间",mTime())--在黑板上存一些变量
bk:setValue("计次",0)
bk:setValue("功能","示例")


--[[            场景创建                 ]]
local scene1=bk:createScene()--创建一个场景
local scene2=bk:createScene()--创建一个场景
local scene1_1=bk:createScene()--创建一个场景
local scene1_2=bk:createScene()--创建一个场景


--[[            场景和流程绑定                 ]]
seq1:addScene(scene1)--将scene1绑定至流程seq1
seq1:addScene(scene2)--将scene2绑定至流程seq1
scene1_seq:addScene(scene1_1)--将scene1_1绑定至流程scene1_seq
scene1_seq:addScene(scene1_2)--将scene1_2绑定至流程scene1_seq

scene1:addSequence(scene1_seq)--将流程scene1_seq设置为场景scene1的子流程


--[[            设置场景的触发器                 ]]
--触发器的默认返回值均为false
--设置scene1的运行触发器规则
scene1:getStartTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("功能")=="示例" and Blackboard:getValue("计次")==0--当黑板的"功能"字段为"示例",并且计次为0时,触发成功
	end)--设置触发器规则,传入函数,该函数有且仅有一个参数Blackboard,为scene1的黑板,返回值为true或false,[true为成功触发,false为失败]

--设置scene1的结束触发器规则
scene1:getEndTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("计次")==1--当黑板的"计次"字段为1时,触发成功
	end)

--设置scene1_1的运行触发器规则
scene1_1:getStartTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("计次")==0
	end)

--设置scene1_2的运行触发器规则
scene1_2:getStartTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("计次")==10
	end)

--设置scene2的运行触发器规则
scene2:getStartTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("计次")==233
	end)

--期望的运行顺序,计次=0 -> 1 -> 10 -> 233 -> 10 ->停止

--[[            设置场景的行为                ]]
scene1:getStartingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("计次",1)
		sysLog(string.format("From:%s,Behavior:%s,计次=%d","scene1","Starting",Blackboard:getValue("计次")))
	end)
scene1:getDoingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("计次",233333)
		sysLog(string.format("From:%s,Behavior:%s,计次=%d","scene1","Doing",Blackboard:getValue("计次")))
	end)
scene1:getEndingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("计次",10)
		sysLog(string.format("From:%s,Behavior:%s,计次=%d","scene1","Ending",Blackboard:getValue("计次")))
	end)
scene1_1:getDoingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("计次",233333)
		sysLog(string.format("From:%s,Behavior:%s,计次=%d","scene1_1","Doing",Blackboard:getValue("计次")))
	end)
scene1_2:getDoingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("计次",233)
		sysLog(string.format("From:%s,Behavior:%s,计次=%d","scene1_2","Doing",Blackboard:getValue("计次")))
	end)
scene2:getDoingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("计次",10)
		sysLog(string.format("From:%s,Behavior:%s,计次=%d","scene2","Doing",Blackboard:getValue("计次")))
	end)






--[[            流程运行                 ]]
sysLog(string.format("From:%s,Behavior:%s,计次=%d","开始运行","/",bk:getValue("计次")))

seq1:run()

sysLog(string.format("From:%s,Behavior:%s,计次=%d","结束运行","/",bk:getValue("计次")))