--[[

Copyright (c) 2012-2013 Baby-Bus.com

http://www.baby-bus.com/LizardMan/

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

--[[!--

场景层类，定义层相关操作方法及逻辑实现。

-   定义场景层功能方法。

]]

----------------------
-- 类
----------------------
local M = classLayerTouch("Main")


----------------------
-- 公共参数
----------------------



-- [常量]
-- ..

-- [操作变量]
-- ..








----------------------
-- 构造方法
----------------------
--[[--

构造方法，定义视图实例初始化逻辑

### Parameters:
-   table **params**    参数集合

### Return: 
-   object              对象实例

]]
function M:ctor(params)
    -- [超类调用]
    M.super.ctor(self, params)

	
end








----------------------
-- 结点渲染
----------------------
--[[--

视图渲染，处理视图结点加载、事件绑定等相关操作

]]
function M:onRender()
	SCENE_CHANGING = false
	bb.UNative.removeAd()
    NV.removeAd()
    --加载背景
    self:loadBackground()

    self:loadTitle()

    self:loadPlay()

    self:loadBtnMV()

    self:loadTree()

    -- self:test()

    -- 友盟数据
    if not LYD120_126 then
    	LYD120_126 = true
	    if ST.getInteger("lyd120-126") == nil then
	        ST.setInteger("lyd120-126", 0)
	    else
	        local age = game:getChildAge()
	        local eventName = "lyd126"
	        if age == "1-2周岁" then
	            eventName = "lyd120" 
	        elseif age == "2-3周岁" then
	            eventName = "lyd121" 
	        elseif age == "3-4周岁" then
	            eventName = "lyd122" 
	        elseif age == "4-5周岁" then
	            eventName = "lyd123" 
	        elseif age == "5-6周岁" then
	            eventName = "lyd124" 
	        elseif age == "6周岁" then
	            eventName = "lyd125" 
	        end
	        DA.sendEvent(eventName, age.."单次启动点击的场景次数"..ST.getInteger("lyd120-126"))
	        ST.setInteger("lyd120-126", 0)
	    end
	end

	if not LYD127_133 then
		LYD127_133 = true
	    if ST.getInteger("lyd127_133") == nil then
	        ST.setInteger("lyd127_133", 0)
	    else
	        local age = game:getChildAge()
	        local eventName = "lyd133"
	        if age == "1-2周岁" then
	            eventName = "lyd127" 
	        elseif age == "2-3周岁" then
	            eventName = "lyd128" 
	        elseif age == "3-4周岁" then
	            eventName = "lyd129" 
	        elseif age == "4-5周岁" then
	            eventName = "lyd130" 
	        elseif age == "5-6周岁" then
	            eventName = "lyd131" 
	        elseif age == "6周岁" then
	            eventName = "lyd132" 
	        end
	        DA.sendEvent(eventName, age.."单次启动玩到喂食场景的次数"..ST.getInteger("lyd127_133"))
	        ST.setInteger("lyd127_133", 0)
	    end
	end
end

-- function M:test()
-- 	local icecream = D.img("icecream/icecreamball/111.png"):to(self,10000):p(300,300)
-- 	-- icecream:setOpacity(0)
-- 	local scoop = D.img("juicedecorate/moment/scoop1.png"):to(icecream,-1000):p(215,55)
-- 	local scoop1 = D.img("juicedecorate/moment/scoop4.png"):to(icecream,10000):p(87,13.5)
-- end


--加载背景
function M:loadBackground()
	--背景
	local bg = D.img("gameplay/bg.png"):to(self,-10):anchor(ccp(0,0)):p(0,0)
end


function M:loadTitle()
	local title = D.img("gameplay/title.png"):to(self,100):p(487,466)
	title:p(487,466 - CONFIG_OFFSET * 320)
	if device.language == "th" then
		if device.model == "ipad" then	
			title:scale(1.05)
			--title:p(520,466 - CONFIG_OFFSET * 320)	
		end
		title:p(520,466 - CONFIG_OFFSET * 320)
	else
		title:scale(1 - CONFIG_OFFSET * 0.8)
	end
	-- bindNodeTest(title)
end

function M:loadPlay()
	local pos = ccp(488 - 150, 150 - CONFIG_OFFSET * 90)
	if device.language == "zh" then
		pos = ccp(488, 123 - CONFIG_OFFSET * 90)
	end
	local play = D.img("gameplay/play.png"):to(self):p(pos)

	local scale = 1 - CONFIG_OFFSET * 0.8

	play:scale(scale)

	play:cycle({
		{"easing","out",{"scaleto",0.5,scale + 0.1},1},
        {"easing","out",{"scaleto",0.5,scale},1},
	})
	
	play:bindTouch()

	function play:onTouchBegan(x, y, touches)
		DA.sendEvent("zgxbb041", "首页-play键")
		sound.playSound("effect/click.mp3")
		self:stopAllActions()
		--删除评价
		if D.getRunningScene().wnode1_ then 
			D.getRunningScene().wnode1_:remove()
		end
		preSceneIsGameplay = 1
		--GAME_PLAY_TIME = GAME_PLAY_TIME - 3
		SCENE_CHANGING = true
		--game:enterScene("restaurant",{},"SlideInB_EX",2)
		if ST.getInteger("isFirstTouchPlayBtn") == nil then 
			DA.sendEvent("lyd162",game:getChildAge().."首次点击play键")
			ST.setInteger("isFirstTouchPlayBtn", 1)
			BABY_AGE = NV.getBabyAge()
		else
			if NV.getBabyAge() ~= BABY_AGE then
				DA.sendEvent("lyd162",game:getChildAge().."首次点击play键")
				BABY_AGE = NV.getBabyAge()
			end
		end
		game:enterScene("restaurant",{})
		return true
	end
end

function M:loadBtnMV()
	if device.language == "zh" then return end
	local mv = D.img("gameplay/mv.png"):to(self):p(488 + 150, 150 - CONFIG_OFFSET * 90)

	local scale = 1 - CONFIG_OFFSET * 0.8

	mv:scale(scale)

	mv:cycle({
		{"easing","out",{"scaleto",0.5,scale + 0.1},1},
        {"easing","out",{"scaleto",0.5,scale},1},
	})
	
	mv:bindTouch()
	function mv:onTouchBegan(x, y, touchs)
		DA.sendEvent("zgxbb042", "首页-视频键")
        -- local url = "https://www.youtube.com/watch?v=BRy04FgEdW4&list=PLPA49Pz3BAxOW0zW4xHxhZd3AI8gkzSqn&index=20"
        -- if device.language == "zht" then
        --     url = "https://www.youtube.com/watch?v=m-0G9P6PLH0&index=11&list=PLvoafAnklPjuy7Zy4WOY01zd2yT5kAoO2"
        -- end
        
        -- 新功能
        local pathBack = "res/img/x4/g/button/btn_back.png"
        if DEVICE_MODEL == "x2" then 
            pathBack = "res/img/x2/g/button/btn_back.png"
        end

        function nextScene()
            game:enterScene("gameplay")
        end

        -- local listkey = "PLPA49Pz3BAxOLq8HkfibIe5tyBbxSKJnm"
        -- if device.language == "zht" then
        --     listkey = "PLvoafAnklPjueS6c_cr8sLMLWzSB8SWTj"
        -- end
        NV.playYouTuBeList({
            -- url      = url.."&autoplay=1",
            -- listKey  = url,
            backPath = pathBack,
            callback = nextScene
        })
    end
end

function M:loadTree()
	local tree1 = self:createNode("Tree",{}):to(self):p(978,502)
	local tree2 = self:createNode("Tree",{}):to(self):p(-57,219)
	local tree3 = import("app.common.Tree").new():to(self):p(77,-92)
	tree2:setFlipX(true)
	-- bindNodeTest(tree3)
end





----------------------
-- 触控事件
----------------------
-- -- 触控开始
-- function M:onTouchBegan(x, y, touches)

--     return true 
-- end 

-- -- 触控移动
-- function M:onTouchMoved(x, y, touches)
    
-- end 

-- -- 触控结束
-- function M:onTouchEnded(x, y, touches)
    
-- end 


----------------------
-- 结点析构
----------------------
--[[--

视图析构，处理视图结点卸载、事件解除绑定等相关操作

]]
function M:onDestructor()
    -- [超类调用]
	M.super.onDestructor(self)

   
end



return M