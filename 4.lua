--[[

Copyright (c) 2012-2013 baby-bus.com

http://www.babybus.com/superdo/

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

动画工具类，定义动画相关操作方法及逻辑实现。

-   指定动画逻辑。
-   提供便捷生成动画接口。

]]

----------------------
-- 类
----------------------
local M = {}
M.TAG   = "UAction"


----------------------
-- 公共参数
----------------------
-- [常量]
-- ..

-- [操作变量]
-- 动作管理器
local actionManager = CCDirector:getInstance():getActionManager()
-- 暂停ID[动作]
local _idPause      = nil








----------------------
-- 动作(Transition)框架
----------------------
local ACTION_EASING = {}
ACTION_EASING["BACKIN"]           = {CCEaseBackIn, 1}
ACTION_EASING["BACKINOUT"]        = {CCEaseBackInOut, 1}
ACTION_EASING["BACKOUT"]          = {CCEaseBackOut, 1}
ACTION_EASING["BOUNCE"]           = {CCEaseBounce, 1}
ACTION_EASING["BOUNCEIN"]         = {CCEaseBounceIn, 1}
ACTION_EASING["BOUNCEINOUT"]      = {CCEaseBounceInOut, 1}
ACTION_EASING["BOUNCEOUT"]        = {CCEaseBounceOut, 1}
ACTION_EASING["ELASTIC"]          = {CCEaseElastic, 2, 0.3}
ACTION_EASING["ELASTICIN"]        = {CCEaseElasticIn, 2, 0.3}
ACTION_EASING["ELASTICINOUT"]     = {CCEaseElasticInOut, 2, 0.3}
ACTION_EASING["ELASTICOUT"]       = {CCEaseElasticOut, 2, 0.3}
ACTION_EASING["EXPONENTIALIN"]    = {CCEaseExponentialIn, 1}
ACTION_EASING["EXPONENTIALINOUT"] = {CCEaseExponentialInOut, 1}
ACTION_EASING["EXPONENTIALOUT"]   = {CCEaseExponentialOut, 1}
ACTION_EASING["IN"]               = {CCEaseIn, 2, 1}
ACTION_EASING["INOUT"]            = {CCEaseInOut, 2, 1}
ACTION_EASING["OUT"]              = {CCEaseOut, 2, 1}
ACTION_EASING["RATEACTION"]       = {CCEaseRateAction, 2, 1}
ACTION_EASING["SINEIN"]           = {CCEaseSineIn, 1}
ACTION_EASING["SINEINOUT"]        = {CCEaseSineInOut, 1}
ACTION_EASING["SINEOUT"]          = {CCEaseSineOut, 1}

--[[--

创建Easing对象，用于包装动作，使其实现缓慢、加速等效果。

### Useage:
    local action = UAction.newEasing(动作对象, Easing类名[, 其他参数])

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------

### Parameters:
-   UAction **action**      动作对象
-   string **easingName**   Easing类名
-   ... **more**            其他参数，用于覆盖定义的easing模板的默认值，如果未指定则使用默认值

### Returns: 
-   UAction                 包装Easing完成后的动作对象

--]]--
function M.newEasing(action, easingName, more)
    ---------------------------------------------------
    -- 策略：
    --      传递参数的策略，unpack{easing名称，参数一，参数二}
    ---------------------------------------------------
    -- 格式化key，获取除CCEASE后的字符串
    local key = string.upper(tostring(easingName))
    if string.sub(key, 1, 6) == "CCEASE" then
        key = string.sub(key, 7)
    end

    local easing
    -- 如果存在定义的Easing效果，则创建并返回
    if ACTION_EASING[key] then
        -- 获得Easing参数
        local cls, count, default = unpack(ACTION_EASING[key])
        -- 如果count为2，则调用2个参数的构造方法进行创建
        if count == 2 then
            easing = cls:create(action, more or default)
        else
            easing = cls:create(action)
        end
    end
    return easing or action
end

