require "controller"
init("0",1)

--[[
��3��������Ҫ�����Լ���װ�ĵ���������ӳٷ�����
_addToTouchDown_()--����touchdown֮ǰ
_addToTouchUp_()--����touchUp֮��
_addToDelay_()--����mSleepǰ����
]]


function click(x,y)
	_addToTouchDown_()--����touchdown֮ǰ
	touchDown(1,x,y)

	mSleep(50)

	touchUp(1,x,y)
	mSleep(10)
	_addToTouchUp_()--����touchUp֮��
end

function delay(Second)
	--_addToDelay_()--ǰ������ν
	mSleep(Second*1000)
	_addToDelay_()--ǰ������ν
end



--[[            �ڰ�����̴���                 ]]
local bk=Blackboard:new()--�½�һ���ڰ�
local seq1=Sequence:new()--�½�һ����������
local scene1_seq=Sequence:new()--�½�һ����������


--[[            �ڰ������ʼ��                 ]]
bk:setValue("����ʱ��",mTime())--�ںڰ��ϴ�һЩ����
bk:setValue("�ƴ�",0)
bk:setValue("����","ʾ��")


--[[            ��������                 ]]
local scene1=bk:createScene()--����һ������
local scene2=bk:createScene()--����һ������
local scene1_1=bk:createScene()--����һ������
local scene1_2=bk:createScene()--����һ������


--[[            ���������̰�                 ]]
seq1:addScene(scene1)--��scene1��������seq1
seq1:addScene(scene2)--��scene2��������seq1
scene1_seq:addScene(scene1_1)--��scene1_1��������scene1_seq
scene1_seq:addScene(scene1_2)--��scene1_2��������scene1_seq

scene1:addSequence(scene1_seq)--������scene1_seq����Ϊ����scene1��������


--[[            ���ó����Ĵ�����                 ]]
--��������Ĭ�Ϸ���ֵ��Ϊfalse
--����scene1�����д���������
scene1:getStartTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("����")=="ʾ��" and Blackboard:getValue("�ƴ�")==0--���ڰ��"����"�ֶ�Ϊ"ʾ��",���Ҽƴ�Ϊ0ʱ,�����ɹ�
	end)--���ô���������,���뺯��,�ú������ҽ���һ������Blackboard,Ϊscene1�ĺڰ�,����ֵΪtrue��false,[trueΪ�ɹ�����,falseΪʧ��]

--����scene1�Ľ�������������
scene1:getEndTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("�ƴ�")==1--���ڰ��"�ƴ�"�ֶ�Ϊ1ʱ,�����ɹ�
	end)

--����scene1_1�����д���������
scene1_1:getStartTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("�ƴ�")==0
	end)

--����scene1_2�����д���������
scene1_2:getStartTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("�ƴ�")==10
	end)

--����scene2�����д���������
scene2:getStartTrigger():setRule(
	function(Blackboard)
		return Blackboard:getValue("�ƴ�")==233
	end)

--����������˳��,�ƴ�=0 -> 1 -> 10 -> 233 -> 10 ->ֹͣ

--[[            ���ó�������Ϊ                ]]
scene1:getStartingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("�ƴ�",1)
		sysLog(string.format("From:%s,Behavior:%s,�ƴ�=%d","scene1","Starting",Blackboard:getValue("�ƴ�")))
	end)
scene1:getDoingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("�ƴ�",233333)
		sysLog(string.format("From:%s,Behavior:%s,�ƴ�=%d","scene1","Doing",Blackboard:getValue("�ƴ�")))
	end)
scene1:getEndingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("�ƴ�",10)
		sysLog(string.format("From:%s,Behavior:%s,�ƴ�=%d","scene1","Ending",Blackboard:getValue("�ƴ�")))
	end)
scene1_1:getDoingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("�ƴ�",233333)
		sysLog(string.format("From:%s,Behavior:%s,�ƴ�=%d","scene1_1","Doing",Blackboard:getValue("�ƴ�")))
	end)
scene1_2:getDoingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("�ƴ�",233)
		sysLog(string.format("From:%s,Behavior:%s,�ƴ�=%d","scene1_2","Doing",Blackboard:getValue("�ƴ�")))
	end)
scene2:getDoingBehavior():setServer(
	function(Blackboard)
		Blackboard:setValue("�ƴ�",10)
		sysLog(string.format("From:%s,Behavior:%s,�ƴ�=%d","scene2","Doing",Blackboard:getValue("�ƴ�")))
	end)






--[[            ��������                 ]]
sysLog(string.format("From:%s,Behavior:%s,�ƴ�=%d","��ʼ����","/",bk:getValue("�ƴ�")))

seq1:run()

sysLog(string.format("From:%s,Behavior:%s,�ƴ�=%d","��������","/",bk:getValue("�ƴ�")))