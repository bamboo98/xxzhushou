
_addToDelay_ = function() end
_addToTouchDown_ = function () end
_addToTouchUp_ = function () end

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


Behavior={}

function Behavior:new(Parent)--创建动作
	local o={
		_tag="Behavior",
		parent=Parent,--设置父节点
		server=function(Blackboard) return end,
		continuity=false,--如果此项设置为true,则协程执行后不会自动销毁,再次运行这个动作的时候会继续上次的接着做
		co=nil,
		blackboard=Parent.blackboard,
		tiggerOnDelay = Tigger:new(Parent.blackboard),
		tiggerOnTouchDown = Tigger:new(Parent.blackboard),
		tiggerOnTouchUp = Tigger:new(Parent.blackboard),
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
	self:setTigger()--设置检查器
	if self.co==nil or not self.continuity or coroutine.status(self.co)=="dead" then--重新建立协程
		self.co=coroutine.create(self.server)
		coroutine.resume(self.co,self.blackboard)--开始运行协程,并且传入黑板数据
		if coroutine.status(self.co)=="dead" then 
			--sysLog("协程运行结束,销毁对象")
			self.co=nil 
		end
	else--重新唤起协程
		coroutine.resume(self.co)
	end
end

function Behavior:setContinuity(Flag)--设置行为是否可以连续运行(中断后不销毁)
	self.continuity=Flag
end

function Behavior.stop()--停止当前行为
	if coroutine.isyieldable() then
		Behavior.resetTigger()--重置检查器
		coroutine.yield()
	end
end

function Behavior:setTigger()--设置检查器
	_addToDelay_ = function() if self.tiggerOnDelay:check() then Behavior.stop() end end
	_addToTouchDown_ = function() if self.tiggerOnTouchDown:check() then Behavior.stop() end end
	_addToTouchUp_ = function() if self.tiggerOnTouchUp:check() then Behavior.stop() end end
end

function Behavior:getTiggerOnDelay()--设置检查器
	return self.tiggerOnDelay
end

function Behavior:getTiggerOnTouchDown()--设置检查器
	return self.tiggerOnTouchDown
end

function Behavior:getTiggerOnTouchUp()--设置检查器
	return self.tiggerOnTouchUp
end

function Behavior.resetTigger()--重置检查器
	_addToDelay_ = function() end
	_addToTouchDown_ = function () end
	_addToTouchUp_ = function () end
end


Scene={}

function Scene:new(Blackboard)
	local o={
		_tag="Scene",
		blackboard=Blackboard,--黑板
		startTrigger=Tigger:new(Blackboard),--运行触发器
		endTrigger=Tigger:new(Blackboard),--结束触发器
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


Tigger={}

function Tigger:new(Blackboard)
	local o={
		_tag="Tigger",
		blackboard=Blackboard,--黑板
		rule=function(bk) return false end,--判断规则
	}
	setmetatable(o,{__index = self} )
	return o
end

function Tigger:setRule(RuleFunction)
	if type(RuleFunction)=="function" then
		self.rule=RuleFunction
	end
end

function Tigger:check()
	return self.rule(self.blackboard)
end


Sequence={}

function Sequence:new()
	local o={
		_tag="Sequence",
		scenes={}
	}
	setmetatable(o,{__index = self} )
	return o
end

function Sequence:run()
	local flag=true
	while flag do
		for _,v in ipairs(self.scenes) do--遍历scene执行run函数
			flag=v:run()
			if flag then break end
		end
	end
end

function Sequence:addScene(Scene)
	if Scene._tag and Scene._tag=="Scene" then
		table.insert(self.scenes,Scene)
	end
end