--[[--

创建复合动画对象。

### Useage:
    local action = UAction.create(参数集合)

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------

### Parameters:
-   UAction **action**      动作对象
-   ... **args**            参数集合

### Returns: 
-   UAction                 包装好的动作对象 

--]]--
function M.create(action, args)
    -- 格式化参数
    args = totable(args)
    if args.easing then
        if type(args.easing) == "table" then
            action = M.newEasing(action, unpack(args.easing))
        else
            action = M.newEasing(action, args.easing)
        end
    end


    -- 动作集合，用于后续执行一系列动作时调用 
    local actions = {}

    -- (1)处理延迟动作
    local delay = tonum(args.delay)
    if delay > 0 then
        actions[#actions + 1] = CCDelayTime:create(delay)
    end

    -- (2)处理实际动作
    actions[#actions + 1] = action

    -- (3)处理回调动作
    local onComplete = args.onComplete
    if type(onComplete) ~= "function" then onComplete = nil end
    if onComplete then
        actions[#actions + 1] = CCCallFunc:create(onComplete)
    end



    -- 如果动作集合 > 1，则构建动作序列，并执行相应的动作
    -- 如果动作集合 = 1，则直接执行相应的动作集[1]
    if #actions > 1 then
        return M.sequence(actions)
    else
        return actions[1]
    end
end

--[[--

执行目标对应的动作.

### Useage:
    local action = UAction.execute(参数集合)

### Aliases:

### Notice:
    UAction.execute() 是一个强大的工具，可以为原本单一的动作添加各种附加特性。
    UAction.execute() 的参数表格支持下列参数：
        delay: 等待多长时间后开始执行动作
        easing: 缓动效果的名字及可选的附加参数，效果名字不区分大小写
        onComplete: 动作执行完成后要调用的函数
        time: 执行动作需要的时间

    UAction.execute() 支持的缓动效果：
        backIn
        backInOut
        backOut
        bounce
        bounceIn
        bounceInOut
        bounceOut
        elastic, 附加参数默认为 0.3
        elasticIn, 附加参数默认为 0.3
        elasticInOut, 附加参数默认为 0.3
        elasticOut, 附加参数默认为 0.3
        exponentialIn, 附加参数默认为 1.0
        exponentialInOut, 附加参数默认为 1.0
        exponentialOut, 附加参数默认为 1.0
        In, 附加参数默认为 1.0
        InOut, 附加参数默认为 1.0
        Out, 附加参数默认为 1.0
        rateaction, 附加参数默认为 1.0
        sineIn
        sineInOut
        sineOut

### Usage:
    UAction.execute(显示对象, CCAction 动作对象, 参数表格对象)

### Example:
    -- 等待 1.0 后开始移动对象
    -- 耗时 1.5 秒，将对象移动到屏幕中央
    -- 移动使用 backout 缓动效果
    -- 移动结束后执行函数，显示 move completed
    UAction.execute(sprite, CCMoveTo:create(1.5, CCPoint(display.cx, display.cy)), {
        delay = 1.0,
        easing = "backout",
        onComplete = function()
            print("move completed")
        end,
    })

Note: **Other transiton methods can also use the same args parameters.**

### Parameters:
-   CCNode **target**                       目标对象
-   CCAction **action**                     动作对象
-   [_optional table **args**_]

### Returns: 
-   UAction                                 包装好的动作对象 

--]]--
function M.execute(target, action, args)
    assert(not tolua.isnull(target), "UAction.execute() - target is not CCNode")
    local action = M.create(action, args)
    target:runAction(action)
    return action
end

--[[--

播放帧动画（一次）
可设置对象自动清理、回调函数和延迟时间

### Useage:
    action = UAction.playAnimationOnce(
        显示对象,
        动画对象,
        [播放完成后删除显示对象],
        [播放完成后要执行的函数],
        [播放前等待的时间])

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- [调用示例－transition]
    local frames    = display.newFrames("Walk%04d.png", 1, 20)
    local animation = display.newAnimation(frames, 0.5 / 20) -- 0.5s play 20 frames
    UAction.playAnimationOnce(sprite, animation)

    -- [调用示例－sprite]
    local frames = display.newFrames("Walk%04d.png", 1, 20)
    local animation = display.newAnimation(frames, 0.5 / 20) -- 0.5s play 20 frames
    sprite:playAnimationOnce(animation)

    -- [调用示例－sprite]
    local frames = display.newFrames("Boom%04d.png", 1, 8)
    local boom = display.newSprite(frames[1])
    -- playAnimationOnce() 第二个参数为 true 表示动画播放完后删除 boom 这个 CCSprite 对象
    -- 这样爆炸动画播放完毕，就自动清理了不需要的显示对象
    boom:playAnimationOnce(display.newAnimation(frames, 0.3/ 8), true)

### Parameters:
-   CCNode **target**                       目标对象
-   CCAction **action**                     动作对象
-   [_optional table **args**_]

### Returns: 
-   UAction                                 包装好的动作对象 

--]]--
function M.playAnimationOnce(target, animation, removeWhenFinished, onComplete, delay)
    -- 定义动作集
    local actions = {}


    -- 处理动作[延迟显示]（注：这里采用的策略是先隐藏，等delay秒后再进行显示）
    if type(delay) == "number" and delay > 0 then
        target:setVisible(false)
        actions[#actions + 1] = CCDelayTime:create(delay)
        actions[#actions + 1] = CCShow:create()
    end


    -- 处理动作[animation帧切换]
    actions[#actions + 1] = CCAnimate:create(animation)


    -- 如果设置removeWhenFinished，则执行清理
    if removeWhenFinished then
        actions[#actions + 1] = CCRemoveSelf:create()
    end
    -- 如果设置onComplete，则执行回调
    if onComplete then
        actions[#actions + 1] = CCCallFunc:create(onComplete)
    end



    -- 如果动作集合 > 1，则构建动作序列，并执行相应的动作
    -- 如果动作集合 = 1，则直接执行相应的动作集[1]
    local action
    if #actions > 1 then
        action = transition.sequence(actions)
    else
        action = actions[1]
    end


    -- 执行动作序列
    target:runAction(action)
    return action
end

--[[--

播放帧动画（永远、无限循环）
可设置对象自动清理、回调函数和延迟时间

### Usage:
    local action = UAction.playAnimationForever(显示对象, 动画对象, [播放前等待的时间])

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- [调用示例]
    local frames = display.newFrames("Walk%04d.png", 1, 20)
    local animation = display.newAnimation(frames, 0.5 / 20) -- 0.5s play 20 frames
    sprite:playAnimationForever(animation)

### Parameters:
-   CCNode **target**                       目标对象
-   CCAnimation **animation**               动画对象
-   number **delay**                        延迟时间

### Returns: 
-   UAction                                 包装好的动作对象 

--]]--
function M.playAnimationForever(target, animation, delay)
    local animate = CCAnimate:create(animation)
    local action
    if type(delay) == "number" and delay > 0 then
        target:setVisible(false)
        local sequence = UAction.sequence({
            CCDelayTime:create(delay),
            CCShow:create(),
            animate,
        })
        action = CCRepeatForever:create(sequence)
    else
        action = CCRepeatForever:create(animate)
    end
    target:runAction(action)
    return action
end








----------------------
-- 动作(Tag)框架
----------------------
--[[== 动作名称类型映射关系表 ==]]--
M.ACTION_NAME_CLASS_MAPPER = {
    callfunc              = CCCallFunc,
    func                  = CCCallFunc,
    fn                    = CCCallFunc,
    show                  = CCShow,
    hide                  = CCHide,
    toggle                = CCToggleVisible,
    togglevisiblity       = CCToggleVisiblity,
    place                 = CCPlace,
    reusegrid             = CCReuseGrid,
    stopgrid              = CCStopGrid,
    flipx                 = CCFlipX,
    flipy                 = CCFlipY,
    follow                = CCFollow,
    speed                 = CCSpeed,
    blink                 = CCBlink,
    deccelamplitude       = CCDeccelAmplitude,
    bezierto              = CCBezierTo,
    bezierby              = CCBezierBy,
    delaytime             = CCDelayTime,
    delay                 = CCDelayTime,
    fadein                = CCFadeIn,
    fadeout               = CCFadeOut,
    fadeto                = CCFadeTo,
    gridaction            = CCGridAction,
    jumpto                = CCJumpTo,
    jumpby                = CCJumpBy,
    moveto                = CCMoveTo,
    moveby                = CCMoveBy,
    ovalby                = CCOvalBy,
    -- pathto                = CCPathTo,
    freefallby            = CCFreeFallBy,
    freefallto            = CCFreeFallTo,
    shake                 = CCShake,
    sinby                 = CCSinBy,
    sinto                 = CCSinTo,
    spiralby              = CCSpiralBy,
    spiralto              = CCSpiralTo,
    repeatnum             = CCRepeat,
    repeatforever         = CCRepeatForever,
    ever                  = CCRepeatForever,
    reversetime           = CCReverseTime,
    reverse               = CCReverseTime,
    rotateto              = CCRotateTo,
    rotateby              = CCRotateBy,
    scaleto               = CCScaleTo,
    scaleby               = CCScaleBy,
    skewto                = CCSkewTo,
    skewby                = CCSkewBy,
    sequence              = CCSequence,
    spawn                 = CCSpawn,
    tintto                = CCTintTo,
    tintby                = CCTintBy,
    orbitcamera           = CCOrbitCamera,
    accelamplitude        = CCAccelAmplitude,
    acceldeccelamplitude  = CCAccelDeccelAmplitude,
    actioncamera          = CCActionCamera,
    cardinalsplineby      = CardinalSplineBy,
    cardinalsplineto      = CardinalSplineTo,
    catmullromby          = CCCatmullRomBy,
    catmullromto          = CCCatmullRomTo,
    actionease            = CCActionEase,
    animate               = CCAnimate,
    progressfromto        = CCProgressFromTo,
    progressto            = CCProgressTo,
    waves                 = CCWaves,
    shaky3d               = CCShaky3D,
    removeself            = CCRemoveSelf,
    remove                = CCRemoveSelf,
    stop                  = nil,
    delete                = nil,
    kill                  = nil,
    frame                 = nil,
    file                  = nil,
    image                 = nil,
    imagerange            = nil,
    framenames            = nil,
    filenames             = nil,
    imagenames            = nil,
    framerepeat           = nil,
    filerepeat            = nil,
    imagerepeat           = nil,
    framenamesrepeat      = nil,
    filenamesrepeat       = nil,
    imagenamesrepeat      = nil,
    frame_repeat          = nil,
    file_repeat           = nil,
    image_range           = nil,
    framenames_repeat     = nil,
    filenames_repeat      = nil,
    imagerange_repeat     = nil,
    callback              = nil,
    display               = nil,
    movearound            = nil,
    moveangle             = nil,
    roundby               = nil,
    ovalby                = nil,
    shake                 = nil,
    echo                  = nil,
    line                  = nil,
    union                 = nil,
    cycle                 = nil,
    sound                 = nil,
    unsound               = nil,
    unmusic               = nil,
    music                 = nil,
    easing                = nil,
    easein                = CCEaseIn,
    easeout               = CCEaseOut,
    easeinout             = CCEaseInOut,
    easeexponentialin     = CCEaseExponentialIn,
    easeexponentialout    = CCEaseExponentialOut,
    easeexponentialinout  = CCEaseExponentialInOut,
    easesinein            = CCEaseSineIn,
    easesineout           = CCEaseSineOut,
    easesineinout         = CCEaseSineInOut,
    easeelasticin         = CCEaseElasticIn,
    easeelasticout        = CCEaseElasticOut,
    easeelasticinout      = CCEaseElasticInOut,
    easebouncein          = CCEaseBounceIn,
    easebounceout         = CCEaseBounceOut,
    easebounceinout       = CCEaseBounceInOut,
    easebackin            = CCEaseBackIn,
    easebackout           = CCEaseBackOut,
    easebackinout         = CCEaseBackInOut,
}

--[[== 动作名称: CCCallFunc ==]]--
M.NAME_CALLFUNC                 = "callfunc"
--[[== 动作名称: CCCallFunc ==]]--
M.NAME_FUNC                     = "func"
--[[== 动作名称: CCCallFunc ==]]--
M.NAME_FN                       = "fn"
--[[== 动作名称: CCShow ==]]--
M.NAME_SHOW                     = "show"
--[[== 动作名称: CCHide ==]]--
M.NAME_HIDE                     = "hide"
--[[== 动作名称: CCToggleVisible ==]]--
M.NAME_TOGGLE                   = "toggle"
--[[== 动作名称: CCToggleVisiblity ==]]--
M.NAME_TOGGLEVISIBLITY          = "togglevisiblity"
--[[== 动作名称: CCPlace ==]]--
M.NAME_PLACE                    = "place"
--[[== 动作名称: CCReuseGrid ==]]--
M.NAME_REUSEGRID                = "reusegrid"
--[[== 动作名称: CCStopGrid ==]]--
M.NAME_STOPGRID                 = "stopgrid"
--[[== 动作名称: CCFlipX ==]]--
M.NAME_FLIPX                    = "flipx"
--[[== 动作名称: CCFlipY ==]]--
M.NAME_FLIPY                    = "flipy"
--[[== 动作名称: CCFollow ==]]--
M.NAME_FOLLOW                   = "follow"
--[[== 动作名称: CCSpeed ==]]--
M.NAME_SPEED                    = "speed"
--[[== 动作名称: CCBlink ==]]--
M.NAME_BLINK                    = "blink"
--[[== 动作名称: CCDeccelAmplitude ==]]--
M.NAME_DECCELAMPLITUDE          = "deccelamplitude"
--[[== 动作名称: CCBezierTo ==]]--
M.NAME_BEZIERTO                 = "bezierto"
--[[== 动作名称: CCBezierBy ==]]--
M.NAME_BEZIERBY                 = "bezierby"
--[[== 动作名称: CCDelayTime ==]]--
M.NAME_DELAYTIME                = "delaytime"
--[[== 动作名称: CCDelayTime ==]]--
M.NAME_DELAY                    = "delay"
--[[== 动作名称: CCFadeIn ==]]--
M.NAME_FADEIN                   = "fadein"
--[[== 动作名称: CCFadeOut ==]]--
M.NAME_FADEOUT                  = "fadeout"
--[[== 动作名称: CCFadeTo ==]]--
M.NAME_FADETO                   = "fadeto"
--[[== 动作名称: CCGridAction ==]]--
M.NAME_GRIDACTION               = "gridaction"
--[[== 动作名称: CCJumpTo ==]]--
M.NAME_JUMPTO                   = "jumpto"
--[[== 动作名称: CCJumpBy ==]]--
M.NAME_JUMPBY                   = "jumpby"
--[[== 动作名称: CCMoveTo ==]]--
M.NAME_MOVETO                   = "moveto"
--[[== 动作名称: CCMoveBy ==]]--
M.NAME_MOVEBY                   = "moveby"
--[[== 动作名称: CCRepeat ==]]--
M.NAME_REPEATX                  = "repeatx"
--[[== 动作名称: CCRepeatForever ==]]--
M.NAME_REPEATFOREVER            = "repeatforever"
--[[== 动作名称: CCRepeatForever ==]]--
M.NAME_EVER                     = "ever"
--[[== 动作名称: CCReverseTime ==]]--
M.NAME_REVERSETIME              = "reversetime"
--[[== 动作名称: CCReverseTime ==]]--
M.NAME_REVERSE                  = "reverse"
--[[== 动作名称: CCRotateTo ==]]--
M.NAME_ROTATETO                 = "rotateto"
--[[== 动作名称: CCRotateBy ==]]--
M.NAME_ROTATEBY                 = "rotateby"
--[[== 动作名称: CCScaleTo ==]]--
M.NAME_SCALETO                  = "scaleto"
--[[== 动作名称: CCScaleBy ==]]--
M.NAME_SCALEBY                  = "scaleby"
--[[== 动作名称: CCSkewTo ==]]--
M.NAME_SKEWTO                   = "skewto"
--[[== 动作名称: CCSkewBy ==]]--
M.NAME_SKEWBY                   = "skewby"
--[[== 动作名称: CCSequence ==]]--
M.NAME_SEQUENCE                 = "sequence"
--[[== 动作名称: CCSpawn ==]]--
M.NAME_SPAWN                    = "spawn"
--[[== 动作名称: CCTintTo ==]]--
M.NAME_TINTTO                   = "tintto"
--[[== 动作名称: CCTintBy ==]]--
M.NAME_TINTBY                   = "tintby"
--[[== 动作名称: CCAccelAmplitude ==]]--
M.NAME_ACCELAMPLITUDE           = "accelamplitude"
--[[== 动作名称: CCAccelDeccelAmplitude ==]]--
M.NAME_ACCELDECCELAMPLITUDE     = "acceldeccelamplitude"
--[[== 动作名称: CCActionCamera ==]]--
M.NAME_ACTIONCAMERA             = "actioncamera"
--[[== 动作名称: CCActionEase ==]]--
M.NAME_ACTIONEASE               = "actionease"
--[[== 动作名称: CCAnimate ==]]--
M.NAME_ANIMATE                  = "animate"
--[[== 动作名称: CCProgressFromTo ==]]--
M.NAME_PROGRESSFROMTO           = "progressfromto"
--[[== 动作名称: CCProgressTo ==]]--
M.NAME_PROGRESSTO               = "progressto"
--[[== 动作名称: nil ==]]--
M.NAME_STOP                     = "stop"
--[[== 动作名称: nil ==]]--
M.NAME_REMOVE                   = "remove"
--[[== 动作名称: nil ==]]--
M.NAME_DELETE                   = "delete"
--[[== 动作名称: nil ==]]--
M.NAME_KILL                     = "kill"
--[[== 动作名称: nil ==]]--
M.NAME_FRAME                    = "frame"
--[[== 动作名称: nil ==]]--
M.NAME_FILE                     = "file"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGE                    = "image"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGERANGE               = "imagerange"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGE_RANGE              = "image_range"
--[[== 动作名称: nil ==]]--
M.NAME_FRAMENAMES               = "framenames"
--[[== 动作名称: nil ==]]--
M.NAME_FILENAMES                = "filenames"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGENAMES               = "imagenames"
--[[== 动作名称: nil ==]]--
M.NAME_FRAMEREPEAT              = "framerepeat"
--[[== 动作名称: nil ==]]--
M.NAME_FILEREPEAT               = "filerepeat"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGEREPEAT              = "imagerepeat"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGERANGEREPEAT         = "imagerangerepeat"
--[[== 动作名称: nil ==]]--
M.NAME_FRAMENAMESREPEAT         = "framenamesrepeat"
--[[== 动作名称: nil ==]]--
M.NAME_FILENAMESREPEAT          = "filenamesrepeat"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGENAMESREPEAT         = "imagenamesrepeat"
--[[== 动作名称: nil ==]]--
M.NAME_FRAME_REPEAT             = "frame_repeat"
--[[== 动作名称: nil ==]]--
M.NAME_FILE_REPEAT              = "file_repeat"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGE_REPEAT             = "image_repeat"
--[[== 动作名称: nil ==]]--
M.NAME_FRAMENAMES_REPEAT        = "framenames_repeat"
--[[== 动作名称: nil ==]]--
M.NAME_FILENAMES_REPEAT         = "filenames_repeat"
--[[== 动作名称: nil ==]]--
M.NAME_IMAGENAMES_REPEAT        = "imagenames_repeat"
--[[== 动作名称: nil ==]]--
M.NAME_CALLBACK                 = "callback"
--[[== 动作名称: nil ==]]--
M.NAME_DISPLAY                  = "display"
--[[== 动作名称: nil ==]]--
M.NAME_MOVEAROUND               = "movearound"
--[[== 动作名称: nil ==]]--
M.NAME_MOVEANGLE                = "moveangle"
--[[== 动作名称: nil ==]]--
M.NAME_ROUNDBY                  = "roundby"
--[[== 动作名称: nil ==]]--
M.NAME_OVALBY                   = "ovalby"
--[[== 动作名称: nil ==]]--
M.NAME_SHAKE                    = "shake"
--[[== 动作名称: nil ==]]--
M.NAME_ECHO                     = "echo"
--[[== 动作名称: nil ==]]--
M.NAME_EASING                   = "easing"
--[[== 动作名称: CCEaseIn ==]]--
M.NAME_EASEIN                   = "easein"
--[[== 动作名称: CCEaseOut ==]]--
M.NAME_EASEOUT                  = "easeout"
--[[== 动作名称: CCEaseInOut ==]]--
M.NAME_EASEINOUT                = "easeinout"
--[[== 动作名称: CCEaseExponentialIn ==]]--
M.NAME_EASEEXPONENTIALIN        = "easeexponentialin"
--[[== 动作名称: CCEaseExponentialOut ==]]--
M.NAME_EASEEXPONENTIALOUT       = "easeexponentialout"
--[[== 动作名称: CCEaseExponentialInOut ==]]--
M.NAME_EASEEXPONENTIALINOUT     = "easeexponentialinout"
--[[== 动作名称: CCEaseSineIn ==]]--
M.NAME_EASESINEIN               = "easesinein"
--[[== 动作名称: CCEaseSineOut ==]]--
M.NAME_EASESINEOUT              = "easesineout"
--[[== 动作名称: CCEaseSineInOut ==]]--
M.NAME_EASESINEINOUT            = "easesineinout"
--[[== 动作名称: CCEaseElasticIn ==]]--
M.NAME_EASEELASTICIN            = "easeelasticin"
--[[== 动作名称: CCEaseElasticOut ==]]--
M.NAME_EASEELASTICOUT           = "easeelasticout"
--[[== 动作名称: CCEaseElasticInOut ==]]--
M.NAME_EASEELASTICINOUT         = "easeelasticinout"
--[[== 动作名称: CCEaseBounceIn ==]]--
M.NAME_EASEBOUNCEIN             = "easebouncein"
--[[== 动作名称: CCEaseBounceOut ==]]--
M.NAME_EASEBOUNCEOUT            = "easebounceout"
--[[== 动作名称: CCEaseBounceInOut ==]]--
M.NAME_EASEBOUNCEINOUT          = "easebounceinout"
--[[== 动作名称: CCEaseBackIn ==]]--
M.NAME_EASEBACKIN               = "easebackin"
--[[== 动作名称: CCEaseBackOut ==]]--
M.NAME_EASEBACKOUT              = "easebackout"
--[[== 动作名称: CCEaseBackInOut ==]]--
M.NAME_EASEBACKINOUT            = "easebackinout"

-- Action扩展方法
local function _extendAction(self)
    if not self.at then 
        function self:at(node)
            node:runAction(self)
            return self
        end
    end

    if not self.stopBy then 
        function self:stopBy(node)
            node:stopAction(self)
            return self
        end
    end

    return self
end

--[[--

顺序执行动作集

### Useage:
    UAction.line(对象集)

### Notice:
    UAction.line({
        动作信息对象1,
        动作信息对象2,
        ...
    })

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：执行动画: 延迟1秒后播放帧动画, 播放完毕后移动到位置(10, 10)处, 进行放大, 最后执行回调函数 >>
    A.line({
        { "delay", 1.0 },
        { "frame", "anim_", 10, .1 } }, 
        { "moveTo", ccp(10, 10) },
        { "scaleTo", 2.0, 2.0 },
        { "fn", 
            function() 

            end 
        },
        ...
    })

### Parameters:
-   table **params**        配置参数集合(二维)

### Returns: 
-   CCAction                动作对象

--]]--
function M.line(params)
    local actions = M.analyzeActions(params)
    return _extendAction(M.sequence(actions))
end

--[[--

同时执行动作集

### Useage:
    UAction.union({
        动作信息对象1,
        动作信息对象2,
        ...
    })

### Notice:

### Example:
    A.union({
        { "delay", 1.0 },
        { "frame", "anim_", 10, .1 } },   
        { "moveTo", ccp(10, 10) },
        { "scaleTo", 2.0, 2.0 },
        { "fn", 
            function() 

            end 
        },
        ...
    })

### Parameters:
-   table **params**        配置参数集合(二维)

### Returns: 
-   CCAction                动作对象

--]]--
function M.union(params)
    local actions = M.analyzeActions(params)
    return _extendAction(M.spawn(actions))
end
M.with = M.union

--[[--

顺序并循环执行动作集

### Useage:
    local action = UAction.cycle({
        动作信息对象1,
        动作信息对象2,
        ...
    }, num)

### Notice:

### Example:
    A.cycle({
        { "delay", 1.0 },
        { "frame", { prefix = "anim_", frameCount = 10, interval = .1 } },   
        { "moveTo", ccp(10, 10) },
        { "scaleTo", 2.0 },
        { "func", function() end },
        { "easing", "SineIn", { "moveTo", ccp(10, 10) }, 0.3 },
        ...
    })
    
### Parameters:
-   table **params**    配置参数集合(二维)
-   number **num**      重复次数

### Returns: 
-   CCAction            动作对象

--]]--
function M.cycle(params, num)
    local actions = M.analyzeActions(params)
    return _extendAction(M.sequenceRepeat(actions, num))
end

--[[--

执行单个动作

### Useage:
    UAction.one(动作信息对象)

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    A.one({ "moveTo", 1.0, ccp(100, 100) }):at(node)


    ----------------------
    -- 示例2: 跨度选择图片
    ----------------------
    -- TEXTURE
    local node = D.imgc("node.png"):to(layer)
    node:one({ "image_range", "box2/img", 10, 5, 1.0 / 12, "jpg" })

    -- FRAME
    R.loadFrames("demo/mia")
    local node = D.imgc("node.png"):to(layer)
    node:one({ "image_range", "#mia", 1, 3, 1.0 / 12 })


    ----------------------
    -- 示例3: 螺旋
    ----------------------
    A.one({ "SpiralTo", 2.0, ccp(500, 500), true, 10 }):at(node)


    ----------------------
    -- 示例4: 波形移动
    ----------------------
    A.one({ "SinTo", 1.0, ccp(800, V.cy), 100, 3, }):at(node)


    ----------------------
    -- 示例5: 路径移动
    ----------------------
    local points = {
        ccp(0, 0),
        ccp(200, 430),
        ccp(300, 200),
        ccp(140, 20),
        ccp(400, 90),
    }
    A.one({ "PathTo", 3.0, points }):at(node)


    ----------------------
    -- 示例6: 自由落体
    ----------------------
    A.one({ "FreeFallTo", ccp(0, 0) }):at(node)


    ----------------------
    -- 示例7: 水波
    ----------------------
    A.one({ "Waves", 5, CCSize(15, 10), 20, 5, true, false }):at(node)


    ----------------------
    -- 示例8: 3D震动
    ----------------------
    A.one({ "Shaky3D", 4, CCSize(15,10), 5, false, }):at(node)


    ----------------------
    -- 示例9: 球面轨迹运动
    ----------------------
    -- 参数1：执行时间 
    -- 参数2：起始半径
    -- 参数3：半径差
    -- 参数4：起始Z角
    -- 参数5：旋转Z角差
    -- 参数6：起始X角
    -- 参数7：旋转X角差
    A.one({ "OrbitCamera", 2, 1, 0, 0, 180, 0, 0, }):at(node)


    ----------------------
    -- 示例10: 切换图像
    ----------------------
    -- 添加按钮
    local button = U.loadButton({
        images      = "node.png",                   -- 按钮图片
        texts       = "Hello, World",               -- 标签文字
        fnClicked   = function(sender, x, y, touches)      -- 事件函数[点击]
            A.one({ 
                "switchimage",
                node,
                { 
                    "samples/button/btn-a-1.png",
                    "samples/button/btn-a-2.png",
                    "samples/button/btn-a-3.png",
                },
            }):at(node)
        end,
    }):p(100, 100):to(layer)


    ----------------------
    -- 示例11: 粒子效果
    ----------------------
    -- 添加粒子效果
    A.one({
        "particle",
        "samples/particle/common.plist",
        node,
    }):at(node)

### Parameters:
-   table **params**    配置参数(一维)

### Returns: 
-   CCAction            动作对象

--]]--
function M.one(params)
    return _extendAction(M.analyzeAction(params))
end
M.run = M.one

--[[--

反向执行单个动作

### Useage:
    UAction.reverse(动作信息对象)

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    A.reverse({ "moveTo", 1.0, ccp(100, 100) }):at(node)


    ----------------------
    -- 示例2: 串连操作
    ----------------------
    local action = A.one({ "moveTo", 1.0, ccp(100, 100) })
    A.line({
        action,
        { "fn", 
            function()
                A.one(action:reverse()):at(node)
            end 
        }
    })
    :at(node)

### Parameters:
-   table **params**    配置参数(一维)

### Returns: 
-   CCAction            动作对象

--]]--
function M.reverse(params)
    return _extendAction(CCReverseTime:create(M.analyzeAction(params)))
end

--[[--

解析动作信息, 生成动作对象

### Useage:
    UAction.analyzeAction(动作信息对象)

### Notice:

### Example:
    ----------------------
    -- 示例1: 动作－来回运动
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()
    -- 创建结点
    local node = D.imgc("node.png"):to(layer)
    -- 执行动作
    A.line({
        { "music", "music/box/box_bg.mp3" },
        { "union", { 
            { "moveto",  1.0, ccp(100, 100) },
            { "scaleto", 1.0, 2.0 },
        }},
        { "cycle", {
            { "rotateby", 1.0, 360, }
        }, -1 }
    }):at(node)


    ----------------------
    -- 示例2: 动作－来回运动
    ----------------------
    node:one({ "movearound", node, 5, ccp(0, 50), .1 })


    ----------------------
    -- 示例3: 动作－旋转运动
    ----------------------
    node:one({ "moveangle", node, 5, 60, 10 })


    ----------------------
    -- 示例4: 动作－缓慢＋回退
    ----------------------
    node:one({ "easing", "backout", { "moveTo", 1.0, ccp(100, 100) }, })


    ----------------------
    -- 示例5: 复合动作
    ----------------------
    -- 顺序执行一组动作
    --     1.同时执行以下动作
    --         -1.闪烁
    --         -2.放大2倍
    --         -3.播放背景音乐
    --     2.播放图片动画
    --     3.更改颜色
    --     4.球面轨迹旋转
    node:one(
    { "line", 
        {
            { "union", 
                {
                    { "Blink", 1.0, 10 },
                    { "ScaleBy", 1.0, 2.0 },
                    { "Music", "a/b/1.mp3" },
                } 
            },
            { "Image", "prefix_", 10, 0.1, "png" },
            { "TintBy", 1.0, 255, 255, 0 },
            { "OrbitCamera", 1.0,10.0, 0,45.0, 180.0, 90.0, 0 },
        } 
    })
    
### Parameters:
-   table **params**    配置参数(一维)

### Returns: 
-   CCAction            动作对象

--]]--
function M.analyzeAction(v)
    -----------------------------------------------------------------------------
    -- 意图：
    --      根据配置生成Action
    --
    -- 意图：
    --      判断传入的参数是否是table类型
    --      是：
    --          则进行配置解析，解析格式{ 动作名称，参数1, 参数2... }
    --      否：
    --          则表示传入的是一个Action
    -----------------------------------------------------------------------------
    local action = nil

    if type(v) == "table" and type(v[1]) == "string" then 
        local name   = string.lower(v[1])
        local clazz  = M.ACTION_NAME_CLASS_MAPPER[name]
        table.remove(v,1)

        if clazz then 
            action = clazz:create(unpack(v))
        elseif name == "stop" then 
            action = cc.CallFunc:create(function() 
                if type(v[1]) == "table" then 
                    for _,vv in pairs(v[1]) do
                        vv:stop()
                    end 
                else
                    v[1]:stop()
                end
            end)
        elseif name == "delete" or name == "kill" then 
            action = cc.CallFunc:create(function() for _,vv in pairs(v) do
                vv:removeFromParentAndCleanup(true)
            end end)
        elseif name == "frame" then 
            action = M.actionFrame({ prefix = v[1], num = v[2], interval = v[3] or (1.0/12), extension = v[4] or "png" })
        elseif name == "file" then 
            action = M.actionFile({ prefix = v[1], num = v[2], interval = v[3] or (1.0/12), extension = v[4] or "png" })
        elseif name == "image" then 
            action = M.actionImage({ prefix = v[1], num = v[2], interval = v[3] or (1.0/12), extension = v[4] or "png" })
        elseif name == "imagerange" or name == "image_range" then 
            action = M.actionImageRange({ prefix = v[1], start = v[2], length = v[3], interval = v[4] or (1.0/12), extension = v[5] or "png" })
        elseif name == "framenames" then 
            action = M.actionFrameNames({ names = v[1], interval = v[2] or (1.0/12), })
        elseif name == "filenames" then 
            action = M.actionFileNames({ names = v[1], interval = v[2] or (1.0/12), })
        elseif name == "imagenames" then 
            action = M.actionImageNames({ names = v[1], interval = v[2] or (1.0/12), })
        elseif name == "framerepeat" or name == "frame_repeat" then 
            action = M.actionFrameRepeat({ prefix = v[1], num = v[2], interval = v[3] or (1.0/12), extension = v[4] or "png" })
        elseif name == "filerepeat" or name == "file_repeat" then 
            action = M.actionFileRepeat({ prefix = v[1], num = v[2], interval = v[3] or (1.0/12), extension = v[4] or "png" })
        elseif name == "imagerepeat" or name == "image_repeat" then 
            action = M.actionImageRepeat({ prefix = v[1], num = v[2], interval = v[3] or (1.0/12), extension = v[4] or "png" })
        elseif name == "imagerangerepeat" or name == "imagerange_repeat" or name == "image_range_repeat" then 
            action = M.actionImageRangeRepeat({ prefix = v[1], start = v[2], length = v[3], interval = v[4] or (1.0/12), extension = v[5] or "png" })
        elseif name == "framenamesrepeat" or name == "framenames_repeat" then 
            action = M.actionFrameNamesRepeat({ names = v[1], interval = v[2] or (1.0/12), })
        elseif name == "filenamesrepeat" or name == "filenames_repeat" then 
            action = M.actionFileNamesRepeat({ names = v[1], interval = v[2] or (1.0/12), })
        elseif name == "imagenamesrepeat" or name == "imagenames_repeat" then 
            action = M.actionImageNamesRepeat({ names = v[1], interval = v[2] or (1.0/12), })
        elseif name == "callback" then 
            action = CCCallFunc:create(function() if type(v[1]) == "function" then v[1]() end end)
        elseif name == "display" then 
            action = CCCallFunc:create(function() v[1]:display(v[2]) end)
        elseif name == "movearound" or name == "move_around" then 
            action = M.actionMoveAround({ deltaTime = v[1], delta = v[2], center = v[3], times = v[4], startDirection = v[5], increase = v[6], increaseMode = v[7], })
        elseif name == "moveangle" or name == "move_angle" then 
            action = M.actionMoveAngle({ time = v[1], pointZero = v[2], angle = v[3], velocity = v[4], })
        elseif name == "roundby" or name == "moveround" then 
            action = M.actionOvalBy({ time = v[1], pointCenter = v[2], side = v[3], isClockwise = v[4], angle = v[5], })
        elseif name == "oval_by" or name == "moveoval" then 
            action = M.actionOvalBy({ time = v[1], pointCenter = v[2], sideA = v[3], sideB = v[4], isClockwise = v[5], angle = v[6], })
        elseif name == "shake" then 
            action = M.actionShake({ time = v[1], strengthX = v[2], strengthY = v[3], })
        elseif name == "pathto" then 
            action = CCPathTo:create(v[1], bb.t2pointarray(v[2]))
        elseif name == "echo" then 
            action = CCCallFunc:create(function() print(v[1]) end)
        elseif name == "sound" then 
            action = CCCallFunc:create(function() sound.playSound(v[1]) end)
        elseif name == "unsound" then 
            action = CCCallFunc:create(function() sound.stopSound(v[1]) end)
        elseif name == "music" then 
            action = CCCallFunc:create(function() sound.playMusic(v[1], ifnil(v[2], true)) end)
        elseif name == "unmusic" then 
            action = CCCallFunc:create(function() sound.stopMusic(v[1]) end)
        elseif name == "switchimage" then 
            action = CCCallFunc:create(function() M.switchImage({ node = v[1], images = v[2], clear = v[3], }) end)
        elseif name == "particle" then 
            action = M.actionParticle({ path = v[1], node = v[2], position = v[3], z = v[4] })
        elseif name == "movegoback" then 
            action = M.actionMoveGoBack({ time = v[1], position = v[2], node = v[3], })
        elseif name == "scalegoback" then 
            action = M.actionScaleGoBack({ time = v[1], scale = v[2], node = v[3], })
        elseif name == "rotategoback" then 
            action = M.actionRotateGoBack({ time = v[1], rotation = v[2], node = v[3], })
        elseif name == "cardinalsplinetolua" then 
            action = CCCardinalSplineTo:create(v[1], bb.t2pointarray(v[2]), 1)
        elseif name == "cardinalsplinebylua" then 
            action = CCCardinalSplineBy:create(v[1], bb.t2pointarray(v[2]), 1)
        elseif name == "catmullromtolua" then 
            action = CCCatmullRomTo:create(v[1], bb.t2pointarray(v[2]))
        elseif name == "catmullrombylua" then 
            action = CCCatmullRomBy:create(v[1], bb.t2pointarray(v[2]))
        elseif name == "bezier" then 
            action = A.actionBezierTo({ time = v[1], startPosition = v[2], endPosition= v[3], })
        elseif name == "one" then 
            action = M.one(v[1])
        elseif name == "line" then 
            action = M.line(v[1])
        elseif name == "union" then 
            action = M.union(v[1])
        elseif name == "cycle" then 
            action = M.cycle(v[1], v[2])
        elseif name == "go_app" then 
            action = CCCallFunc:create(function() game:enterScene(v[1], v[2], v[3], v[4], v[5]) end)
        elseif name == "go_ccb" then 
            action = CCCallFunc:create(function() CCBCenter.replaceScene("MSG_" .. S.upper(v[1]) .. "_MODEL", "ccb.c.ue." .. S.upper(v[1]) .. "Controller", nil, nil, v[2], v[3], v[4]) end)
        elseif name == "easing" then
            local nameEasing  = "ease" .. string.lower(v[1])
            local clazzEasing = M.ACTION_NAME_CLASS_MAPPER[nameEasing]
            local vv = v[2]
            table.remove(v,1)
            table.remove(v,1)

            action = clazzEasing:create(M.analyzeAction(vv), unpack(v))
        end
    else
        action = v
    end

    return action
end

--[[--

解析动作信息集合, 生成动作对象

### Useage:
    UAction.analyzeActions({
        动作信息对象1,
        动作信息对象2,
        ...
    })

### Notice:

### Example:
    
### Parameters:
-   table **params**    配置参数集合(二维)

### Returns: 
-   CCAction            动作对象

--]]--
function M.analyzeActions(params)
    -- [参数验证]
    -- 验证配置参数必须为table类型
    J.typeTable(M.TAG, params)
    -- 验证配置参数必须不为空
    J.tableNotEmpty(M.TAG, params)


    local actions = {}
    -- [配置解析]
    for _,v in ipairs(params) do
        local action = M.analyzeAction(v)
        if not action then 
            -- 当调度级别>1时，输出日志信息
            if DEBUG > 1 then
                echoInfo("ERROR: error action created!", unpack(v))
            end
            echoError("ERROR: error action created!")
        end

        table.insert(actions, action)
    end

    return actions
end

--[[--

生成合并动作

### Useage:
    UAction.spawn({
        动作1,
        动作2,
        ...
    })

### Notice:

### Example:
    -- [调用示例]
    -- 回调函数
    local function onComplete()
        echo("SPAWN COMPLETED")
    end

    -- 创建Action序列
    local action = UAction.spawn({
        CCMoveBy:create(sprite, ccp(100, 0)),   -- 向右移动
        CCDelayTime:create(1.0),                -- 延迟1秒
        CCMoveBy:create(sprite, ccp(0, 100)),   -- 向上移动
        CCCallFunc:create(onComplete),          -- 回调函数
    })

    -- 执行动作
    sprite:runAction(action)

### Parameters:
-   table **actions**       动作集

### Returns: 
-   CCAction                动作对象

--]]--
function M.spawn(actions)
    if #actions < 1 then return end
    if #actions < 2 then return actions[1] end

    local prev = actions[1]
    for i = 2, #actions do
        prev = cc.Spawn:create(prev, actions[i])
    end
    return prev
end

--[[--

生成序列动作

### Useage:
    local action = UAction.sequence({
        动作1,
        动作2,
        ...
    })

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：执行动作>>
    -- 回调函数
    local function onComplete()
        echo("SEQUENCE COMPLETED")
    end

    -- 创建Action序列
    local action = UAction.sequence({
        CCMoveBy:create(sprite, ccp(100, 0)),   -- 向右移动
        CCDelayTime:create(1.0),                -- 延迟1秒
        CCMoveBy:create(sprite, ccp(0, 100)),   -- 向上移动
        CCCallFunc:create(onComplete),          -- 回调函数
    })

    -- 执行动作
    sprite:runAction(action)

### Parameters:
-   table **actions**       动作集

### Returns: 
-   CCAction                动作对象

--]]--
function M.sequence(actions)
    if #actions < 1 then return end
    if #actions < 2 then return actions[1] end

    local prev = actions[1]
    for i = 2, #actions do
        prev = CCSequence:create(prev, actions[i])
    end
    return prev
end

--[[--

生成重复序列动作

### Useage:
    local action = UAction.sequenceRepeat(动作集, 重复次数)

### Notice:

### Example:
    local action = UAction.sequenceRepeat({
        CCMoveTo:create(1.0, V.POINTS.CENTER),
        CCScaleTo:create(1.0, 2.0),
        ...
    }, 10)

### Parameters:
-   table **actions**       动作集
-   number **num**          重复次数，默认为无限循环

### Returns: 
-   CCAction                动作对象

--]]--
function M.sequenceRepeat(actions, num)
    if isnumber(num) then 
        return CCRepeat:create(transition.sequence(actions), num)
    else
        return CCRepeatForever:create(transition.sequence(actions))
    end
end









----------------------
-- 基础动作
----------------------
--[[--

旋转精灵到指定旋转角度。 

### Example:

### Parameters:
-   CCNode **target**
-   table **args**

]]
function M.rotateTo(target, args)
    assert(not tolua.isnull(target), "UAction.rotateTo() - target is not CCNode")
    -- local rotation = args.rotate
    local action = CCRotateTo:create(args.time, args.rotate)
    return M.execute(target, action, args)
end

--[[--

移动精灵到指定位置x，y。 x和y是通过修改它的位置属性的绝对坐标。

### Example:
    -- [调用示例]
    -- 移动精灵到(100, 100)
    UAction.moveTo(sprite, {time = 2.0, x = 100, y = 100})

    -- 移动到屏幕中心
    UAction.moveTo(sprite, {x = display.cx, y = display.cy, time = 1.5})
    -- 移动到屏幕左边，不改变 y
    UAction.moveTo(sprite, {x = display.left, time = 1.5})
    -- 移动到屏幕底部，不改变 x
    UAction.moveTo(sprite, {y = display.bottom, time = 1.5})

### Parameters:
-   CCNode **target**
-   table **args**

]]
function M.moveTo(target, args)
    assert(not tolua.isnull(target), "UAction.moveTo() - target is not CCNode")
    local tx, ty = target:getPosition()
    local x = args.x or tx
    local y = args.y or ty
    local action = CCMoveTo:create(args.time, CCPoint(x, y))
    return M.execute(target, action, args)
end

--[[--

移动精灵x，y点，通过修改它的位置属性。 x和y是相对于该对象的位置。

### Example:

    -- [调用示例]
    -- 向右上方向移动
    UAction.moveBy(sprite, {time = 2.0, x = 100, y = 100})

    -- 向右移动 100 点，向上移动 100 点
    UAction.moveBy(sprite, {x = 100, y = 100, time = 1.5})
    -- 向左移动 100 点，不改变 y
    UAction.moveBy(sprite, {x = -100, time = 1.5})
    -- 向下移动 100 点，不改变 x
    UAction.moveBy(sprite, {y = -100, time = 1.5})

### Parameters:
-   CCNode **target**
-   table **args**

]]
function M.moveBy(target, args)
    assert(not tolua.isnull(target), "UAction.moveBy() - target is not CCNode")
    local x = args.x or 0
    local y = args.y or 0
    local action = CCMoveBy:create(args.time, CCPoint(x, y))
    return UAction.execute(target, action, args)
end

--[[--

精灵的渐变显示。透明度取值范围[0， 255]。 其“反义”动作是UAction.fadeOut()。

### Example:
    -- [调用示例]
    -- 1.0秒渐变显示
    UAction.fadeIn(sprite, {time = 1.0})

### Parameters:
-   CCNode **target**
-   table **args**

]]
function M.fadeIn(target, args)
    assert(not tolua.isnull(target), "UAction.fadeIn() - target is not CCNode")
    local action = CCFadeIn:create(args.time)
    return M.execute(target, action, args)
end

--[[--

精灵的渐变隐藏。透明度取值范围[0， 255]。 其“反义”动作是UAction.fadeIn()。

### Parameters:
-   CCNode **target**
-   table **args**

]]
function M.fadeOut(target, args)
    assert(not tolua.isnull(target), "UAction.fadeOut() - target is not CCNode")
    local action = CCFadeOut:create(args.time)
    return M.execute(target, action, args)
end

--[[--

淡入淡出精灵。修改不透明度使当前对象渐变显示到指定的透明度。

### Example:

    -- [调用示例]
    -- 2.0秒渐变切换到透明度opacity
    UAction.fadeTo(sprite, {time = 2.0, opacity = 200})

### Parameters:
-   CCNode **target**
-   table **args**

]]
function M.fadeTo(target, args)
    assert(not tolua.isnull(target), "UAction.fadeTo() - target is not CCNode")
    local opacity = toint(args.opacity)
    if opacity < 0 then
        opacity = 0
    elseif opacity > 255 then
        opacity = 255
    end
    local action = CCFadeTo:create(args.time, opacity)
    return M.execute(target, action, args)
end

--[[--

指定缩放因子缩放精灵，通过修改它的scale属性。

### Example:

    -- [调用示例]
    UAction.scaleTo(sprite1, {time = 2.0, scale = 2.0})      -- 放大精灵
    UAction.scaleTo(sprite2, {time = 2.0, scaleX = 2.0})     -- 放大精灵[水平]
    UAction.scaleTo(sprite3, {time = 2.0, scaleY = 2.0})     -- 放大精灵[垂直]

### Parameters:
-   CCNode **target**
-   table **args**

]]
function M.scaleTo(target, args)
    assert(not tolua.isnull(target), "UAction.scaleTo() - target is not CCNode")
    local action
    if args.scale then
        action = CCScaleTo:create(tonum(args.time), tonum(args.scale))
    elseif args.scaleX or args.scaleY then
        local scaleX, scaleY
        if args.scaleX then
            scaleX = tonum(args.scaleX)
        else
            scaleX = target:getScaleX()
        end
        if args.scaleY then
            scaleY = tonum(args.scaleY)
        else
            scaleY = target:getScaleY()
        end
        action = CCScaleTo:create(tonum(args.time), scaleX, scaleY)
    end
    return M.execute(target, action, args)
end








----------------------
-- 动画
----------------------
-- [Animate & Animation]
-- [Animate & Animation][Animation]
--[[--

使用图片文件方式(png*N)生成一个动画(CCAnimation)对象

### Useage:
    local animation = UAction.animationWithFile({ prefix = 动画文件前缀名称, num = 动画帧数[, interval = 动画帧间隔, extension = 动画图片文件后缀名] })

### Notice:
使用animationWithFile这个方法需要满足两个前提: 
    1. 动画图片文件的名字带有从1开始计数的连续数字。 
    2. 无。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node      = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.animationWithFile({ prefix = "file/anim_", num = 3, interval = 1.0 / 12 })
    local animate   = CCAnimate:create(animation)
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.animationWithFile(params)
    -- [参数赋值]
    local prefix            = params.prefix                             -- 文件前缀
    local num               = params.num                                -- 动画帧数
    local interval          = params.interval     or 1.0 / frameCount   -- 帧间隔
    local extension         = params.extension    or "png"              -- 图片文件后缀名
    local scene             = D.getRunningScene()                       -- 当前场景


    -- [构建帧集合]
    -- 把动画帧作为贴图进行加载,然后生成精灵动画帧
    local frames = {}
    for i = 1, num do
        -- 1.获得图片文件名
        local fileName = string.format("%s%d.%s", prefix, i, extension)
        -- 2.生成图片Texture2D对象
        local texture = R.loadTexture(fileName)
        -- 3.获得图片Texture2D对象的rect
        local texSize = texture:getContentSize()
        local texRect = CCRect(0, 0, texSize.width, texSize.height)
        -- 4.生成CCSpriteFrame
        local frame = cc.SpriteFrame:createWithTexture(texture, texRect)
        table.insert(frames, frame)
        -- 5.放入自动释放队列中
        if true then 
            if F.fnIn("isAutoCleanupImages", scene) then 
                if scene:isAutoCleanupImages() then 
                    scene:markAutoCleanupImage(fileName)
                end
            end
        end
    end

    
    -- [生成动画对象]
    -- 使用所有的精灵动画帧,返回一个动画对象
    return cc.Animation:createWithSpriteFrames(frames, interval)
end

--[[--

使用图片帧方式(png+plist)生成一个动画(CCAnimation)对象

### Useage:
    UAction.animationWithFrame({ prefix = 动画帧前缀名称, num = 动画帧数[, interval = 动画帧间隔, extension = 动画图片文件后缀名] })

### Notice:
使用animationWithFrame这个方法需要满足两个前提: 
    1. 动画帧文件的名字带有从1开始计数的连续数字。 
    2. 动画帧文件必须是.png文件。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node      = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.animationWithFrame({ prefix = "anim_", num = 3, interval = 1.0 / 12 })
    local animate   = CCAnimate:create(animation)
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.animationWithFrame(params)
    -- [参数赋值]
    local prefix            = params.prefix                             -- 帧前缀
    local num               = params.num                                -- 动画帧数
    local interval          = params.interval     or 1.0 / frameCount   -- 帧间隔
    local extension         = params.extension    or "png"              -- 图片文件后缀名


    -- [构建帧集合]
    -- 把动画帧作为贴图进行加载,然后生成精灵动画帧
    local frames = {}
    for i = 1, num do
        -- 1.获得图片文件名
        local frameName = string.format("%s%d.%s", prefix, i, extension)
        -- 2.生成CCSpriteFrame
        local frame     = display.newSpriteFrame(frameName)
        table.insert(frames, frame)
    end
    
    
    -- [生成动画对象]
    -- 使用所有的精灵动画帧,返回一个动画对象
    return CCAnimation:createWithSpriteFrames(frames, interval)
end

--[[--

自动检测图片是帧或者是文件，生成一个动画(CCAnimation)对象

### Useage:
    local animation = UAction.animationWithImage({ prefix = 动画文件/帧前缀名称, num = 动画帧数[, interval = 动画帧间隔, extension = 动画图片后缀名] })

### Notice:
使用animationWithImage这个方法需要满足两个前提: 
    1. 动画图片文件的名字带有从1开始计数的连续数字。 
    2. 无。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node      = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.animationWithImage({ prefix = "file/anim_", num = 3, interval = 1.0 / 12 })
    local animate   = CCAnimate:create(animation)
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件/帧前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.animationWithImage(params)
    -- [参数赋值]
    local prefix            = params.prefix                             -- 文件前缀

    -- [针对前缀采用不同的策略播放动画]
    if string.byte(prefix) == 35 then -- first char is #
        params.prefix = string.sub(prefix, 2)
        return M.animationWithFrame(params)
    else
        return M.animationWithFile(params)
    end
end

--[[--

自动检测图片是帧或者是文件，根据图像区间生成一个动画(CCAnimation)对象

### Useage:
    local animation = UAction.animationWithImageRange({ prefix = 动画文件/帧前缀名称, start = 起始动画文件索引, length = 截止长度[, interval = 动画帧间隔, extension = 动画图片后缀名] })

### Notice:
使用animationWithImageRange这个方法需要满足两个前提: 
    1. 动画图片文件的名字带有从1开始计数的连续数字。 
    2. 无。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node      = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.animationWithImageRange({ prefix = "file/anim_", start = 2, length = 3, interval = 1.0 / 12 })
    local animate   = CCAnimate:create(animation)
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件/帧前缀名称
-   number **start**        起始动画文件索引
-   number **length**       截止长度
-   number **interval**     动画帧间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.animationWithImageRange(params)
    -- [参数赋值]
    local prefix            = params.prefix                             -- 帧前缀
    local start             = params.start                              -- 起始动画文件索引
    local length            = params.length                             -- 截止长度
    local interval          = params.interval     or 1.0 / frameCount   -- 帧间隔
    local extension         = params.extension    or "png"              -- 图片文件后缀名


    -- [构建帧集合]
    -- 把动画帧作为贴图进行加载,然后生成精灵动画帧
    local frames = {}

    -- [针对前缀采用不同的策略播放动画]
    if string.byte(prefix) == 35 then -- first char is #
        prefix = string.sub(prefix, 2)
        for i = start, start + length - 1 do
            -- 1.获得图片文件名
            local frameName = string.format("%s%d.%s", prefix, i, extension)
            -- 2.生成CCSpriteFrame
            local frame     = display.newSpriteFrame(frameName)
            table.insert(frames, frame)
        end
    else
        for i = start, start + length - 1 do
            -- 1.获得图片文件名
            local fileName = string.format("%s%d.%s", prefix, i, extension)
            -- 2.生成图片Texture2D对象
            local texture = R.loadTexture(fileName)
            -- 3.获得图片Texture2D对象的rect
            local texSize = texture:getContentSize()
            local texRect = CCRect(0, 0, texSize.width, texSize.height)
            -- 4.生成CCSpriteFrame
            local frame = CCSpriteFrame:createWithTexture(texture, texRect)
            table.insert(frames, frame)
        end
    end
    
    
    -- [生成动画对象]
    -- 使用所有的精灵动画帧,返回一个动画对象
    return CCAnimation:createWithSpriteFrames(frames, interval)
end

--[[--

使用图片帧名称集合(file*N)生成一个动画(CCAnimation)对象

### Useage:
    UAction.animationWithFileNames({ names = 动画名称集合[, interval = 动画帧间隔] })

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node      = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.animationWithFileNames({ names = { "file/anim_1.png", "file/anim_2.png", "file/anim_3.png", }, interval = 1.0 / 12 })
    local animate   = CCAnimate:create(animation)
    node:runAction(animate)

### Parameters:
-   table **names**         动画名称集合
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.animationWithFileNames(params)
    -- [参数赋值]
    local names             = params.names                              -- 文件名称集
    local interval          = params.interval                           -- 帧间隔
    local scene             = D.getRunningScene()                       -- 当前场景


    -- [构建帧集合]
    -- 把动画帧作为贴图进行加载,然后生成精灵动画帧
    local frames = {}
    local num    = #names
    for i = 1, num do
        -- 1.获得图片文件名
        local fileName = names[i]
        -- 2.生成图片Texture2D对象
        local texture = R.loadTexture(fileName)
        -- 3.获得图片Texture2D对象的rect
        local texSize = texture:getContentSize()
        local texRect = CCRect(0, 0, texSize.width, texSize.height)
        -- 4.生成CCSpriteFrame
        local frame = CCSpriteFrame:createWithTexture(texture, texRect)
        table.insert(frames, frame)
        -- 5.放入自动释放队列中
        if true then 
            if F.fnIn("isAutoCleanupImages", scene) then 
                if scene:isAutoCleanupImages() then 
                    scene:markAutoCleanupImage(fileName)
                end
            end
        end
    end
    
    
    -- [生成动画对象]
    -- 使用所有的精灵动画帧,返回一个动画对象
    return CCAnimation:createWithSpriteFrames(frames, interval)
end

--[[--

使用图片帧名称集合(frame*N)生成一个动画(CCAnimation)对象

### Useage:
    UAction.animationWithFrameNames({ names = 动画帧名称集合[, interval = 动画帧间隔] })

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node      = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.animationWithFrameNames({ names = { "anim_1.png", "anim_2.png", "anim_3.png", }, interval = 1.0 / 12 })
    local animate   = CCAnimate:create(animation)
    node:runAction(animate)

### Parameters:
-   table **names**         动画帧名称集合
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.animationWithFrameNames(params)
    -- [参数赋值]
    local names             = params.names                              -- 帧名称集
    local interval          = params.interval                           -- 帧间隔


    -- [构建帧集合]
    -- 把动画帧作为贴图进行加载,然后生成精灵动画帧
    local frames = {}
    local num    = #names
    for i = 1, num do
        -- 1.获得图片文件名
        local frameName = names[i]
        local frame     = display.newSpriteFrame(frameName)
        table.insert(frames, frame)
    end
    
    
    -- [生成动画对象]
    -- 使用所有的精灵动画帧,返回一个动画对象
    return CCAnimation:createWithSpriteFrames(frames, interval)
end

--[[--

自动检测图片是帧或者是文件，使用图片名称集合，生成一个动画(CCAnimation)对象

### Useage:
    UAction.animationWithImageNames({ names = 动画名称集合[, interval = 动画间隔] })

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node      = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.animationWithImageNames({ names = { "anim_1.png", "anim_2.png", "anim_3.png", }, interval = 1.0 / 12 })
    local animate   = CCAnimate:create(animation)
    node:runAction(animate)

### Parameters:
-   table **names**         动画名称集合
-   number **interval**     动画间隔

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.animationWithImageNames(params)
    -- [参数赋值]
    local names             = params.names                              -- 帧名称集

    
    -- [验证]
    J.typeTable(M.TAG, names)
J.numberOver0(M.TAG, #names)

    -- [针对前缀采用不同的策略播放动画]
    if string.byte(names[1]) == 35 then -- first char is #
        for i = 1, #names do
            J.assert(M.TAG, string.byte(names[i]) == 35, "all names must be start with '#'!")
            names[i] = string.sub(names[i], 2)
            for n = 1, 100 do
                fukserfsd
            end
        end
        return M.animationWithFrameNames(params)
    else
        return M.animationWithFileNames(params)
    end
end

-- [Animate & Animation][Animate]
--[[--

使用图片文件方式(png*N)生成一个动画(Animate)对象

### Useage:
    UAction.animateWithFile({ prefix = 动画文件前缀名称, num = 动画帧数[, interval = 动画帧间隔, extension = 动画图片文件后缀名] })

### Aliases:
    UAction.animateWithFile

### Notice:
使用animationWithFile这个方法需要满足两个前提: 
    1. 动画图片文件的名字带有从1开始计数的连续数字。 
    2. 无。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node    = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithFile({ prefix = "file/anim_", num = 3, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithFile(params)
    local animation = M.animationWithFile(params)
    return CCAnimate:create(animation)
end
M.actionFile = M.animateWithFile

--[[--

使用图片帧方式(png+plist)生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithFrame({ prefix = 动画帧前缀名称, num = 动画帧数[, interval = 动画帧间隔, extension = 动画图片文件后缀名] })

### Aliases:
    UAction.actionFrame

### Notice:
使用animationWithFrame这个方法需要满足两个前提: 
    1. 动画帧文件的名字带有从1开始计数的连续数字。 
    2. 动画帧文件必须是.png文件。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithFrame({ prefix = "anim_", num = 3, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithFrame(params)
    local animation = M.animationWithFrame(params)
    return CCAnimate:create(animation)
end
M.actionFrame = M.animateWithFrame

--[[--

自动检测图片是帧或者是文件，生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithImage({ prefix = 动画前缀名称, num = 动画文件数量[, interval = 动画间隔, extension = 动画图片文件后缀名] })

### Aliases:
    UAction.actionImage

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithImage({ prefix = "#anim_", num = 3, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **num**          动画文件数量
-   number **interval**     动画间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithImage(params)
    local animation = M.animationWithImage(params)
    return CCAnimate:create(animation)
end
M.actionImage = M.animateWithImage

--[[--

自动检测图片是帧或者是文件，根据图像区间生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithImageRange({ prefix = 动画前缀名称, start = 起始动画文件索引, length = 截止长度[, interval = 动画间隔, extension = 动画图片文件后缀名] })

### Aliases:
    UAction.actionImageRange

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithImage({ prefix = "#anim_", start = 2, legnth = 3, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **start**        起始动画文件索引
-   number **length**       截止长度
-   number **interval**     动画间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithImageRange(params)
    local animation = M.animationWithImageRange(params)
    return CCAnimate:create(animation)
end
M.actionImageRange = M.animateWithImageRange

--[[--

使用图片帧名称集合(file*N)生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithFileNames({ names = 动画文件名称集合[, interval = 动画帧间隔] })

### Aliases:
    UAction.actionFileNames

### Notice:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node    = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithFileNames({ names = { "file/anim_1.png", "file/anim_2.png", "file/anim_3.png", }, interval = 1.0 / 12 })
    node:runAction(animate)

### Example:

### Parameters:
-   table **names**         动画文件名称集合
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithFileNames(params)
    local animation = M.animationWithFileNames(params)
    return CCAnimate:create(animation)
end
M.actionFileNames = M.animateWithFileNames

--[[--

使用图片帧名称集合(frame*N)生成一个动画(CCAnimate)对象

### Useage:
    UAction.animationWithFrameNames({ names = 动画帧名称集合[, interval = 动画帧间隔] })

### Aliases:
    UAction.actionFrameNames

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithFrameNames({ names = { "anim_1.png", "anim_2.png", "anim_3.png", }, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   table **names**         动画帧名称集合
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithFrameNames(params)
    local animation = M.animationWithFrameNames(params)
    return CCAnimate:create(animation)
end
M.actionFrameNames = M.animateWithFrameNames

--[[--

自动检测图片是帧或者是文件，生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithImageNames({ names = 动画名称集合[, interval = 动画间隔] })

### Aliases:
    UAction.actionImageNames

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithImageNames({ names = { "#anim_1.png", "#anim_2.png", "#anim_3.png", }, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   table **names**         动画名称集合
-   number **interval**     动画间隔

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithImageNames(params)
    local animation = M.animationWithImageNames(params)
    return CCAnimate:create(animation)
end
M.actionImageNames = M.animateWithImageNames

--[[--

根据SWF文件，生成一个动画(CCAnimate)对象

### Useage:
    local animate = UAction.animateWithSWF({ prefix = 动画文件/帧前缀名称, num = 动画帧数[, interval = 动画帧间隔, extension = 动画图片后缀名] })

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node      = D.img("node.png"):pc():to(layer)

    -- 播放动画
    local animate   = A.animateWithSWF({ prefix = "samples/swf/Untitled", interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件/帧前缀名称
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithSWF(params)
    -- [参数赋值]
    local prefix            = params.prefix                             -- 文件前缀
    local interval          = params.interval                             -- 文件前缀

    -- [针对前缀采用不同的策略播放动画]
    return AnimateUtils:createAnimFormSwf(prefix, interval)
end

--[[--

[重复]使用图片文件方式(png*N)生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithFileRepeat({ prefix = 动画文件前缀名称, num = 动画帧数[, interval = 动画帧间隔, extension = 动画图片文件后缀名] })

### Aliases:
    UAction.actionFileRepeat

### Notice:
使用animationWithFile这个方法需要满足两个前提: 
    1. 动画图片文件的名字带有从1开始计数的连续数字。 
    2. 无。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node    = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithFileRepeat({ prefix = "file/anim_", num = 3, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithFileRepeat(params)
    local animate = M.animateWithFile(params)
    return CCRepeatForever:create(animate)
end
M.actionFileRepeat = M.animateWithFileRepeat

--[[--

[重复]使用图片帧方式(png+plist)生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithFrameRepeat({ prefix = 动画帧前缀名称, num = 动画帧数[, interval = 动画帧间隔, extension = 动画图片文件后缀名] })

### Aliases:
    UAction.actionFrameRepeat

### Notice:
使用animationWithFrame这个方法需要满足两个前提: 
    1. 动画帧文件的名字带有从1开始计数的连续数字。 
    2. 动画帧文件必须是.png文件。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.actionFrameRepeat({ prefix = "anim_", num = 3, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithFrameRepeat(params)
    local animate = M.animateWithFrame(params)
    return CCRepeatForever:create(animate)
end
M.actionFrameRepeat = M.animateWithFrameRepeat

--[[--

[重复]自动检测图片是帧或者是文件，生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithImageRepeat({ prefix = 动画前缀名称, num = 动画文件数量[, interval = 动画间隔, extension = 动画图片文件后缀名] })

### Aliases:
    UAction.actionImageRepeat

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithImageRepeat({ prefix = "#anim_", num = 3, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **num**          动画文件数量
-   number **interval**     动画间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithImageRepeat(params)
    local animate = M.animateWithImage(params)
    return CCRepeatForever:create(animate)
end
M.actionImageRepeat = M.animateWithImageRepeat

--[[--

[重复]自动检测图片是帧或者是文件，根据图像区间生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithImageRangeRepeat({ prefix = 动画前缀名称, start = 起始动画文件索引, length = 截止长度[, interval = 动画间隔, extension = 动画图片文件后缀名] })

### Aliases:
    UAction.actionImageRangeRepeat

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithImageRepeat({ prefix = "#anim_", start = 2, length = 3, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   string **prefix**       动画文件前缀名称
-   number **start**        起始动画文件索引
-   number **length**       截止长度
-   number **interval**     动画间隔
-   string **extension**    动画图片文件后缀名

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithImageRangeRepeat(params)
    local animate = M.animateWithImageRange(params)
    return CCRepeatForever:create(animate)
end
M.actionImageRangeRepeat = M.animateWithImageRangeRepeat

--[[--

[重复]使用图片帧名称集合(file*N)生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithFileNamesRepeat({ names = 动画文件名称集合[, interval = 动画帧间隔] })

### Aliases:
    UAction.actionFileNamesRepeat

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 创建结点
    local node    = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithFileNamesRepeat({ names = { "file/anim_1.png", "file/anim_2.png", "file/anim_3.png", }, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   table **names**         动画文件名称集合
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithFileNamesRepeat(params)
    local animate = M.animateWithFileNames(params)
    return CCRepeatForever:create(animate)
end
M.actionFileNamesRepeat = M.animateWithFileNamesRepeat

--[[--

[重复]使用图片帧名称集合(frame*N)生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithFrameNamesRepeat({ names = 动画帧名称集合[, interval = 动画帧间隔] })

### Aliases:
    UAction.actionFrameNamesRepeat

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithFrameNamesRepeat({ names = { "anim_1.png", "anim_2.png", "anim_3.png", }, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   table **names**         动画帧名称集合
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithFrameNamesRepeat(params)
    local animate = M.animateWithFrameNames(params)
    return CCRepeatForever:create(animate)
end
M.actionFrameNamesRepeat = M.animateWithFrameNamesRepeat

--[[--

[重复]自动检测图片是帧或者是文件，生成一个动画(CCAnimate)对象

### Useage:
    UAction.animateWithImageNamesRepeat({ names = 动画名称集合[, interval = 动画间隔] })

### Aliases:
    UAction.actionImageNamesRepeat

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node    = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animate = UAction.animateWithImageNamesRepeat({ names = { "#anim_1.png", "#anim_2.png", "#anim_3.png", }, interval = 1.0 / 12 })
    node:runAction(animate)

### Parameters:
-   table **names**         动画名称集合
-   number **interval**     动画间隔

### Returns: 
-   CCAnimate               动画对象

--]]--
function M.animateWithImageNamesRepeat(params)
    local animate = M.animateWithImageNames(params)
    return CCRepeatForever:create(animate)
end
M.actionImageNamesRepeat = M.animateWithImageNamesRepeat








----------------------
-- 名称
----------------------
--[[--

[废弃]根据帧前缀及指定索引获得帧名称

### Useage:
    UAction.frameNameAtIndex(索引, 帧前缀)

### Notice:

### Example:

### Link:
    UAction.nameAtIndex(index, prefix)

### Parameters:
-   number **index**        索引
-   string **prefix**       帧前缀

### Returns: 
-   string                  动画帧名称

--]]--
function M.frameNameAtIndex(index, prefix)
    return string.format("#%s%d.png", prefix, index)
end

--[[--

[废弃]根据帧前缀获得第一个动画帧名称

### Useage:
    UAction.frameNameAtFirst(帧前缀)

### Notice:

### Example:

### Link:
    UAction.nameAtFirst(prefix)

### Parameters:
-   string **prefix**       帧前缀

### Returns: 
-   string                  动画帧名称

--]]--
function M.frameNameAtFirst(prefix)
    return M.frameNameAtIndex(1, prefix)
end

--[[--

根据名称前缀及指定索引获得动画名称

### Useage:
    UAction.nameAtIndex(索引, 帧前缀)

### Aliases:
    UAction.nameAt

### Notice:

### Example:

### Parameters:
-   number **index**        索引
-   string **prefix**       名称前缀

### Returns: 
-   string                  动画名称

--]]--
function M.nameAtIndex(index, prefix)
    return string.format("%s%d.png", prefix, index)
end
M.nameAt = M.nameAtIndex

--[[--

根据名称前缀引获得第一个动画名称

### Useage:
    UAction.nameAtFirst(帧前缀)

### Aliases:
    UAction.nameFirst

### Notice:

### Example:

### Parameters:
-   string **prefix**       名称前缀

### Returns: 
-   string                  动画名称

--]]--
function M.nameAtFirst(prefix)
    return M.nameAtIndex(1, prefix)
end
M.nameFirst = M.nameAtFirst

--[[--

获得当前图像显示的文件索引

### Useage:
    UAction.indexAtFiles(结点, 文件集合)

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------

### Parameters:
-   CCNode **node**         结点
-   table **imgNames**      文件集合

### Returns: 
-   number                  图像显示的文件索引

--]]--
function M.indexAtFiles(node, imgNames)
    -- 精灵当前播放的是第几帧
    local index = 0
    for i = 1, #imgNames do
        local id    = node:getTexture():getName()
        if id == imgNames[i] then 
            index = i
            break
        end
    end

    -- 下标索引从1开始 
    return index
end

--[[--

获得当前图像显示的文件索引

### Useage:
    UAction.indexAtFiles(结点, 文件集合)

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------

### Parameters:
-   CCNode **node**         结点
-   CCAnimate **animate**   动作对象
-   number **num**          动作帧数量 

### Returns: 
-   number                  图像显示的文件索引

--]]--
function M.indexAtAnimate(node, animate, num)
    -- 精灵当前播放的是第几帧
    local index = 0
    for i = 1, num do
        local id    = node:getTexture():getName()
        local frame = tolua.cast(animate:getAnimation():getFrames():objectAtIndex(i - 1), "CCSpriteFrame")
        if id == frame:getTexture():getName() then 
            index = i
            break
        end
    end

    -- 下标索引从1开始 
    return index
end








----------------------
-- 调用控制
----------------------
--[[--

暂停场景调度

### Useage:
    UAction.pause()

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    UAction.pause()

--]]--
function M.pause()
    if not CCDirector:getInstance():isPaused() then 
        CCDirector:getInstance():pause()
    end
end

--[[--

恢复场景调度

### Useage:
    UAction.resume()

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    UAction.resume()

--]]--
function M.resume()
    if CCDirector:getInstance():isPaused() then 
        CCDirector:getInstance():resume()
    end
end

--[[--

切换场景调度

### Useage:
    UAction.toggleDirectorStatus()

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    UAction.toggleDirectorStatus()

--]]--
function M.toggleDirectorStatus()
    local director = CCDirector:getInstance()
    if director:isPaused() then
        director:resume()
    else
        director:pause()
    end
end

--[[--

暂停所有动作

### Useage:
    UAction.pauseAll()

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    UAction.pauseAll()

--]]--
function M.pauseAll()
    _idPause = actionManager:pauseAllRunningActions()
end

--[[--

暂停指定对象的所有动作

### Useage:
    UAction.pauseTarget(对象)

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    UAction.pauseTarget(node)

### Parameters:
-   CCNode **target**       对象
-   bool **isCascade**      是否级联子结点进行操作

--]]--
function M.pauseTarget(target)
    if not tolua.isnull(target) then
        actionManager:pauseTarget(target)
    end
end

--[[--

暂停指定对象集的所有动作
遍历所有指定的对象, 将它们的动作停止

### Useage:
    UAction.pauseTargets(对象集)

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    UAction.pauseTargets({ node1, node2, })

### Parameters:
-   table **targets**       对象集
-   bool **isCascade**      是否级联子结点进行操作

--]]--
function M.pauseTargets(targets)
    if istable(targets) then 
        for i = 1, #targets do
            M.pauseTarget(targets[i])
        end
    end
end

--[[--

恢复所有动作

### Useage:
    UAction.resumeAll()

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    UAction.resumeAll()

--]]--
function M.resumeAll()
    actionManager:resumeTargets(_idPause)
end

--[[--

恢复指定对象的所有动作

### Useage:
    UAction.resumeTarget(对象)

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：恢复结点的所有动作>>
    UAction.resumeTarget(node)

### Parameters:
-   CCNode **target**       对象
-   bool **isCascade**      是否级联子结点进行操作

### Returns: 

--]]--
function M.resumeTarget(target)
    if not tolua.isnull(target) then
        actionManager:resumeTarget(target)
    end
end

--[[--

恢复指定对象集的所有动作
遍历所有指定的对象, 将它们的动作恢复

### Useage:
    UAction.resumeTargets(对象集)

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    UAction.resumeTargets({ node1, node2, })

### Parameters:
-   table **targets**       对象集
-   bool **isCascade**      是否级联子结点进行操作

### Returns: 

--]]--
function M.resumeTargets(targets)
    if istable(targets) then 
        for i = 1, #targets do
            M.resumeTarget(targets[i])
        end
    end
end

--[[--

停止动作。

### Useage:
    UAction.removeAction(动作)

### Notice:

### Example:
    -- [调用示例]
    local action = UAction.moveTo(sprite, {time = 2.0, x = 100, y = 100})
    ....
    UAction.removeAction(action)             -- 停止移动

### Parameters:
-   CCAction **action**     动作对象

### Returns: 

--]]--
function M.removeAction(action)
    if not tolua.isnull(action) then
        actionManager:removeAction(action)
    end
end

--[[--

停止目标的所有动作.

### Useage:
    UAction.stopTarget(对象集)

### Notice:

### Example:
    -- [调用示例]
    transition.moveTo(sprite, {time = 2.0, x = 100, y = 100})
    transition.fadeOut(sprite, {time = 2.0})
    ....
    UAction.stopTarget(sprite)               -- 停止sprite的所有动作

### Parameters:
-   CCNode **target**       目标对象

### Returns: 

--]]--
function M.stopTarget(target)
    if not tolua.isnull(target) then
        actionManager:removeAllActionsFromTarget(target)
    end
end








----------------------
-- 动画整合
----------------------
--[[--

快捷播放动画

### Useage:
    UAction.playAnimation({
        target              = 动画结点,
        resource            = 资源名称(会首先addSpriteFramesWithFile),
        pattern             = 资源格式化字符串,
        num                 = 帧数量,
        playTime            = 播放时长,
        defaultDisplayIndex = 默认帧索引,
        forever             = 是否无限循环动画,
        removeWhenFinished  = 是否在动画结束后删除结点,
        onComplete          = 结果回调,
        delay               = 延迟时间,
    })

### Aliases:
    UAction.play

### Notice:

### Example:

### Parameters:
-   CCNode      **target**              动画结点
-   string      **resource**            资源名称(会首先addSpriteFramesWithFile)
-   string      **pattern**             资源格式化字符串
-   number      **num**                 帧数量
-   number      **playTime**            播放时长
-   number      **defaultDisplayIndex** 默认帧索引
-   bool        **forever**             是否无限循环动画
-   bool        **removeWhenFinished**  是否在动画结束后删除结点
-   function    **onComplete**          结果回调
-   number      **delay**               延迟时间

### Returns: 
-   CCNode                              动画结点

--]]--
function M.playAnimation(params)
    -- [参数解析]
    local target                = params.target 
    local resource              = params.resource
    local pattern               = params.pattern
    local num                   = params.num
    local playTime              = params.playTime
    local defaultDisplayIndex   = params.defaultDisplayIndex
    local forever               = params.forever
    local removeWhenFinished    = params.removeWhenFinished
    local onComplete            = params.onComplete
    local delay                 = params.delay

    -- 处理资源
    if resource then 
        display.addSpriteFramesWithFile(resource .. ".plist", resource .. ".png")
    end
    -- 处理目标对象(不存在，则创建)
    if not target then
        target = display.newSprite("#" .. string.format(pattern, defaultDisplayIndex or 1))
    end
    local frames = display.newFrames(pattern, 1, num)
    local animation = display.newAnimation(frames, playTime / num)
    if forever then
        transition.playAnimationForever(target, animation, delay)
    else
        transition.playAnimationOnce(target, animation, removeWhenFinished, onComplete, delay)
    end 
    
    return target
end
M.play = M.playAnimation








----------------------
-- 缓存
----------------------
--[[--

添加动画对象进缓存(文件)

### Useage:
    UAction.setCacheAnimationFile(动画缓存名称, 动画文件前缀名称, 动画帧数[, 动画帧间隔])

### Notice:
使用animationWithFile这个方法需要满足两个前提: 
    1. 动画图片文件的名字带有从1开始计数的连续数字。 
    2. 无。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：构建动画缓存>>
    -- 创建结点
    local node = D.img("file/anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.setCacheAnimationFile("Anim1", "file/anim_", 3, 1.0 / 12)
    node:playAnimationForever(animation)

### Parameters:
-   string **name**         动画缓存名称
-   string **prefix**       动画文件前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.setCacheAnimationFile(name, prefix, num, interval)
    local animation = M.animationWithFile({ prefix = prefix, num = num, interval = interval })
    display.setAnimationCache(name, animation)

    return animation
end

--[[--

添加动画对象进缓存(帧)

### Useage:
    UAction.setCacheAnimationFrame(动画缓存名称, 动画帧前缀名称, 动画帧数[, 动画帧间隔])

### Notice:
使用animationWithFrame这个方法需要满足两个前提: 
    1. 动画帧文件的名字带有从1开始计数的连续数字。 
    2. 动画帧文件必须是.png文件。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：构建动画缓存>>
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node = D.img("#anim_1.png"):pc():to(layer)

    -- 播放动画
    local animation = UAction.setCacheAnimationFrame("Anim1", "anim_", 3, 1.0 / 12)
    node:playAnimationForever(animation)

### Parameters:
-   string **name**         动画缓存名称
-   string **prefix**       动画文件前缀名称
-   number **num**          动画帧数
-   number **interval**     动画帧间隔

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.setCacheAnimationFrame(name, prefix, num, interval)
    local animation = M.animationWithFrame({ prefix = prefix, num = num, interval = interval })
    display.setAnimationCache(name, animation)

    return animation
end

--[[--

获得动画对象缓存

### Useage:
    UAction.getCacheAnimation(动画缓存名称)

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 加载动画资源
    R.loadFrames("frame/anim")

    -- 创建结点
    local node = D.img("#anim_1.png"):pc():to(layer)

    -- 设置动画缓存
    A.setCacheAnimationFrame("Anim1", "anim_", 3, 1.0 / 12)
    
    -- 获得动画缓存并播放动画
    local animation = A.getCacheAnimation("Anim1")
    node:playAnimationForever(animation)

### Parameters:
-   string **name**         动画缓存名称

### Returns: 
-   CCAnimation             动画对象

--]]--
function M.getCacheAnimation(name)
    return D.getAnimationCache(name)
end

--[[--

获得动作缓存中的动作对象 

### Useage:
    local action = UAction.getCacheAction(动作名称)

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 获得动作对象[传统]
    local cache = CCAnimationCache:sharedAnimationCache()
    cache:addAnimationsWithFile("animations/animations-1.plist")
    local animation = cache:animationByName("anim_1")

    -- 获得动作对象[框架]
    local animation = A.getCacheAction("anim_1")

### Parameters:
-   string **name**         动作名称

### Returns: 
-   CCAction                动作对象 

--]]--
function M.getCacheAction(name)
    return CCAnimationCache:sharedAnimationCache():animationByName(name)
end








----------------------
-- 执行动作
----------------------
--[[--

复制动作对象

### Useage:
    local actionCopied = UAction.copy(动作对象)

### Aliases:
    UAction.clone

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：构建动画>>
    -- 创建结点
    local node    = D.imgc("node.png"):to(layer)
    -- 创建动画序列
    local actions = {
        { "moveTo", 1.0, ccp(100, 100) },
        { "echo", "step 2!" },
        { "moveTo", 1.0, ccp(200, 200) },
        { "moveTo", 1.0, ccp(300, 300) },
        { "moveTo", 1.0, ccp(400, 400) },
        { "moveTo", 1.0, ccp(500, 500) },
    }

    -- 创建动作对象
    A.runLine({
        node        = node,
        actions     = actions,
        from        = 2,
        to          = 4,
        callback    = function()
            print("ok!")
        end,
    })

### Parameters:
-   CCAction **action**     动作对象

### Returns: 
-   CCAction                复制的动作对象

--]]--
function M.runLine(params)
    -- [参数赋值]
    local node      = params.node
    local actions   = params.actions 
    local from      = ifnil(params.from, 1) 
    local to        = ifnil(params.to, #actions)
    local callback  = params.callback


    -- [动画]
    local newActions = bb.UTable.subtable(actions, from, to)
    -- 添加回调函数
    if isfunction(callback) then 
        table.insert(newActions, CCCallFunc:create(callback))
    end
    -- 执行动画
    node:runAction(A.line(newActions))
end

--[[--

复制动作对象

### Useage:
    local actionCopied = UAction.copy(动作对象)

### Aliases:
    UAction.clone

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：构建动画>>
    -- 创建结点
    local node    = D.imgc("node.png"):to(layer)
    -- 创建动画序列
    local actions = {
        { "moveTo", 1.0, ccp(100, 100) },
        { "echo", "step 2!" },
        { "moveTo", 1.0, ccp(200, 200) },
        { "echo", "step 4!" },
        { "moveTo", 1.0, ccp(300, 300) },
        { "moveTo", 1.0, ccp(400, 400) },
        { "moveTo", 1.0, ccp(500, 500) },
    }

    -- 创建动作对象
    A.runAssign({
        node        = node,
        actions     = actions,
        indexes     = { 2,3,4 },
        callback    = function()
            print("ok!")
        end,
    })

### Parameters:
-   CCAction **action**     动作对象

### Returns: 
-   CCAction                复制的动作对象

--]]--
function M.runAssign(params)
    -- [参数赋值]
    local node      = params.node
    local actions   = params.actions 
    local indexes   = params.indexes
    local callback  = params.callback


    -- [动画]
    local newActions = T.assign(actions, indexes)
    -- 添加回调函数
    if isfunction(callback) then 
        table.insert(newActions, CCCallFunc:create(callback))
    end
    -- 执行动画
    node:runAction(A.line(newActions))
end








----------------------
-- 复制
----------------------
--[[--

复制动作对象

### Useage:
    local actionCopied = UAction.copy(动作对象)

### Aliases:
    UAction.clone

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：构建动画缓存>>
    -- 创建结点
    local node1 = D.imgc("node.png"):to(layer)
    local node2 = D.imgc("node.png"):to(layer)

    -- 创建动作对象
    local action = CCMoveTo:create(1.0, ccp(100, 100))
    local actionCopied = UAction.copy(action)

    -- 播放动作
    node1:runAction(action)
    node2:runAction(actionCopied)

### Parameters:
-   CCAction **action**     动作对象

### Returns: 
-   CCAction                复制的动作对象

--]]--
function M.copy(action)
    return action:clone()
end
M.clone = M.copy








----------------------
-- 速度
----------------------
--[[--

实现动作加速

### Useage:
    UAction.speedUp(动画名称, 加速倍数)

### Aliases:
    
### Notice:
    这个方法有一个缺点：改变了CCAnimationCache中这个animation的delay unit。也就是说以后即使再从CCAnimationCache中获取这个animation，其delay unit已经是原来的0.2倍了。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：改变动作速度>>
    -- 实现加速效果(改变原速度的2倍)
    UAction.speedUp(2)

### Parameters:
-   string **animationName**    动画名称
-   number **multiple**         加速倍数

### Returns: 

--]]--
function M.speedUp(animationName, multiple)
    -- [验证]
    J.typeNumber(M.TAG, multiple)

    -- 实现加速效果
    local action = M.getCacheAnimation(animationName)
    action:setDelayUnit(action:getDelayUnit() * multiple) 
end

--[[--

实现动作减速

### Useage:
    UAction.speedDown(动画名称, 加速倍数)

### Aliases:
    
### Notice:
    这个方法有一个缺点：改变了CCAnimationCache中这个animation的delay unit。也就是说以后即使再从CCAnimationCache中获取这个animation，其delay unit已经是原来的0.2倍了。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：改变动作速度>>
    -- 实现减速效果(改变原速度的1/2倍)
    UAction.speedDown(2)

### Parameters:
-   string **animationName**    动画名称
-   number **multiple**         减速倍数

### Returns: 

--]]--
function M.speedDown(animationName, multiple)
    -- [验证]
    J.typeNumber(M.TAG, multiple)

    -- 实现减速效果
    local action = M.getCacheAnimation(animationName)
    action:setDelayUnit(action:getDelayUnit() * (1 / multiple))
end

--[[--

改变动作播放速度

### Useage:
    UAction.speedValue(动画名称, 加速倍数)

### Aliases:
    
### Notice:
    这个方法有一个缺点：改变了CCAnimationCache中这个animation的delay unit。也就是说以后即使再从CCAnimationCache中获取这个animation，其delay unit已经是原来的0.2倍了。

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：改变动作速度>>
    -- 实现速度改变效果
    UAction.speedValue(.5)

### Parameters:
-   string **animationName**    动画名称
-   number **value**            速度改变值

### Returns: 

--]]--
function M.speedValue(animationName, value)
    -- [验证]
    J.typeNumber(M.TAG, value)

    -- 实现减速效果
    local action = M.getCacheAnimation(animationName)
    action:setDelayUnit(action:getDelayUnit() * value)
end

--[[--

还原调度器播放速度

### Useage:
    UAction.speedRestore(动画名称)

### Aliases:
    
### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- <<说明：改变游戏速度>>
    -- 实现减速效果(改变原速度的1/2倍)
    UAction.speedValue(.5)

    -- 实现速度还原
    UAction.speedRestore()

### Parameters:
-   string **animationName**    动画名称

### Returns: 

--]]--
function M.speedRestore(animationName)
    -- 实现减速效果
    local action = M.getCacheAnimation(animationName)
    
    -- 暂未能实现此功能，以后可能提供 
    E.raiseUnsupportedOperationException("UAction.speedRestore(animationName)")
end








----------------------
-- 复合动作
----------------------
--[[--

运行动作[开始]

### Useage:
    runActionBegan_(方法名称, 参数集合)

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 执行模板[开始]
    runActionBegan_("SomeActionMethod", params)

### Parameters:
-   string **method**       方法名称
-   table **params**        参数集合

### Returns: 

--]]--
local function runActionBegan_(method, params)
    -- [参数验证]
    J.typeTable(M.TAG, params)

    -- [参数解析]
    local node              = params.node

    -- [验证]
    J.notNil(M.TAG, node, tostring(method) .. "() invalid params.node!")
end

--[[--

运行动作[结束](执行或返回动作对象)

### Useage:
    local action = UAction.runActionEnded_(动作对象, 参数集合)

### Aliases:

### Notice:

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 执行动作
    runActionEnded_(action, { node = node, })
    -- 返回动作
    local action = runActionEnded_(action, { node = node, isReturnAction = true, })

### Parameters:
-   CCAction **action**     动作对象
-   table **params**        参数集合

### Returns: 
-   CCAction                动作对象

--]]--
local function runActionEnded_(action, params)
    if tobool(params.isReturnAction) then
        return action
    else
        params.node:one(action)
        return params.node
    end
end

--[[--

获得动作[来回移动]

### Useage:
    local action = UAction.actionMoveAround(参数集合)

### Aliases:

### Notice:
    [必填项]
        number      **times**           移动次数
        number      **center**          位置中心处
        number      **delta**           位置偏移量
        number      **deltaTime**       位置偏移时间
        enum        **startDirection**  位置起始移动方向
    [关键项] 
        enum        **directionMode**   方向模式
        number      **increase**        位置增加值
        enum        **increaseMode**    位置增加模式
    [选填项]
        无
    [其他项]
        directionMode 参数可用的值：
            DIRECTION_MODE_LR           = 1
            DIRECTION_MODE_TB           = 2
            DIRECTION_MODE_D4           = 3
            DIRECTION_MODE_D5           = 4
            DIRECTION_MODE_D8           = 5
            DIRECTION_MODE_D9           = 6
        startDirection 参数可用的值：
            DIRECTION_LEFT              = 1
            DIRECTION_RIGHT             = 2
            DIRECTION_TOP               = 3
            DIRECTION_BOTTOM            = 4
        increaseMode 参数可用的值：
            CHANGEMODE_FIX_VALUE        = 1
            CHANGEMODE_PERCENTAGE       = 2

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionMoveAround({
        center      = node:point(),
        delta       = ccp(50, 0),
        deltaTime   = .3,
        times       = 3,
        startDirection = DIRECTION_RIGHT,
        increase    = ccp(50, 0)
    })
    node:one(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[来回移动]

--]]--
function M.actionMoveAround(params)
    -- [参数解析]
    params = totable(params)
    local times             = ifnil(params.times, UNLIMITED)        -- 移动次数
    local center            = params.center                         -- 位置中心处
    local delta             = params.delta                          -- 位置偏移量
    local deltaTime         = params.deltaTime                      -- 位置偏移时间
    local directionMode     = ifnil(params.directionMode, DIRECTION_MODE_LR)    -- 方向模式
    local increase          = ifnil(params.increase, 0)             -- 位置增加值
    local increaseMode      = ifnil(params.increaseMode, CHANGEMODE_FIX_VALUE)  -- 位置增加模式
    local startDirection    = params.startDirection                 -- 位置起始移动方向


    -- [验证]
    if startDirection then 
        if directionMode == DIRECTION_MODE_LR then 
            J.assert(M.TAG, (startDirection == DIRECTION_LEFT or startDirection == DIRECTION_RIGHT))
        elseif directionMode == DIRECTION_MODE_TB then 
            J.assert(M.TAG, (startDirection == DIRECTION_TOP or startDirection == DIRECTION_BOTTOM))
        end
    end


    -- [内部函数]
    -- 获得进行来回移动的坐标点集
    local function getPositions(directionMode, startDirection, center, delta, increaseMode, increase, timesIndex)
        local p1, p2, p3, p4

        if increase ~= 0 then 
            if isnumber(increase) then 
                if increaseMode == CHANGEMODE_FIX_VALUE then 
                    delta = ccp(delta.x + timesIndex * increase, delta.y + timesIndex * increase)
                else
                    delta = ccp(delta.x * math.pow((1 + increase / 100), timesIndex), delta.y * math.pow((1 + increase / 100), timesIndex))
                end
            else
                if increaseMode == CHANGEMODE_FIX_VALUE then 
                    delta = ccp(delta.x + timesIndex * increase.x, delta.y + timesIndex * increase.y)
                else
                    delta = ccp(delta.x * math.pow((1 + increase.x / 100), timesIndex), delta.y * math.pow((1 + increase.y / 100), timesIndex))
                end
            end
        end

        if directionMode == DIRECTION_MODE_LR then 
            if startDirection == DIRECTION_LEFT then 
                p1 = ccpAdd(center, ccpMul(delta, -1, -1))
                p2 = center
                p3 = ccpAdd(center, delta)
                p4 = center
            else
                p1 = ccpAdd(center, delta)
                p2 = center
                p3 = ccpAdd(center, ccpMul(delta, -1, -1))
                p4 = center
            end
        elseif directionMode == DIRECTION_MODE_TB then 
            if startDirection == DIRECTION_TOP then 
                p1 = ccpAdd(center, delta)
                p2 = center
                p3 = ccpAdd(center, ccpMul(delta, -1, -1))
                p4 = center
            else
                p1 = ccpAdd(center, ccpMul(delta, -1, -1))
                p2 = center
                p3 = ccpAdd(center, delta)
                p4 = center
            end
        end

        return p1, p2, p3, p4
    end


    -- [构造动作]
    local actions = {}

    if times ~= UNLIMITED then
        for i = 1, times do
            local p1, p2, p3, p4 = getPositions(directionMode, startDirection, center, delta, increaseMode, increase, i)

            actions[#actions + 1] = CCMoveTo:create(deltaTime, p1)
            actions[#actions + 1] = CCMoveTo:create(deltaTime, p2)
            actions[#actions + 1] = CCMoveTo:create(deltaTime, p3)
            actions[#actions + 1] = CCMoveTo:create(deltaTime, p4)
        end
    end

    return A.line(actions)
end

--[[--

执行动作[来回移动]

### Useage:
    UAction.moveAround(参数集合)

### Aliases:

### Notice:
    [必填项]
        CCNode      **node**            结点
        number      **times**           移动次数
        number      **center**          位置中心处
        number      **delta**           位置偏移量
        number      **deltaTime**       位置偏移时间
        enum        **startDirection**  位置起始移动方向
    [关键项] 
        enum        **directionMode**   方向模式
        number      **increase**        位置增加值
        enum        **increaseMode**    位置增加模式
    [选填项]
        无
    [其他项]
        directionMode 参数可用的值：
            DIRECTION_MODE_LR           = 1
            DIRECTION_MODE_TB           = 2
            DIRECTION_MODE_D4           = 3
            DIRECTION_MODE_D5           = 4
            DIRECTION_MODE_D8           = 5
            DIRECTION_MODE_D9           = 6
        startDirection 参数可用的值：
            DIRECTION_LEFT              = 1
            DIRECTION_RIGHT             = 2
            DIRECTION_TOP               = 3
            DIRECTION_BOTTOM            = 4
        increaseMode 参数可用的值：
            CHANGEMODE_FIX_VALUE        = 1
            CHANGEMODE_PERCENTAGE       = 2

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    A.moveAround({
        node            = node,
        delta           = ccp(50, 0),
        deltaTime       = .3,
        times           = 3,
        startDirection  = DIRECTION_RIGHT,
        increase        = ccp(50, 0)
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.moveAround(params)
    -- [前处理]
    runActionBegan_("moveAround", params)

    -- [参数追加]
    params.center = params.node:point()

    -- [构造动作]
    local action = M.actionMoveAround(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[角度旋转]

### Useage:
    local action = UAction.actionMoveAngle(参数集合)

### Aliases:

### Notice:
    [必填项]
        number      **time**            运动时间
        number      **angle**           移动角度
        number      **velocity**        运动速度
        CCPoint     **pointZero**       中心点位置
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionMoveAngle({
        time        = 3.0,
        angle       = 30,
        velocity    = 10,
        pointZero   = V.POINTS.CENTER,
    })
    node:one(action)


    ----------------------
    -- 示例2: 复合操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    for i = 1, 30 do
        local angle     = i * (360 / 30)
        local node      = D.imgc("node.png"):to(layer)
        local action    = A.actionMoveAngle({
            time        = 1.0,
            angle       = angle,
            velocity    = 300,
            pointZero   = V.POINTS.CENTER,
        })
        node:one(action)
    end

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[角度旋转]

--]]--
function M.actionMoveAngle(params)
    -- [参数解析]
    params = totable(params)
    local time      = params.time
    local angle     = params.angle
    local velocity  = params.velocity
    local pointZero = ifnil(params.pointZero, CCPoint0)

    -- [验证]
    J.typeNumber(M.TAG, time,     "actionMoveAngle(..) invalid params.time!")
    J.typeNumber(M.TAG, angle,    "actionMoveAngle(..) invalid params.angle!")
    J.typeNumber(M.TAG, velocity, "actionMoveAngle(..) invalid params.velocity!")


    -- [操作变量]
    local distance    = time * velocity
    local pointTarget = PT.pointAngle(pointZero, angle, distance)

    -- [构造动作]
    return CCMoveTo:create(time, pointTarget)
end

--[[--

执行动作[角度旋转]

### Useage:
    UAction.moveAngle(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        number      **angle**           移动角度
        number      **velocity**        运动速度
        CCPoint     **pointZero**       中心点位置
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    A.moveAngle({
        node        = node,
        time        = 3.0,
        angle       = 30,
        velocity    = 10,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.moveAngle(params)
    -- [前处理]
    runActionBegan_("moveAngle", params)

    -- [参数追加]
    params.pointZero = params.node:point()

    -- [构造动作]
    local action = M.actionMoveAngle(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[圆形/椭圆运动]

### Useage:
    local action = UAction.actionOvalBy(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            运动时间
        CCPoint     **pointCenter**     椭圆中心点位置
    [关键项] 
        number      **side**            边长/半径(当设置side后，就可以不用设置sideA和sideB，设置side将默认椭圆为圆形)
        number      **sideA**           长边长
        number      **sideB**           短边长
        bool        **isClockwise**     是否顺时针运动
        number      **angle**           默认旋转角度
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作[椭圆]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionOvalBy({
        time        = 3.0,
        pointCenter = V.POINTS.CENTER,
        sideA       = 50,
        sideB       = 100,
        isClockwise = true,
        angle       = 30,
    })
    node:one(action)


    ----------------------
    -- 示例2: 通用操作[圆形]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionOvalBy({
        time        = 3.0,
        pointCenter = V.POINTS.CENTER,
        side        = 50,
        isClockwise = true,
        angle       = 30,
    })
    node:one(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[角度旋转]

--]]--
function M.actionOvalBy(params)
    -- [参数解析]
    params = totable(params)
    local time          = params.time
    local pointCenter   = params.pointCenter
    local side          = params.side
    local sideA         = ifnil(params.sideA, side)
    local sideB         = ifnil(params.sideB, side)
    local isClockwise   = ifnil(params.isClockwise, true)
    local angle         = ifnil(params.angle, 0)

    -- [验证]
    J.typeNumber(M.TAG, time,     "actionOvalBy(..) invalid params.time!")
    J.typeNumber(M.TAG, sideA,    "actionOvalBy(..) invalid params.sideA!")
    J.typeNumber(M.TAG, sideB,    "actionOvalBy(..) invalid params.sideB!")
    J.typeNumber(M.TAG, angle,    "actionOvalBy(..) invalid params.angle!")


    -- [构造动作]
    return tolua.cast(CCOvalBy:actionWithDuration(time, pointCenter, sideA, sideB, iff(isClockwise, 1, 0), angle), "cc.ActionInterval")
end

--[[--

执行动作[圆形/椭圆运动]

### Useage:
    UAction.ovalBy(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        CCPoint     **pointCenter**     椭圆中心点位置
    [关键项] 
        number      **side**            边长/半径(当设置side后，就可以不用设置sideA和sideB，设置side将默认椭圆为圆形)
        number      **sideA**           长边长
        number      **sideB**           短边长
        bool        **isClockwise**     是否顺时针运动
        number      **angle**           默认旋转角度
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    A.ovalBy({
        node        = node,
        pointCenter = V.POINTS.CENTER,
        time        = 3.0,
        side        = 50,
        isClockwise = true,
        angle       = 30,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.ovalBy(params)
    -- [前处理]
    runActionBegan_("ovalBy", params)

    -- [参数追加]
    params.pointCenter = ifnil(params.pointCenter, params.node:point())

    -- [构造动作]
    local action = M.actionOvalBy(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[圆形/螺旋]

### Useage:
    local action = UAction.actionCircleMove(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            运动时间
        CCPoint     **pointCenter**     椭圆中心点位置
    [关键项] 
        number      **scaleDiff**       缩放系数
        number      **angle**           旋转角度
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作[圆]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.img("node.png"):p(V.cx + 20, V.cy):to(layer)
    -- 构建动作
    -- 设置动画时间，圆心，是否缩放(不缩放设置为0.0)，旋转角度
    local action = A.actionCircleMove({
        time        = 10,
        pointCenter = V.POINTS.CENTER,
        scaleDiff   = 0.0,
        angle       = 1500,
    })
    -- 执行动作
    node:one(action)


    ----------------------
    -- 示例2: 通用操作[螺旋]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.img("node.png"):p(V.cx + 20, V.cy):to(layer)
    -- 构建动作
    -- 设置动画时间，圆心，缩放递增值0.01，旋转角度
    local action = A.actionCircleMove({
        time        = 10,
        pointCenter = V.POINTS.CENTER,
        scaleDiff   = 0.01,
        angle       = 1500,
    })
    -- 执行动作
    node:one(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[角度旋转]

--]]--
function M.actionCircleMove(params)
    -- [参数解析]
    params = totable(params)
    local time          = params.time
    local pointCenter   = params.pointCenter
    local scaleDiff     = ifnil(params.scaleDiff, 0)
    local angle         = params.angle

    -- [验证]
    J.typeNumber(M.TAG, time,     "actionCircleMove(..) invalid params.time!")
    J.typeNumber(M.TAG, scaleDiff,"actionCircleMove(..) invalid params.scaleDiff!")
    J.typeNumber(M.TAG, angle,    "actionCircleMove(..) invalid params.angle!")


    -- [构造动作]
    return tolua.cast(CCCircleMove:create(time, pointCenter, scaleDiff, angle), "cc.ActionInterval")
end

--[[--

执行动作[圆形/螺旋]

### Useage:
    UAction.circleMove(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        CCPoint     **pointCenter**     椭圆中心点位置
    [关键项] 
        number      **scaleDiff**       缩放系数
        number      **angle**           旋转角度
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作[圆]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.img("node.png"):p(V.cx + 20, V.cy):to(layer)
    -- 构建动作
    -- 设置动画时间，圆心，是否缩放(不缩放设置为0.0)，旋转角度
    A.circleMove({
        node        = node,
        time        = 10,
        pointCenter = V.POINTS.CENTER,
        scaleDiff   = 0.0,
        angle       = 1500,
    })


    ----------------------
    -- 示例2: 通用操作[螺旋]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.img("node.png"):p(V.cx + 20, V.cy):to(layer)
    -- 执行动作
    -- 设置动画时间，圆心，缩放递增值0.01，旋转角度
    A.circleMove({
        node        = node,
        time        = 10,
        pointCenter = V.POINTS.CENTER,
        scaleDiff   = 0.01,
        angle       = 1500,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.circleMove(params)
    -- [前处理]
    runActionBegan_("circleMove", params)

    -- [参数追加]
    -- 无

    -- [构造动作]
    local action = M.actionCircleMove(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[振动]

### Useage:
    local action = UAction.actionShake(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            振动时间
        CCPoint     **strength**        振动强度
    [关键项] 
        number      **strengthX**       振动强度x
        number      **strengthY**       振动强度y
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作[振动x,y方向相同]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionShake({
        time        = 3.0,
        strength    = 30,
    })
    node:one(action)


    ----------------------
    -- 示例2: 通用操作[振动x,y方向不同]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionShake({
        time        = 3.0,
        strengthX   = 30,
        strengthY   = 60,
    })
    node:one(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[角度旋转]

--]]--
function M.actionShake(params)
    -- [参数解析]
    params = totable(params)
    local time          = params.time
    local strength      = params.strength
    local strengthX     = ifnil(params.strengthX, strength)
    local strengthY     = ifnil(params.strengthY, ifnil(strength, strengthX))


    -- [验证]
    J.typeNumber(M.TAG, time,     "actionShake(..) invalid params.time!")
    J.typeNumber(M.TAG, strengthX,"actionShake(..) invalid params.strengthX!")
    J.typeNumber(M.TAG, strengthY,"actionShake(..) invalid params.strengthY!")


    -- [构造动作]
    return CCShake:createWithStrength(time, strengthX, strengthY)
end

--[[--

执行动作[振动]

### Useage:
    UAction.shake(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            振动时间
        CCPoint     **strength**        振动强度
    [关键项] 
        number      **strengthX**       振动强度x
        number      **strengthY**       振动强度y
    [选填项]

    [其他项]

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    A.shake({
        node        = node,
        time        = 3.0,
        strengthX   = 30,
        strengthY   = 60,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.shake(params)
    -- [前处理]
    runActionBegan_("shake", params)

    -- [构造动作]
    local action = M.actionShake(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[贝塞尔]

### Useage:
    local action = UAction.actionBezierTo(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            运动时间
        CCPoint     **startPosition**   起始坐标
        CCPoint     **controlPoint1**   控制点1
        CCPoint     **controlPoint2**   控制点2
        CCPoint     **endPosition**     结束坐标
        number      **high**            振动强度
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作[自动创建控制点]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionBezierTo({
        time            = 1.0,
        startPosition   = node:point(),
        endPosition     = ccp(100, 100),
    })
    node:one(action)


    ----------------------
    -- 示例2: 通用操作[手动创建控制点]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionBezierTo({
        time            = 1.0,
        startPosition   = node:point(),
        endPosition     = ccp(100, 100),
        controlPoint1   = ccp(353.5, 346.7),
        controlPoint2   = ccp(226.9, 273.5),
        high            = 300,
    })
    node:one(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[角度旋转]

--]]--
function M.actionBezierTo(params)
    -- [参数解析]
    params = totable(params)
    local time          = ifnil(params.time, 1.0)
    local startPosition = params.startPosition
    local endPosition   = params.endPosition
    local controlPoint1 = params.controlPoint1
    local controlPoint2 = params.controlPoint2
    local high          = ifnil(params.high, 100)

    -- [验证]
    J.typeNumber(M.TAG, time,           "actionBezierTo(..) invalid params.time!")
    J.typeCCPoint(M.TAG, startPosition, "actionBezierTo(..) invalid params.startPosition!")
    J.typeCCPoint(M.TAG, endPosition,   "actionBezierTo(..) invalid params.endPosition!")

    -- [自动创建]
    if (not controlPoint1) and (not controlPoint2) then 
        -- 验证
        J.typeNumber(M.TAG, high, "actionBezierTo(..) invalid params.high!")
        
        -- 起始点和结束点之间的差值
        local delta = ccpMul(ccpSub(endPosition, startPosition), .333)

        -- 计算过渡点
        -- 根据high跳跃点计算
        controlPoint1 = ccpAdd(startPosition, ccp(delta.x, delta.y + high))
        controlPoint2 = ccpAdd(startPosition, ccp(delta.x * 2, delta.y * 2 + high))
    end


    -- [日志输出]
    LO.system2({ object = M, method = "actionBezierTo()", message = "controlPoint1: " .. stringForCCPoint(controlPoint1) .. ", controlPoint2: " .. stringForCCPoint(controlPoint2) .. "." })


    -- [构造动作]
    -- 贝塞尔曲线
    local config = {controlPoint1, controlPoint2, endPosition}

    return cc.BezierTo:create(time, config)
end

--[[--

执行动作[贝塞尔]

### Useage:
    UAction.bezierTo(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        CCPoint     **startPosition**   起始坐标
        CCPoint     **controlPoint1**   控制点1
        CCPoint     **controlPoint2**   控制点2
        CCPoint     **endPosition**     结束坐标
        number      **high**            振动强度
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作[自动创建控制点]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    A.bezierTo({
        node            = node,
        time            = 1.0,
        endPosition     = ccp(100, 100),
    })


    ----------------------
    -- 示例1: 通用操作[手动创建控制点]
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    A.bezierTo({
        node            = node,
        time            = 1.0,
        endPosition     = ccp(100, 100),
        controlPoint1   = ccp(353.5, 346.7),
        controlPoint2   = ccp(226.9, 273.5),
        high            = 300,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.bezierTo(params)
    -- [前处理]
    runActionBegan_("bezierTo", params)

    -- [参数追加]
    params.startPosition = params.node:point()

    -- [构造动作]
    local action = M.actionBezierTo(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[翻转]

### Useage:
    local action = UAction.actionTurnOver(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            运动时间
        function    **fnTurnMiddle**    翻转到中间时的回调函数
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionTurnOver({
        time            = 1.0,
        fnTurnMiddle    = function()
            print("turn over!")
        end,
    })
    node:one(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[角度旋转]

--]]--
function M.actionTurnOver(params)
    -- [参数解析]
    params = totable(params)
    local time          = ifnil(params.time, 1.0)
    local fnTurnMiddle  = tofunction(params.fnTurnMiddle)

    -- [验证]
    J.typeNumber(M.TAG, time, "actionTurnOver(..) invalid params.time!")


    -- [日志输出]
    LO.system2({ object = M, method = "actionTurnOver()", message = "time: " .. tostring(time) })


    -- [构造动作]   
    local flip3D1 = tolua.cast(CCOrbitCamera:create(time / 2, 1, 0, 0, -90, 0, 0), "CCAction")
    local turn    = A.one({ "fn", fnTurnMiddle })
    local flip3D2 = tolua.cast(CCOrbitCamera:create(time / 2, 1, 0, -270, -90, 0, 0), "CCAction")
    return A.sequence({ flip3D1, turn, flip3D2 })
end

--[[--

执行动作[翻转]

### Useage:
    UAction.turnOver(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        function    **fnTurnMiddle**    翻转到中间时的回调函数
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    A.turnOver({
        node            = node,
        time            = 1.0,
        fnTurnMiddle    = function()
            print("turn over!")
        end,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.turnOver(params)
    -- [前处理]
    runActionBegan_("turnOver", params)

    -- [构造动作]
    local action = M.actionTurnOver(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[渐显渐隐]

### Useage:
    local action = UAction.actionFadeInOut(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            运动时间
        function    **fnMiddle**        渐显/渐隐到中间处的回调函数
        number      **delayMiddle**     渐显/渐隐到中间处时的延迟时间
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    local action = A.actionFadeInOut({
        time            = 1.0,
        fnMiddle        = function()
            print("middle!")
        end,
    })
    node:one(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[角度旋转]

--]]--
function M.actionFadeInOut(params)
    -- [参数解析]
    params = totable(params)
    local time          = ifnil(params.time, 1.0)
    local fnMiddle      = tofunction(params.fnMiddle)
    local delayMiddle   = ifnil(params.delayMiddle, 0)

    -- [验证]
    J.typeNumber(M.TAG, time, "actionFadeInOut(..) invalid params.time!")


    -- [日志输出]
    LO.system2({ object = M, method = "actionFadeInOut()", message = "time: " .. tostring(time) })


    -- [构造动作]
    local actions = {}
    actions[#actions + 1] = CCFadeIn:create(time / 2)
    if isnumber(delayMiddle) and delayMiddle ~= 0 then 
        actions[#actions + 1] = CCDelayTime:create(delayMiddle)
    end
    actions[#actions + 1] = CCCallFunc:create(fnMiddle)
    actions[#actions + 1] = CCFadeOut:create(time / 2)
    return A.line(actions)
end

--[[--

执行动作[翻转]

### Useage:
    UAction.turnOver(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        function    **fnMiddle**        渐显/渐隐到中间处的回调函数
        number      **delayMiddle**     渐显/渐隐到中间处时的延迟时间
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.img("node.png"):opacity(0):pc():to(layer)
    A.fadeInOut({
        node            = node,
        time            = 1.0,
        fromAlpha       = 0,
        isAutoRemove    = false,
        fnBegan         = function(node)
            print("began!")
        end,
        fnMiddle        = function()
            print("middle!")
        end,
        fnEnd           = function(node)
            print("end!")
        end,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.fadeInOut(params)
    -- [前处理]
    runActionBegan_("fadeInOut", params)

    -- [参数追加]
    local node              = CCSpriteExtend.extend(params.node)
    local fnBegan           = tofunction(params.fnBegan)
    local fnEnd             = tofunction(params.fnEnd)
    local fromAlpha         = params.fromAlpha
    local isAutoRemove      = ifnil(isAutoRemove, false)

    -- [构造动作]
    local action  = nil
    if true then 
        local actions = {}

        -- 处理前处理
        actions[#actions + 1] = CCCallFunc:create(function()  
            fnBegan(node)

            -- 设置初始透明度
            if isnumber(fromAlpha) then
                node:setOpacity(fromAlpha)
            end
        end)
        -- 渐显渐隐
        actions[#actions + 1] = M.actionFadeInOut(params)
        -- 处理前处理
        actions[#actions + 1] = CCCallFunc:create(function()  
            fnEnd(node)

            -- 自我清理
            if isAutoRemove then
                node:remove()
            end
        end)
        action = M.sequence(actions)
    end

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[云线路径]

### Useage:
    local action = UAction.actionCatmullRom(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            运动时间
        table       **points**          控制点列表
        bool        **relative**        是否相对操作(如果为真为by，假为to)
        function    **fnCallback**      回调函数
    [关键项] 
        无
    [选填项]
        无

    云线，在拐弯处移动速度稍快

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    -- 构建动作
    local action = nil
    local array  = {}
    table.insert(array, ccp(0, 0))
    table.insert(array, ccp(V.w_2 - 30, 0))
    table.insert(array, ccp(V.w_2 - 30, V.h - 80))
    table.insert(array, ccp(0, V.h - 80))
    table.insert(array, ccp(0, 0))
    action = A.actionCatmullRom({
        time            = 1.0,
        points          = array,
        fnCallback      = function(sender)
            print("ok")
        end,
    })
    node:runAction(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[云线路径]

--]]--
function M.actionCatmullRom(params)
    -- [参数解析]
    params = totable(params)
    local time          = ifnil(params.time, 1.0)
    local points        = ifnil(params.points, {})
    local relative      = ifnil(params.relative, false)
    local fnCallback    = params.fnCallback


    -- [验证]
    J.typeTable(M.TAG, points)


    -- [日志输出]
    LO.system2({ object = M, method = "actionCatmullRom()", message = "time: " .. tostring(time) })


    -- [构造动作]
    local actions = {}
    local clazz   = iff(relative, cc.CatmullRomBy, cc.CatmullRomTo)

    -- 动作[CCCatmullRom]
    local action = nil
    if true then 
        local array = {}
        for i = 1, #points do
           table.insert(array, points[i])
        end
        action = clazz:create(time, array)
    end
    actions[#actions + 1] = action

    -- 动作[CCCallFunc]
    if isfunction(fnCallback) then 
        actions[#actions + 1] = CCCallFunc:create(function()
            fnCallback(node)
        end)
    end

    return A.sequence(actions)
end

--[[--

执行动作[云线路径]

### Useage:
    UAction.catmullRom(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        table       **points**          控制点列表
        bool        **relative**        是否相对操作(如果为真为by，假为to)
        function    **fnCallback**      回调函数
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    -- 构建动作
    local array = {}
    table.insert(array, ccp(0, 0))
    table.insert(array, ccp(V.w_2 - 30, 0))
    table.insert(array, ccp(V.w_2 - 30, V.h - 80))
    table.insert(array, ccp(0, V.h - 80))
    table.insert(array, ccp(0, 0))
    A.catmullRom({
        node            = node,
        time            = 1.0,
        points          = array,
        fnCallback      = function(sender)
            print("ok")
        end,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.catmullRom(params)
    -- [前处理]
    runActionBegan_("catmullRom", params)

    -- [构造动作]
    local action = M.actionCatmullRom(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[样条曲线]

### Useage:
    local action = UAction.actionCardinalSpline(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            运动时间
        number      **tension**         松紧程度。tension==1时，样条线是分段直线。tension<1向外松弛弯曲，tension>1向内缩紧弯曲。
        table       **points**          控制点列表
        bool        **relative**        是否相对操作(如果为真为by，假为to)
        function    **fnCallback**      回调函数
    [关键项] 
        无
    [选填项]
        无

    轨迹 三个参数是: 移动一轮的时间,坐标组,浮张力(惯性)

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    -- 构建动作
    local action = nil
    local array  = {}
    table.insert(array, ccp(0, 0))
    table.insert(array, ccp(V.w_2 - 30, 0))
    table.insert(array, ccp(V.w_2 - 30, V.h - 80))
    table.insert(array, ccp(0, V.h - 80))
    table.insert(array, ccp(0, 0))
    action = A.actionCardinalSpline({
        time            = 1.0,
        tension         = 0,
        points          = array,
        fnCallback      = function(sender)
            print("ok")
        end,
    })
    node:runAction(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[样条曲线]

--]]--
function M.actionCardinalSpline(params)
    -- [参数解析]
    params = totable(params)
    local time          = ifnil(params.time, 1.0)
    local tension       = ifnil(params.tension, 1.0)
    local points        = ifnil(params.points, {})
    local relative      = ifnil(params.relative, false)
    local fnCallback    = params.fnCallback


    -- [验证]
    J.typeTable(M.TAG, points)
    J.typeNumber(M.TAG, tension)


    -- [日志输出]
    LO.system2({ object = M, method = "actionCardinalSpline()", message = "time: " .. tostring(time) })


    -- [构造动作]
    local actions = {}
    local clazz   = iff(relative, CCCardinalSplineBy, CCCardinalSplineTo)

    -- 动作[CCCardinalSplineBy]
    local action
    if true then 
        local array = {}
        for i = 1, #points do
           table.insert(array, points[i])
        end
        action = clazz:create(time, array, tension)
    end
    actions[#actions + 1] = action

    -- 动作[CCCallFunc]
    if isfunction(fnCallback) then 
        actions[#actions + 1] = CCCallFunc:create(function()
            fnCallback(node)
        end)
    end

    return A.sequence(actions)
end

--[[--

执行动作[样条曲线]

### Useage:
    UAction.cardinalSpline(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        number      **tension**         松紧程度。tension==1时，样条线是分段直线。tension<1向外松弛弯曲，tension>1向内缩紧弯曲。
        table       **points**          控制点列表
        function    **fnCallback**      回调函数
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    -- 构建动作
    local array = {}
    table.insert(array, ccp(0, 0))
    table.insert(array, ccp(V.w_2 - 30, 0))
    table.insert(array, ccp(V.w_2 - 30, V.h - 80))
    table.insert(array, ccp(0, V.h - 80))
    table.insert(array, ccp(0, 0))
    A.cardinalSpline({
        node            = node,
        time            = 1.0,
        tension         = 0,
        points          = array,
        fnCallback      = function(sender)
            print("ok")
        end,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.cardinalSpline(params)
    -- [前处理]
    runActionBegan_("cardinalSpline", params)

    -- [构造动作]
    local action = M.actionCardinalSpline(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[改变速度]

### Useage:
    local action = UAction.actionChangeSpeed(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCAction    **action**          动作对象
        number      **speed**           速度值
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 构建动作
    local action = A.line({
        { "moveTo",   1.0, ccp(100, 100), },
        { "scaleTo",  2.0, 2, },
        { "rotateBy", 2.0, 2, },
    })
    local action = A.actionChangeSpeed({
        action   = action,
        speed    = 2,
    })
    node:runAction(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[改变速度]

--]]--
function M.actionChangeSpeed(params)
    -- [参数解析]
    params = totable(params)
    local action        = params.action
    local speed         = ifnil(params.speed, 1.0)


    -- [验证]
    J.notNil(M.TAG, action)


    -- [日志输出]
    LO.system2({ object = M, method = "actionChangeSpeed()", message = "speed: " .. tostring(speed) })


    -- [构造动作]
    return CCSpeed:create(action, speed)
end

--[[--

执行动作[改变速度]

### Useage:
    UAction.changeSpeed(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        CCAction    **action**          动作对象
        number      **speed**           速度值
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 构建动作
    local action = A.line({
        { "moveTo",   1.0, ccp(100, 100), },
        { "scaleTo",  2.0, 2, },
        { "rotateBy", 2.0, 2, },
    })
    A.changeSpeed({
        node            = node,
        action          = action,
        speed           = 2,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.changeSpeed(params)
    -- [前处理]
    runActionBegan_("changeSpeed", params)

    -- [构造动作]
    local action = M.actionChangeSpeed(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

获得动作[移动+渐显/隐]

### Useage:
    local action = UAction.actionFadeMove(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        number      **time**            运动时间
        CCPoint     **position**        位置
    [关键项] 
        number      **opacity**         透明度
        bool        **isAbsolute**      是否是绝对路径
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    -- 构建动作
    local action = nil
    action = A.actionFadeMove({
        time            = 1.0,
        position        = ccp(0, 50),
        opacity         = 0,
        isAbsolute      = false,
    })
    node:runAction(action)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[移动+渐显/隐]

--]]--
function M.actionFadeMove(params)
    -- [参数解析]
    params = totable(params)
    local time          = ifnil(params.time, 1.0)
    local position      = ifnil(params.position, CCPoint0)
    local opacity       = ifnil(params.opacity, 0)
    local isAbsolute    = ifnil(params.isAbsolute, false)


    -- [验证]
    J.typeNumber(M.TAG, time)


    -- [日志输出]
    LO.system2({ object = M, method = "actionFadeMove()", message = "time: " .. tostring(time) })


    -- [构造动作]
    local actions = {}

    -- 动作[actionFadeMove]
    local action = A.union({
        { "FadeTo", time, opacity, },
        { iff(isAbsolute, "MoveTo", "MoveBy"), time, position, },
    })

    return action
end

--[[--

执行动作[移动+渐显/隐]

### Useage:
    UAction.fadeMove(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            运动时间
        CCPoint     **position**        位置
    [关键项] 
        number      **opacity**         透明度
        bool        **isAbsolute**      是否是绝对路径
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    A.fadeMove({
        node            = node,
        time            = 1.0,
        position        = ccp(0, 50),
        opacity         = 0,
        isAbsolute      = false,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.fadeMove(params)
    -- [前处理]
    runActionBegan_("fadeMove", params)

    -- [构造动作]
    local action = M.actionFadeMove(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

执行动作[移动+果冻]

### Useage:
    UAction.moveJelly(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **toTime**          目标时间
        CCPoint     **toPosition**      目标位置
    [关键项] 
        number      **delay**           延迟时间
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    -- 构建动作
    A.moveJelly({
        node        = node,
        toPosition  = ccp(V.cx, 100),
        toTime      = 1.0,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.moveJelly(params)
    -- [前处理]
    runActionBegan_("moveJelly", params)

    -- [参数解析]
    local node          = params.node
    local delay         = ifnil(params.delay, 0)
    local toTime        = ifnil(params.toTime, 1.0)
    local toPosition    = ifnil(params.toPosition, CCPoint0)

    -- [构造动作]
    local anchorStart = ccp(0.5, 0.3)
    local anchorEnd   = node:getAnchorPoint()
    local action      = A.line({
        { "fn", function() ND.setAnchorPoint(node, anchorStart, true) end },
        { "delay", delay },
        A.union({
            {"easing", "elasticOut", {"moveTo", toTime, toPosition }},
            { "delay", 0.2 },
            { "scaleTo", 0.15, 1.3, 0.7 },
            { "scaleTo", 0.15, 1.0, 1.0 },
            { "scaleTo", 0.20, 1.2, 0.8 },
            { "scaleTo", 0.20, 1.0, 1.0 },
        }),
        { "fn", function() ND.setAnchorPoint(node, anchorEnd, true) end },
    })

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

执行动作[缩放回弹]

### Useage:
    UAction.scaleSpringback(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            时间
        number      **scale0**          缩放比例[起始]
        number      **scale1**          缩放比例[结束]
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 构建动作
    local action = A.line({
        { "moveTo",   1.0, ccp(100, 100), },
        { "scaleTo",  2.0, 2, },
        { "rotateBy", 2.0, 2, },
    })
    A.scaleSpringback({
        node     = node,
        time     = 1.0,
        scale0   = 0.2,
        scale1   = 1.0,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[缩放回弹]

--]]--
function M.scaleSpringback(params)
    -- [前处理]
    runActionBegan_("springback", params)

    -- [参数解析]
    params = totable(params)
    local node          = params.node
    local time          = ifnil(params.time, 1.0)
    local scale0        = ifnil(params.scale0, 0.2)
    local scale1        = ifnil(params.scale1, 1.0)


    -- [验证]
    J.typeNumber(M.TAG, time, "springback(..) invalid params.time!")


    -- [日志输出]
    LO.system2({ object = M, method = "springback()", message = string.format("scale0: %.2f, scale1: %.2f, time: %.2f!", scale0, scale1, time) })


    -- [构造动作]
    node:setScale(scale0)
    local action = A.one({ "easing", "ElasticOut", { "ScaleTo", time, scale1 } })

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

执行动作[切换图片]

### Useage:
    UAction.switchImage(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        table       **images**          图像集合
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 添加按钮
    local button = U.loadButton({
        images      = "node.png",                   -- 按钮图片
        texts       = "Hello, World",               -- 标签文字
        fnClicked   = function(sender, x, y, touches)      -- 事件函数[点击]
            A.switchImage({
                node    = node,
                images  = { 
                    "samples/button/btn-a-1.png",
                    "samples/button/btn-a-2.png",
                    "samples/button/btn-a-3.png",
                },
                clear   = false,
            })
        end,
    }):p(100, 100):to(layer)

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.switchImage(params)
    -- [前处理]
    runActionBegan_("switchImage", params)

    -- [参数解析]
    params = totable(params)
    local node          = params.node
    local images        = ifnil(params.images, {})
    local clear         = ifnil(params.clear, false)


    -- [验证]
    J.typeTable(M.TAG, images, "switchImage(..) invalid params.images!")
    J.numberOver0(M.TAG, #images, "switchImage(..) invalid params.images length!")


    -- [日志输出]
    -- 无


    -- [构造动作]
    if clear or (not node.__a_switchimage__) then 
        node.__a_switchimage__      = images
        node.__a_switchimage_i__    = 1
    end
    local action = A.one({ "fn", function()
        local _,index = N.mod(node.__a_switchimage_i__, #node.__a_switchimage__)
        index = index + 1
        local image = node.__a_switchimage__[index]
        node:display(image)

        node.__a_switchimage_i__ = node.__a_switchimage_i__ + 1
    end })

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

执行动作[播放粒子效果]

### Useage:
    UAction.actionParticle(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            父结点
        string      **path**            料子效果文件路径
        CCPoint     **position**        位置
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 添加粒子效果
    A.actionParticle({
        node    = node,
        path    = "samples/particle/common.plist"
    }):at(node)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[粒子效果]

--]]--
function M.actionParticle(params)
    -- [参数解析]
    params = totable(params)
    local path          = params.path
    local node          = ifnil(params.node, D.getRunningScene())
    local z             = ifnil(params.z, 0)
    local position      = ifnil(params.position, CCPoint0)


    -- [验证]
    J.typeString(M.TAG, path)


    -- [日志输出]
    LO.system2({ object = M, method = "actionParticle()", message = "path: " .. tostring(path) .. ", position: " .. stringForCCPoint(position) })


    -- [构造动作]
    local actions = {}

    -- 动作[actionParticle]
    local action = A.one({
        "fn", 
        function()
            print(z)
            print(z)
            print(z)
            print(z)
            print(z)
            P.newParticle(path, position.x, position.y):z(z):to(node)
        end 
    })

    return action
end

--[[--

执行动作[播放粒子效果]

### Useage:
    UAction.particle(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            父结点
        string      **path**            料子效果文件路径
        CCPoint     **position**        位置
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node = D.imgc("node.png"):to(layer)
    A.particle({
        node    = node,
        path    = "samples/particle/common.plist",
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.particle(params)
    -- [前处理]
    runActionBegan_("particle", params)

    -- [构造动作]
    local action = M.actionParticle(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

执行动作[移动来回]

### Useage:
    UAction.actionMoveGoBack(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            时间
        CCPoint     **position**        位置
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 添加粒子效果
    A.actionMoveGoBack({
        node        = node,
        time        = 1.0,
        position    = ccp(100, 100),
    }):at(node)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[移动来回]

--]]--
function M.actionMoveGoBack(params)
    -- [参数解析]
    params = totable(params)
    local time      = params.time
    local node      = ifnil(params.node)
    local position  = ifnil(params.position, CCPoint0)


    -- [验证]
    J.typeNumber(M.TAG, time)


    -- [日志输出]
    LO.system2({ object = M, method = "actionMoveGoBack()", message = "time: " .. tostring(time) .. ", position: " .. stringForCCPoint(position) })


    -- [构造动作]
    local actions = {}

    -- 动作[actionMoveGoBack]
    local action = nil
    local unit = A.one({ "MoveTo", time / 2, position })
    action = A.line({
        unit,
        { "fn", 
            function()
                A.one(unit:reverse()):at(node)
            end 
        }
    })

    return action
end

--[[--

执行动作[移动来回]

### Useage:
    UAction.moveGoBack(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            时间
        CCPoint     **position**        位置
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 添加粒子效果
    A.moveGoBack({
        node        = node,
        time        = 1.0,
        position    = ccp(100, 100),
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.moveGoBack(params)
    -- [前处理]
    runActionBegan_("moveGoBack", params)

    -- [构造动作]
    local action = M.actionMoveGoBack(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

执行动作[旋转来回]

### Useage:
    UAction.actionRotateGoBack(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            时间
        CCPoint     **position**        位置
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 添加粒子效果
    A.actionRotateGoBack({
        node        = node,
        time        = 1.0,
        rotation    = 120,
    }):at(node)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[旋转来回]

--]]--
function M.actionRotateGoBack(params)
    -- [参数解析]
    params = totable(params)
    local time      = params.time
    local node      = ifnil(params.node)
    local rotation  = ifnil(params.rotation, 360)


    -- [验证]
    J.typeNumber(M.TAG, time)


    -- [日志输出]
    LO.system2({ object = M, method = "actionRotateGoBack()", message = "time: " .. tostring(time) .. ", rotation: " .. rotation })


    -- [构造动作]
    local actions = {}
    -- [状态记录]
    local origin  = node:getRotation()

    -- 动作[actionRotateGoBack]
    local action = A.line({
        { "RotateTo", time / 2, rotation },
        { "RotateTo", time / 2, origin },
    })

    return action
end

--[[--

执行动作[旋转来回]

### Useage:
    UAction.rotateGoBack(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            时间
        CCPoint     **position**        位置
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 添加粒子效果
    A.rotateGoBack({
        node        = node,
        time        = 1.0,
        rotation    = 120,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.rotateGoBack(params)
    -- [前处理]
    runActionBegan_("rotateGoBack", params)

    -- [构造动作]
    local action = M.actionRotateGoBack(params)

    -- [后处理]
    return runActionEnded_(action, params)
end

--[[--

执行动作[缩放来回]

### Useage:
    UAction.actionScaleGoBack(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            时间
        number      **scale**           缩放比例
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 添加粒子效果
    A.actionScaleGoBack({
        node        = node,
        time        = 1.0,
        scale       = 2.0,
    }):at(node)

### Parameters:
-   table **params**        参数集合

### Returns: 
-   CCAction                动作[移动来回]

--]]--
function M.actionScaleGoBack(params)
    -- [参数解析]
    params = totable(params)
    local time      = params.time
    local node      = ifnil(params.node)
    local scale     = ifnil(params.scale, 0)


    -- [验证]
    J.typeNumber(M.TAG, time)


    -- [日志输出]
    LO.system2({ object = M, method = "actionScaleGoBack()", message = "time: " .. tostring(time) .. ", scale: " .. scale })


    -- [构造动作]
    local actions = {}
    -- [状态记录]
    local origin  = node:getScale()

    -- 动作[actionScaleGoBack]
    local action = A.line({
        { "ScaleTo", time / 2, scale },
        { "ScaleTo", time / 2, origin },
    })

    return action
end

--[[--

执行动作[缩放来回]

### Useage:
    UAction.scaleGoBack(参数集合)

### Aliases:

### Notice:
    参数集合说明:
    [必填项]
        CCNode      **node**            结点
        number      **time**            时间
        CCPoint     **position**        位置
    [关键项] 
        无
    [选填项]
        无

### Example:
    ----------------------
    -- 示例1: 通用操作
    ----------------------
    -- 测试环境
    local scene, layer = game:enterDemoScene()

    -- 添加结点
    local node   = D.imgc("node.png"):to(layer)
    -- 添加粒子效果
    A.scaleGoBack({
        node        = node,
        time        = 1.0,
        scale       = 2.0,
    })

### Parameters:
-   table **params**        参数集合

### Returns: 

--]]--
function M.scaleGoBack(params)
    -- [前处理]
    runActionBegan_("scaleGoBack", params)

    -- [构造动作]
    local action = M.actionScaleGoBack(params)

    -- [后处理]
    return runActionEnded_(action, params)
end



return M