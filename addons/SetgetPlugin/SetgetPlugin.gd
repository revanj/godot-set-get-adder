#========================================================================
#				SetgetPlugin
#========================================================================
# 【Get/Set 方法代码生成器插件】
# 对正在操作的脚本进行添加 setget 方法的代码
# * 点击菜单中的“项目-工具-生成 Set/Get 方法“ 菜单打开 SetgetDialog 停靠栏
#   停靠栏出现在右下角，点击 OK 添加到当前正在编辑的脚本里，需要保存一下才能出现。
# * 注意：还未解决加载问题，需要按下 Ctrl + S 或 Ctrl + Alt + S 进行保存才能出现生成的代码
#========================================================================
# @datetime: 2020-10-30 10:56 => 0.1
# @Godot version: 3.2.3
# @author: ApprenticeZhang
#========================================================================

tool
extends EditorPlugin


const DOCK = preload("res://addons/SetgetPlugin/SetgetDialog.tscn")
const PARSER = preload("res://addons/SetgetPlugin/SetgetGenerate.gd")


var dock: Control
var menu_name: String = '生成 Set/Get 方法'
var __checkbox_group: Array
var __added_close: bool = true		# 点击完添加，则关闭面板
var __add_set_func: bool = true		# 是否添加 set 方法
var __add_get_func: bool = true		# 是否添加 get 方法
var __add_type_hint: bool = true	# 添加类型


##==============================
##		内置方法
##==============================
func _enter_tree() -> void:
#	add_tool_menu_item(menu_name, self, "parse", ['hello'])	# 带有参数的
	add_tool_menu_item(menu_name, self, "show_setget_dock")


func _exit_tree() -> void:
	remove_tool_menu_item(menu_name)
	remove_dock()



##==============================
##		自定义方法
##==============================
func show_setget_dock(args) -> void:
	"""显示 setget 停靠栏"""
	
	# 清空上次的节点
	remove_dock()
	
	# 注意：添加的场景如果有脚本的话，脚本不会生效，强行代码添加的脚本也不会起作用
	# 必须要自己代码连接节点信号
	dock = DOCK.instance()
	
	# 添加 CheckBox 按钮
	var checkbox_container = dock.get_node('VBox/Scroll/VBox/Panel/CheckGroup')
	var cur_script = get_current_script() as Script
	var source_code = cur_script.source_code		# 脚本源代码
	__checkbox_group = add_checkbox(checkbox_container, source_code)	# 添加复选框按钮
	
	#>>>> 设置节点参数与信号
	# 标签
	var script_path = dock.get_node("VBox/HBox/ScriptPath") as LineEdit
	script_path.text = get_editor_interface().get_script_editor().get_current_script().resource_path
	script_path.hint_tooltip = '当前脚本路径：' + script_path.text
	
	# 按钮组
	var button_group = dock.get_node('VBox/Scroll/VBox/Right')
	
	var add = button_group.get_node('Add') as Button	# Add 按钮
	add.connect("pressed", self, 'add_setget_func', [__checkbox_group])
	
	var close = button_group.get_node('Close') as Button	# Close 按钮
	close.connect('pressed', self, 'remove_dock')
	
	var select_all = button_group.get_node('SelectAll') as Button
	select_all.connect('pressed', self, 'select_all', [__checkbox_group])
	
	var cancel_all = button_group.get_node('CancelAll') as Button
	cancel_all.connect('pressed', self, 'cancel_all', [__checkbox_group])
	
	var update_list = button_group.get_node('UpdateList') as Button
	update_list.connect('pressed', self, 'update_list')
	
	# CheckButton 按钮组
	var checkbutton_group = button_group.get_node('Center/CheckButton')
	
	var set_func = checkbutton_group.get_node("SetFunc") as CheckButton
	set_func.set_pressed(__add_set_func)
	set_func.connect('pressed', self, 'press_set_func', [set_func])
	
	var get_func = checkbutton_group.get_node("GetFunc") as CheckButton
	get_func.set_pressed(__add_get_func)
	get_func.connect('pressed', self, 'press_get_func', [get_func])
	
	var added_close = checkbutton_group.get_node("AddedClose") as CheckButton
	added_close.set_pressed(__added_close)
	added_close.connect('pressed', self, 'press_added_close', [added_close])
	
	var add_type = checkbutton_group.get_node("AddType") as CheckButton
	add_type.set_pressed(__add_type_hint)
	add_type.connect('pressed', self, 'press_add_type', [add_type])
	
	# 添加 Dock
	add_control_to_dock(DOCK_SLOT_RIGHT_BL, dock)


