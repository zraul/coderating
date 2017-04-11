# -*- coding:utf-8-*-

import sys
import re

_LUA_COMMENTS_REGEX = re.compile(ur'(--\[\[(\s|\S)*?\]\](--)*)')
_LUA_FUNCTION_REGEX = re.compile(ur'((local ){0,1}function\s+(.*))')
_LUA_LOCAL_VARIABLE_REGEX = re.compile(ur'(local\s(.)*)')
_LUA_FUNCTION_WITH_COMMENTS_REGEX = re.compile(ur'(--\[\[(\s|\S)*?\]\](--)*(\s)*(local ){0,1}function\s+(.*))')

class Rating(object):
    def __init__(self):
        self.ratingResultList = []
        self.fileLines = []
        self.oneLineKeywordsList = ['if', 'for', 'do', 'while', 'case', 'switch', 'default']
        self.secondOperatorList = ['+', '*', '/', '%', '>', '<', '>=', '<=']
        self.boolHeader = ['is', 'can', 'has']

    #
    # 加载需要评分的文件
    # filename:文件名称
    #
    def loadFile(self, filename):
        file = open(filename, 'r')
        self.content = file.read()
        self.fileLines = self.content.splitlines()
        self.doLuaCommentsCheck(self.content)
        self.doLuaAllFunctionCheck(self.content)

    #
    # 获取报错所在行
    #
    def getLineNumber(self, content):
        try:
            return self.fileLines.index(content) + 1
        except Exception:
            pass


    #
    # 检查是方法注释是否完整
    #
    def checkFunctionWithComments(self, functionWithCommentsList, functionList):
        tmpFunctionList = []
        for i in range(len(functionWithCommentsList)):
            tmpFunctionList.append(functionWithCommentsList[i][0].splitlines()[-1])


        for i in range(len(tmpFunctionList)):
            if tmpFunctionList[i] in functionList:
                if 'M.' in tmpFunctionList[i]:
                    self.checkPluginFunctionComments(functionWithCommentsList[i][0], tmpFunctionList[i])
                elif 'M:' in tmpFunctionList[i]:
                    self.checkMemberFunctionComments(functionWithCommentsList[i][0], tmpFunctionList[i])
                else:
                    self.checkPrivateFunctionComments(functionWithCommentsList[i][0], tmpFunctionList[i])
            else:
                self.ratingResultList.append('%s:方法未写注释内容' % self.getLineNumber(tmpFunctionList[i]))

    #
    # 检查方法[插件]注释
    #
    def checkPluginFunctionComments(self, content, functionName):
        try:
            if 'Parameters:' not in content:
                self.ratingResultList.append('%s:缺少参数注释' % self.getLineNumber(functionName))

            if 'Returns:' not in content:
                self.ratingResultList.append('%s:缺少返回参数注释' % self.getLineNumber(functionName))

            if 'Useage:' not in content:
                self.ratingResultList.append('%s:缺少用法注释' % self.getLineNumber(functionName))

            if 'Refer' not in content:
                self.ratingResultList.append('%s:缺少关联函数注释' % self.getLineNumber(functionName))

            if 'See' not in content:
                self.ratingResultList.append('%s:缺少参考文档注释' % self.getLineNumber(functionName))
        except Exception:
            pass

    #
    # 检查私有方法注释
    #
    def checkPrivateFunctionComments(self, content, functionName):
        try:
            if '-- ' not in content.splitlines()[-2]:
                self.ratingResultList.append('%s 私有方法缺少注释' % self.getLineNumber(functionName))
        except Exception:
            pass

    #
    # 检查成员方法注释
    #
    def checkMemberFunctionComments(self, content, functionName):
        try:
            if '-- ' not in content.splitlines()[-2]:
                self.ratingResultList.append('%s 成员方法缺少注释' % self.getLineNumber(functionName))
        except Exception:
            pass

    #
    # 检查文件注释
    #
    def doLuaCommentsCheck(self, content):
        comments_list = _LUA_COMMENTS_REGEX.findall(content)
        self.luaCheckFileHeaderComments(comments_list[0][0], comments_list[1][0])

    #
    # 检查文件头注释
    # copyrightComments：文件头版权注释
    # functionComments：文件作用注释
    #
    def luaCheckFileHeaderComments(self, copyrightComments, functionComments):
        if copyrightComments.count('http://www.babybus.com/superdo/') >= 1 \
                and copyrightComments.count('Copyright (c) 2012-2013 baby-bus.com') >= 1:
            pass
            # print('文件头版权声明正确')
        else:
            self.ratingResultList.append('文件头版权声明错误')
            # print('文件头版权声明错误')

        if functionComments.count('!--') >= 1 and len(functionComments) >= 5:
            pass
            # print('文件作用声明正确')
        else:
            self.ratingResultList.append('文件作用声明错误')
            # print('文件作用声明错误')

    #
    # 检查函数内容
    #
    def doLuaAllFunctionCheck(self, content):
        functionList = _LUA_FUNCTION_REGEX.findall(content)
        realFunctionList = []
        for i in range(len(functionList)):
            try:
                length = self.getAllFunctionContent(self.fileLines.index(functionList[i][0].strip()))
                lineNumber = self.fileLines.index(functionList[i][0].strip())
                if length > 20:
                    self.ratingResultList.append("%d:函数超过20行" % (lineNumber + 1))

                # 保存所有的函数
                realFunctionList.append(functionList[i][0].strip())

                # 函数名与参数格式检查
                self.doCheckFunctionName(functionList[i][0].strip(), lineNumber)

                # 检查方法内容
                functionLines = self.fileLines[lineNumber:lineNumber + length]
                self.doCheckLoacalVariable(functionLines, lineNumber)
                self.doCheckIsAlign(functionLines, lineNumber)
                self.checkFunctionLineIsTooLong(functionLines, lineNumber)
                self.checkFunctionByLines(functionLines, lineNumber)
            except Exception:
                pass

        functionWithCommentsList = _LUA_FUNCTION_WITH_COMMENTS_REGEX.findall(content)
        self.checkFunctionWithComments(functionWithCommentsList, realFunctionList)

    #
    # 获取完整函数内容,返回函数行数
    #
    def getAllFunctionContent(self, number):
        for i in range(200):
            if self.fileLines[number + i] == 'end':
                return i + 1

        return 0

    #
    # 检查函数每行是否超过120列,遍历方法每一行
    #
    def checkFunctionLineIsTooLong(self, functionLines, lineNumber):
        for i in range(len(functionLines)):
            if len(functionLines[i]) >= 120:
                self.ratingResultList.append('%d:单列超过120' % (lineNumber + i + 1))

    #
    # 逐行遍历函数，进行部分检查
    #
    def checkFunctionByLines(self, functionLines, lineNumber):
        for m in range(len(functionLines)):
            self.doCheckCommaIsContainSpace(functionLines[m], lineNumber + m + 1)
            self.doCheckOneLineKeyWords(functionLines[m], lineNumber + m + 1)
            self.doCheckOperatorWithSpace(functionLines[m], lineNumber + m + 1)


    #
    # 判断运算符两端是否有空格
    #
    def doCheckOperatorWithSpace(self, lineContent, lineNumber):
        try:
            for i in range(len(self.secondOperatorList)):
                if (self.secondOperatorList[i] in lineContent)  and ('--' not in lineContent):
                    if (' ' + self.secondOperatorList[i] + ' ') not in lineContent:
                        self.ratingResultList.append('%d:%s操作符两端未填充空格' % (lineNumber, self.secondOperatorList[i]))
        except Exception:
            pass

    #
    # 判断是否逗号后面是否有空格, 只有回车的空行会引起调用错误
    #
    def doCheckCommaIsContainSpace(self, lineContent, lineNumber):
        try:
            if (lineContent.index(',') != -1) and ('--' not in lineContent) and (not lineContent.endswith(',')):
                for i in range(lineContent.count(',')):
                    if ', ' not in lineContent:
                        self.ratingResultList.append('%d:逗号后未追加空格' % (lineNumber))
                        break
                    else:
                        lineContent = lineContent.replace(', ', '', 1)
        except Exception:
            pass

    #
    # 检查if、for、do、while、case、switch、default等语句自占一行
    #
    def doCheckOneLineKeyWords(self, lineContent, lineNumber):
        try:
            for i in range(len(self.oneLineKeywordsList)):
                if lineContent.index(self.oneLineKeywordsList[i]) != -1:
                    if lineContent.endswith('end'):
                        # print('%d %s' % (startLineNumber + indexLineNumber + 1, lineContent))
                        self.ratingResultList.append('%d:%s语句未独占一行' % (lineNumber, self.oneLineKeywordsList[i]))
        except Exception:
            pass

    #
    # 检查函数名称与函数
    # line(list):具体内容
    #
    def doCheckFunctionName(self, function, lineNumber):
        # 函数名称
        name = function[0:function.find('(')]

        # 函数参数
        argument = function[function.find('(') + 1:function.rfind(')')]

        name.strip()
        if '.' in name:
            name = name[name.find('.') + 1:]

        if not name[0].islower():
            self.ratingResultList.append('%s:函数名非小写字母开头' % (lineNumber + 1))
            # print("the first characters is not lower")

        # 判断是否有多个单词组成
        if re.findall('[A-Z]', name):
            pass
        else:
            if len(name) >= 10:
                self.ratingResultList.append('%s:函数名长度超过10个字母未分词,可能存在错误' % (lineNumber + 1))
                # print('this function name may be wrong')

        # 多个参数逗号间是否有空格
        if ',' in argument:
            count = argument.count(',')
            for i in range(count):
                if ', ' not in argument:
                    self.ratingResultList('%s:函数参数逗号之间为留有空格' % (lineNumber + 1))
                    # print('函数参数逗号未空格')
                    break
                else:
                    argument = argument.replace(', ', '', 1)
        else:
            pass

    #
    # 判断函数内部local变量
    #
    def doCheckLoacalVariable(self, functionLines, lineNumber):
        lines = '\n'.join(functionLines)
        localVariable = _LUA_LOCAL_VARIABLE_REGEX.findall(lines)
        for i in range(1, len(localVariable)):
            if '=' not in localVariable[i][0]:
                self.ratingResultList.append('%d:变量未初始化或者赋值' % (self.getLineNumberInFunction(functionLines, localVariable[i][0]) + lineNumber))

            if localVariable[i][0].count(',') >= 4:
                self.ratingResultList.append('%d:同一行变量赋值过多' % (self.getLineNumberInFunction(functionLines, localVariable[i][0]) + lineNumber))

            if ('= true' in localVariable[i][0]) or ('= false' in localVariable[i][0]):
                for m in range(len(self.boolHeader)):
                    if self.boolHeader[i] not in localVariable[i][0]:
                        self.ratingResultList.append('%d:布尔变量命令错误' % (self.getLineNumberInFunction(functionLines, localVariable[i][0]) + lineNumber))
                        break

    #
    # 查找结果在函数中的位置
    #
    def getLineNumberInFunction(self, lines, content):
        try:
            for i in range(len(lines)):
                if content in lines[i]:
                    return i + 1
        except Exception:
            return 0

    #
    # 判断函数是否对齐,每行遍历,进行前后对比,后期需要改进逻辑
    # fun_lines(list):函数全部内容
    #
    def doCheckIsAlign(self, functionLines, lineNumber):
        lineTabCnt = []
        for i in range(len(functionLines)):
            lineTabCnt.append(self.getSpaceCnt(functionLines[i]))

        for n in range(1, len(functionLines) - 1):
            # if/for判断
            if ('if ' in functionLines[n]) or ('for ' in functionLines[n]):
                # print('if 开始行 %d' % n)
                m = 0
                for m in range(1, len(functionLines) - n):
                    if ((lineTabCnt[n + m] - lineTabCnt[n]) % 4 != 0):
                        self.ratingResultList.append('%d:格式未与前行对齐' % (lineNumber + n + m + 1))
                        # print('格式未对齐')
                        break

                    if ('end' in functionLines[n + m]) and (lineTabCnt[n + m] == lineTabCnt[n]):
                        # print('if结束行 %d' % ( n + m))
                        break

                    if m == (len(functionLines) - n - 1):
                        self.ratingResultList.append('%d:end未对齐或未写end' % (lineNumber + n + m + 1))
                        # print('%d行end未对齐或未写end' % n)

            elif ((lineTabCnt[n] - lineTabCnt[n-1]) % 4 != 0):
                self.ratingResultList.append('%d:与其它行格式未对齐' % (lineNumber + n + 1))
                # print('%d 行与其它行格式未对齐' % (n))
            elif (lineTabCnt[n] == 0) and (len(functionLines[n]) != 0):
                self.ratingResultList.append('%d:直接顶格' % (lineNumber + n + 1))
                # print('%d 行直接顶格' % n)


    #
    # 获取空格数目
    # line:内容
    #
    def getSpaceCnt(self, line):
        cnt = 0
        for i in range(len(line)):
            if line[i] == ' ':
                cnt = cnt + 1
            else:
                break

        return cnt


def main():
    filename = sys.argv[1]
    rating = Rating()
    rating.loadFile(filename)
    out = open('result.txt', 'w+')
    for i in range(len(rating.ratingResultList)):
        out.writelines(rating.ratingResultList[i] + '\n')

    out.close()
    print('审查结束,结果保存在result.txt')

if __name__ == '__main__':
    main()