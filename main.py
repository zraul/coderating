# -*- coding:utf-8-*-

import sys
import os
import re
from coderegex import _LUA_FUNCTION_REGEX
from coderegex import _LUA_LOCAL_VARIABLE_REGEX
from coderegex import _LUA_COMMENTS_REGEX


# 所有函数列表
fun_list = []
# 注释列表
remark_list = []
# 评分错误内容
rating_result = []

#
# 加载需要评分的文件
# filename:文件名称
#
def loadFile(filename):
    file = open(filename, 'r')
    content = file.read()
    file_lines = content.splitlines()
    doLuaCommentsCheck(content, file_lines)
    doLuaAllFunctionCheck(content, file_lines)


#
#   检查文件注释
#
#
def doLuaCommentsCheck(content, file_lines):
    print('doLuaCommentsCheck')
    comments_list = _LUA_COMMENTS_REGEX.findall(content)
    luaCheckFileHeaderComments(comments_list[0][0], comments_list[1][0])

#
#   检查文件头注释
#   copyrightComments：文件头版权注释
#   functionComments：文件作用注释
#
def luaCheckFileHeaderComments(copyrightComments, functionComments):
    if copyrightComments.count('http://www.babybus.com/superdo/') >= 1 \
            and copyrightComments.count('Copyright (c) 2012-2013 baby-bus.com') >= 1:
        print('文件头版权声明正确')
    else:
        print('文件头版权声明错误')

    if functionComments.count('!--') >= 1 and len(functionComments) >= 5:
        print('文件作用声明正确')
    else:
        print('文件作用声明错误')

#
#   检查函数内容
#
#
def doLuaAllFunctionCheck(content, file_lines):
    fun_list = _LUA_FUNCTION_REGEX.findall(content)
    for i in range(len(fun_list)):
        try:
            length = getAllFunctionContent(file_lines.index(fun_list[i][0].strip()), file_lines)
            # if length > 20:
            #     print("%s 函数超过20行" % file_lines.index(fun_list[i][0].strip()))

            # 函数名与参数格式检查
            # luaCheckFunctionName(fun_list[i][1].strip())

            # local变量检查
            if file_lines.index(fun_list[i][0].strip()) + 1 == 2081:
                fun_line = file_lines[file_lines.index(fun_list[i][0].strip()):file_lines.index(fun_list[i][0].strip()) + length]
                luaCheckLoacalVariable(fun_line)
                luaCheckIsAlign(fun_line)
                checkFunctionLineIsTooLong(fun_line)
        except Exception,e:
            pass

#
# 获取完整函数内容,返回函数行数
#
def getAllFunctionContent(number, file_lines):
    for i in range(200):
        if file_lines[number + i] == 'end':
            return i + 1

    return 0

#
# 检查函数每行是否超过120列
#
def checkFunctionLineIsTooLong(fun_lines):
    for i in range(len(fun_lines)):
        if len(fun_lines[i]) >= 120:
            print("函数列超过120列")

#
# 检查函数名称与函数
# line(list):具体内容
#
def luaCheckFunctionName(line):
    # 函数名称
    name = line[0:line.find('(')]

    # 函数参数
    argument = line[line.find('(') + 1:line.rfind(')')]

    name.strip()
    if '.' in name:
        name = name[name.find('.') + 1:]

    if not name[0].islower():
        print("the first characters is not lower")

    # 判断是否有多个单词组成
    if re.findall('[A-Z]', name):
        print('this function name is wright')
    else:
        if len(name) >= 8:
            print('this function name may be wrong')

    # 多个参数逗号间是否有空格
    if ',' in argument:
        count = argument.count(',')
        for i in range(count):
            if ', ' not in argument:
                print('函数参数逗号未空格')
                break
            else:
                argument = argument.replace(', ', '', 1)
    else:
        print('函数未包含两个以上参数')

#
# 判断函数内部local变量
# fun_lines(list):函数全部内容
#
def luaCheckLoacalVariable(fun_lines):
    lines = '\n'.join(fun_lines)
    localVariable = _LUA_LOCAL_VARIABLE_REGEX.findall(lines)
    print(localVariable)
    for i in range(len(localVariable)):
        if '=' not in localVariable[i][0]:
            print('%s 变量未初始化或赋值' % localVariable[i][0])

        if localVariable[i][0].count(',') >= 4:
            print('同一行变量赋值过多')

#
# 判断函数是否对齐,每行遍历,进行前后对比,后期需要改进逻辑
# fun_lines(list):函数全部内容
#
def luaCheckIsAlign(fun_lines):
    lineTabCnt = []
    for i in range(len(fun_lines)):
        # print("%s %d" % (fun_lines[i], getSpaceCnt(fun_lines[i])))
        lineTabCnt.append(getSpaceCnt(fun_lines[i]))

    for n in range(1, len(fun_lines) - 1):
        # if/for判断
        if ('if' in fun_lines[n]) or ('for' in fun_lines[n]):
            # print('if 开始行 %d' % n)
            m = 0
            for m in range(1, len(fun_lines) - n):
                if ((lineTabCnt[n + m] - lineTabCnt[n]) % 4 != 0):
                    print('格式未对齐')
                    break

                if ('end' in fun_lines[n + m]) and (lineTabCnt[n + m] == lineTabCnt[n]):
                    # print('if结束行 %d' % ( n + m))
                    break

                if m == (len(fun_lines) - n - 1):
                    print('%d行end未对齐或未写end' % n)

        elif ((lineTabCnt[n] - lineTabCnt[n-1]) % 4 != 0):
            print('%d 行与其它行格式未对齐' % (n))
        elif (lineTabCnt[n] == 0) and (len(fun_lines[n]) != 0):
            print('%d 行直接顶格' % n)


#
# 获取空格数目
# line:内容
#
def getSpaceCnt(line):
    cnt = 0
    for i in range(len(line)):
        if line[i] == ' ':
            cnt = cnt + 1
        else:
            break

    return cnt

def main():
    filename = sys.argv[1]
    loadFile(filename)

if __name__ == '__main__':
    main()