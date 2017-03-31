#coding:utf-8

import re

_JAVA_IMPORT_REGEX = re.compile('import [a-zA-Z\.0-9]*;')
_PYTHON_IMPORT_REGEX = re.compile('import [a-zA-Z\_\.]*')
_OBJECTIVE_C_IMPORT_REGEX = re.compile('#import \"[a-zA-Z\_\.\+]*\"')

_JAVA_CLASS_REGEX = re.compile('(private|public){1} class [a-zA-Z\_]{1}[a-zA-Z0-9\_]*(\s){0,1}\{')
_PYTHON_FUNCTION_REGEX = re.compile('')
_OBJECTIVE_C_CLASS_REGEX = re.compile('')

_JAVA_VARIABLE_REGEX = re.compile(ur'private [a-zA-Z\_]{1}[a-zA-Z0-9\_]* [a-zA-Z\_]{1}[a-zA-Z0-9\_]*.*;')

_LUA_COMMENTS_REGEX = re.compile(ur'(--\[\[(\s|\S)*?\]\](--)*)')
_LUA_FUNCTION_REGEX = re.compile(ur'(function\s+(.*))')
_LUA_LOCAL_VARIABLE_REGEX = re.compile(ur'(local\s(.)*)')