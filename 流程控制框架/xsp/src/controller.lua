
_addToDelay_ = function() end
_addToTouchDown_ = function () end
_addToTouchUp_ = function () end

local function doFunction(f,blackboard)
    while f do
        f = coroutine.yield(f(blackboard))
    end
end

Blackboard={}

function Blackboard:new()--创建黑板对象
	local o={
		_tag="Blackboard",
		con={},
	}
	setmetatable(o,{__index = self} )

	return o
end

function Blackboard:setValue(Member,Value)
	self.con[Member]=Value
end

function Blackboard:getValue(Member,DefaultValue)
	if self.con[Member]~=nil then
		return self.con[Member] 
	else
		return DefaultValue or nil
	end
end

function Blackboard:setValueBatch(Value)
	for k,v in pairs(Value) do
		self.con[k]=v
	end
end

function Blackboard:getAllValue(Target)
	Target=Target or self
	return Target.con
end

function Blackboard:createScene()
	return Scene:new(self)
end
function Blackboard:createSequence()
	return Sequence:new(self)
end


Behavior={}

function Behavior:new(Parent)--创建动作
	local o={
		_tag="Behavior",
		parent=Parent,--设置父节点
		server=function(Blackboard) return end,
		continuity=false,--如果此项设置为true,则协程执行后不会自动销毁,再次运行这个动作的时候会继续上次的接着做
		co=nil,
		blackboard=Parent.blackboard,
		triggerOnDelay = Trigger:new(Parent.blackboard),
		triggerOnTouchDown = Trigger:new(Parent.blackboard),
		triggerOnTouchUp = Trigger:new(Parent.blackboard),
	}
	setmetatable(o,{__index = self} )

	return o
end

function Behavior:setServer(ServerFunction)--这里传入Function没有参数,数据交互使用黑板对象
	if type(ServerFunction)=="function" then
		self.server=ServerFunction
	end
end

function Behavior:run()
	local flag,ret
	self:setTrigger()--设置检查器
	if self.co==nil then
		self.co=coroutine.create(doFunction)
	end
	flag,ret=coroutine.resume(self.co,self.server,self.blackboard)--开始运行协程,并且传入黑板数据
	if flag and type(ret)=="string" and ret=="_stop_" then--是手动中断,不是正常运行结束
		if not self.continuity then--不需要继续运行的协程,直接销毁
			self.co=nil
		end
	elseif not flag then--错误停止
		sysLog("协程内发生错误,错误信息"..ret)
		dialog("脚本运行发生错误,请反馈给竹子菌,详细信息\r\n"..ret)
		lua_exit()
	end
end

function Behavior:setContinuity(Flag)--设置行为是否可以连续运行(中断后不销毁)
	self.continuity=Flag
end

function Behavior.stop()--停止当前行为
	if coroutine.isyieldable() then
		Behavior.resetTrigger()--重置检查器
		coroutine.yield("_stop_")
	end
end

function Behavior:setTrigger()--设置检查器
	_addToDelay_ = function() if self.triggerOnDelay:check() then Behavior.stop() end end
	_addToTouchDown_ = function() if self.triggerOnTouchDown:check() then Behavior.stop() end end
	_addToTouchUp_ = function() if self.triggerOnTouchUp:check() then Behavior.stop() end end
end

function Behavior:getTriggerOnDelay()--设置检查器
	return self.triggerOnDelay
end

function Behavior:getTriggerOnTouchDown()--设置检查器
	return self.triggerOnTouchDown
end

function Behavior:getTriggerOnTouchUp()--设置检查器
	return self.triggerOnTouchUp
end

function Behavior.resetTrigger()--重置检查器
	_addToDelay_ = function() end
	_addToTouchDown_ = function () end
	_addToTouchUp_ = function () end
end


Scene={}