func add_checkbox(
	checkbox_container: Control, 
	source_code: String
) -> Array:
	"""
	添加 CheckBox 按钮
	@checkbox_container: 添加 CheckBox 的容器
	@source_code: 源代码
	"""
	# 解析代码
	var parser = PARSER.new()	# 代码解析器
	var prop_data = parser.parse_code(source_code)		# 解析获取所有属性信息
	var method_names = parser.get_method_names(source_code)	# 解析获取所有方法名
	var added_prop = parser.get_exists_prop_method_name(source_code)	# 获取已添加的属性
	
	# 添加 CheckBox 节点
	var checkbox_arr: Array
	var prop_name: String
	var ck: CheckBox
	for i in range(prop_data.size()):
		prop_name = prop_data[i]['name']
		ck = CheckBox.new()
		
		# 没有添加过，则进行添加
		if not added_prop.has(parser.trim_left(prop_name, '_')):
			ck.pressed = true
		
		ck.text = prop_name
		checkbox_container.add_child(ck)
		checkbox_arr.append(ck)
		ck.set_meta('prop_data', prop_data[i])	# 添加属性数据
	return checkbox_arr

func get_current_script() -> GDScript:
	"""返回当前正在编辑的脚本"""
	return get_editor_interface().get_script_editor().get_current_script() as GDScript


func update_script_code(
	script_name: String,
	script_path: String,
	source_code: String,
	prop_data_list: Array
) -> void:
	"""
	更新脚本代码
	@script_name: 脚本名称
	@script_path: 脚本路径
	@source_code: 代码
	@prop_data_list: 更新脚本源代码
	"""
	# >>> 解析代码
	# 新建解析器
	var parser = PARSER.new()
	
	# 生成 Set/Get 方法代码
	var exists_method_prop_names = parser.get_exists_prop_method_name(source_code)	# 获取已添加方法的属性，用于止添加重复方法
	var set_func_code: String = parser.generate_set_func(prop_data_list, exists_method_prop_names, __add_type_hint)		# 生成 set 方法代码
	var get_func_code: String = parser.generate_get_func(prop_data_list, exists_method_prop_names, __add_type_hint)		# 生成 get 方法代码
	
	# 添加 Set/Get 方法代码
	var new_code: String = source_code
	if __add_set_func:		# set
		new_code += set_func_code
	if __add_get_func:		# get
		new_code += get_func_code
	
	# 保存脚本
	var file: File = File.new()
	file.open(script_path, File.WRITE)
	file.store_string(new_code)
	file.close()

	# >>> 重新加载 Script
	# < 这样做会出现旧的无名的脚本，暂时没发现其他切换脚本的办法，所以暂时用这个办法 >
	# 将旧脚本路径设为空白
	var old_script = get_current_script() as GDScript
	old_script.take_over_path('')

	# 将新脚本路径设为改变的路径
	var new_script = load(script_path) as GDScript
	new_script.take_over_path(script_path)
	get_editor_interface().edit_resource(new_script)
	
	# 代码光标定位到最后一行
	var row_num = new_code.count('\n', 0, new_code.length())
	get_editor_interface().get_script_editor().goto_line(row_num)



##==============================
##		连接信号方法
##==============================
func add_setget_func(checkbox_group: Array) -> void:
	"""
	添加 setget 方法
	< 将 Set/Get 方法写入到文件中 >
	@checkbox_group: checkbox 组，判断要添加哪些数据
	"""
	# 获取勾选的属性数据
	var prop_data_list: Array
	for checkbox in checkbox_group:
		checkbox = checkbox as CheckBox
		if checkbox.is_pressed():
			var prop_data = checkbox.get_meta('prop_data')
			prop_data_list.append(prop_data)
	
	# 获取当前编辑的脚本的信息
	var cur_script = get_current_script()
	
	if prop_data_list.size() > 0:
		# 更新脚本代码
		update_script_code(
			cur_script.resource_name, 
			cur_script.resource_path,
			cur_script.source_code, 
			prop_data_list
		)
		
		# 如果添加完之后关闭停靠栏
		if __added_close:
			# 添加完移除停靠栏
			remove_dock()
		else:
			yield(get_tree().create_timer(0.05), "timeout")
			# 更新停靠栏
			update_list()
	else:
		print('没有勾选复选框+')


func remove_dock() -> void:
	"""移除停靠栏"""
	__checkbox_group.clear()
	
	if dock:
		remove_control_from_docks(dock)
		dock.queue_free()
		dock = null

func select_all(checkbox_group: Array) -> void:
	"""选择所有选框"""
	for checkbox in checkbox_group:
		checkbox.set_pressed(true)

func cancel_all(checkbox_group: Array) -> void:
	"""取消选定所有选框"""
	for checkbox in checkbox_group:
		checkbox.set_pressed(false)

func update_list() -> void:
	"""更新列表数据"""
	show_setget_dock(null)


#>>> CheckButton 按钮
func press_added_close(checkbutton: CheckButton) -> void:
	"""添加完是否关闭停靠栏"""
	__added_close = checkbutton.is_pressed()

func press_set_func(checkbutton: CheckButton) -> void:
	__add_set_func = checkbutton.is_pressed()

func press_get_func(checkbutton: CheckButton) -> void:
	__add_get_func = checkbutton.is_pressed()

func press_add_type(checkbutton: CheckButton) -> void:
	__add_type_hint = checkbutton.is_pressed()
