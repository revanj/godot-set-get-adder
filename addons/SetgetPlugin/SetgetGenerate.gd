#========================================================================
#				SetgetGenerate
#========================================================================
# 【Get/Set 方法代码生成器】
#========================================================================
# @datetime: 2020-10-30 10:56 => 0.1
# @Godot version: 3.2.3
# @author: ApprenticeZhang
#========================================================================


extends Reference


##==============================
##		自定义方法
##==============================
func parse_code(
	source_code: String
) -> Array:
	"""
	解析代码
	@source_code: 要解析的源代码
	@return: 返回解析后的属性列表信息
	"""
	
	# 正则表达式
	# 【未导出变量】
	var regex = RegEx.new()
	regex.compile(
		"\nvar\\s+"						# var 开头为 \n，换行第一个
		+ "(?<name>\\w+)"				# 匹配【变量名】
		+ "(\\s*:\\s*(?<type>\\w+))?"	# 匹配【变量类型】
	)
	
	#【导出变量】
	var export_regex = RegEx.new()
	export_regex.compile(
		"\nexport"						# export 开头为 \n，换行第一个
		+ "(\\s*"						# 左括号内容
		+ "\\((?<type>\\w+)\\)"			# 匹配【括号中的变量类型】
		+ "\\s*|\\s+)"					# 右括号内容
		+ "var\\s*"						# var 
		+ "(?<name>\\w+)"				# 匹配【变量名】
		+ "(:\\s*(?<type>\\w+)?)?"		# 匹配【冒号和冒号后的变量类型】
		+ "(=((\\w+)|\\s*\\w+))?"		# 等号和后面的数据
	)
	
	# 进行匹配，返回匹配数据
	var tmp = regex.search_all(source_code)
	var tmp_2 = export_regex.search_all(source_code)
	for v in tmp_2:		# 两个数据合并
		tmp.append(v)
	
	# 记录结果
	var results = []
	for v in tmp:
		v = v as RegExMatch
		
#		# 保存变量数据
		var var_data = {
			'name': v.get_string('name'),
			'type': v.get_string('type')
		}
		
		results.push_back(var_data)
#		printt(v.get_string('name'), v.get_string('type'))
	
	return results


func generate_set_func(
	prop_list: Array,
	not_include_method_name: Array = [],
	add_type_hint: bool = true
) -> String:
	"""
	生成 set 方法代码
	@prop_list: 由 parse_code() 方法解析出来的变量数据列表
	@not_include_method_name: 不添加的方法名列表
	@add_type_hint: 添加类型提示
	@return: 返回生成的代码
	"""
	var t: String = ""
	for p in prop_list:
		
		# 变量名
		var var_name: String
		var_name = p['name']
		
		# 方法名
		var method_name: String
		method_name = trim_left(var_name, '_')		# 删除开头下划线
		method_name = 'set_' + method_name
		
		# 跳过不添加的方法名
		if not_include_method_name.has(method_name):
			continue
		
		# 变量类型
		var type: String
		if (add_type_hint 			# 添加类型提示
			&& p['type'] != ''
		):
			type = 'value: ' + p['type']
		else:						# 不添加类型提示
			type = 'value'
		
		# 返回类型
		var return_type: String = ""
		if add_type_hint:
			return_type = ' -> void'
		
		# 格式化代码块
		t += """\nfunc {method_name}({type}){return_type}:
\t{var_name} = value\n""".format({
			'method_name': method_name,
			'var_name': var_name,
			'type': type,
			'return_type': return_type
		})
	return t


func generate_get_func(
	prop_list: Array,
	not_include_method_name: Array = [],
	add_type_hint: bool = true
) -> String:
	"""
	生成 get 方法代码
	@prop_list: 由 parse_code() 方法解析出来的变量数据列表
	@not_include_method_name: 不添加的方法名列表
	@add_type_hint: 添加类型提示
	@return: 返回生成的代码
	"""
	var t: String = ""
	for p in prop_list:
		# 变量名
		var var_name: String
		var_name = p['name']
		
		# 方法名
		var method_name: String
		method_name = trim_left(var_name, '_')	# 删除开头下划线
		if p['type'] == 'bool':
			method_name = 'is_' + method_name	# bool 类型 is 开头
		else:
			method_name = 'get_' + method_name	# 其他类型 get 开头
		
		# 跳过不添加的方法名
		if not_include_method_name.has(method_name):
			continue
		
		# 返回变量类型
		var return_type: String = ''
		if (add_type_hint			# 添加类型提示
			&& p['type'] != ''
		):
			return_type = ' -> ' + p['type']
		else:						# 不添加类型提示
			return_type = ''
		
		# 格式化代码块
		t += """\nfunc {method_name}(){return_type}:
\treturn {var_name}\n""".format({
			'method_name': method_name,
			'var_name': var_name,
			'return_type': return_type,
		})
	
	return t


func get_method_names(source_code: String) -> Array:
	"""返回代码所有方法名"""
	# 正则表达式
	var regex = RegEx.new()
	regex.compile(
		"\nfunc\\s+"			# func 开头
		+ "(?<name>\\w+)"		# 方法名
	)
	
	# 找到所有方法名
	var method_names: Array = []
	for m in regex.search_all(source_code):
		m = m as RegExMatch
		method_names.append(m.get_string('name'))
	
	return method_names


func get_exists_prop_method_name(source_code: String) -> Array:
	"""
	返回所有已添加的 setget 方法的属性名
	@source_code: 用于解析的源代码
	@return: 返回方法中的属性名字的列表
	"""
	# 获取所有方法中的属性名
	var prop_name_list := []
	var method_names = get_method_names(source_code)
	var regex = RegEx.new()
	regex.compile(
		"(set|get|is)_"			# set/get/is 开头
		+ "(?<name>\\w+)"			# 方法名
	)
	for m_name in method_names:
		var result = regex.search(m_name) as RegExMatch
		if result == null:
			continue
		
		var n = result.get_string('name')
		if not prop_name_list.has(n):
			prop_name_list.append(n)
#	print('--> get_exists_prop_method_name() ', prop_name_list)
	return prop_name_list


func trim_left(text: String, trim_str: String) -> String:
	"""修剪左边的字符，直到没有为止"""
	while (text.left(1) == trim_str):
		text = text.trim_prefix(trim_str)
	return text