function Scene:new(Blackboard)
	local o={
		_tag="Scene",
		blackboard=Blackboard,--黑板
		startTrigger=Trigger:new(Blackboard),--运行触发器
		endTrigger=Trigger:new(Blackboard),--结束触发器
	}
	setmetatable(o,{__index = self} )
	o.startingBehavior=Behavior:new(o)--运行前操作(一定会执行)
	o.doingBehavior=Behavior:new(o)--运行中循环操作(满足结束触发器则不会执行)
	o.endingBehavior=Behavior:new(o)--运行结束后操作(一定会执行)
	return o
end

function Scene:getStartingBehavior()
	return self.startingBehavior
end

function Scene:getDoingBehavior()
	return self.doingBehavior
end

function Scene:getEndingBehavior()
	return self.endingBehavior
end

function Scene:getStartTrigger()
	return self.startTrigger
end

function Scene:getEndTrigger()
	return self.endTrigger
end

function Scene:run()
	if self.startTrigger:check() then
		getDefaultCSYS():keepScreen(false)
		self.startingBehavior:run()
		if not self.endTrigger:check() then
			self.doingBehavior:run()
		end
		self.endingBehavior:run()
		if self.child and self.child._tag=="Sequence" then
			self.child:run()--当子场景触发成功时,检查子场景流程
		end
		return true
	end
	return false
end

function Scene:addSequence(Sequence)
	if Sequence._tag and Sequence._tag=="Sequence" then
		self.child=Sequence
	end
end


Trigger={}

function Trigger:new(Blackboard)
	local o={
		_tag="Trigger",
		blackboard=Blackboard,--黑板
		rule=function(bk) return false end,--判断规则
	}
	setmetatable(o,{__index = self} )
	return o
end

function Trigger:setRule(RuleFunction)
	if type(RuleFunction)=="function" then
		self.rule=RuleFunction
	end
end

function Trigger:check()
	return self.rule(self.blackboard)
end


Sequence={}

function Sequence:new(Blackboard)
	local o={
		_tag="Sequence",
		scenes={},
		isLoop=false,
		maxCount=-1,
		maxTime=-1,
		loopIntervalTime=0,
		LoopEndTrigger=Trigger:new(Blackboard)
	}
	setmetatable(o,{__index = self} )
	return o
end

function Sequence:run()
	local flag=true
	local loopCount,loopTime
	repeat
		if flag then --如果上次遍历scene成功执行,则重置循环时间和次数
			loopTime=mTime()
			loopCount=0
		end
		getDefaultCSYS():keepScreen(false)
		getDefaultCSYS():keepScreen(true)
		for _,v in ipairs(self.scenes) do--遍历scene执行run函数
			flag=v:run()
			if flag then
				break 
			end
		end
		if self.LoopEndTrigger:check() then 
			break 
		end
		loopCount=loopCount+1
		if self.loopIntervalTime>0 then mSleep(self.loopIntervalTime) end
	until((not flag and not self.isLoop) or ((self.isLoop and not flag) and (loopTime+self.maxTime<mTime() or loopCount>self.maxCount)))
	getDefaultCSYS():keepScreen(false)
end

function Sequence:addScene(Scene)
	if Scene._tag and Scene._tag=="Scene" then
		table.insert(self.scenes,Scene)
	end
end

--[[
	Sequence:getLoopEndTrigger()
	设置场景循环时用于判断是否立即结束循环并返回上一节点的触发器
	返回触发器对象
]]
function Sequence:getLoopEndTrigger()
	return self.LoopEndTrigger
end

--[[
	Sequence:setLoop(isLoop,LoopCount,LoopTime,IntervalTime)
	设置场景检测的循环方式
	参数:	isLoop		Bool型,是否循环
			LoopCount 	循环次数
			LoopTime 	循环最长时间
			IntervalTime每次循环的间隔(毫秒)
]]
function Sequence:setLoop(isLoop,LoopCount,LoopTime,IntervalTime)
	LoopCount=LoopCount or -1
	LoopTime=LoopTime or -1
	IntervalTime=IntervalTime or 0
	self.isLoop=isLoop
	self.maxCount=LoopCount
	self.maxTime=LoopTime*1000
	self.loopIntervalTime=IntervalTime
end