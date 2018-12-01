
## 生成 `powercfg`
1. 输入 SoC 型号
  - 如果SoC不在支持列表中，则需要输入附加信息
2. 使用 **在设置菜单指定的**文本编辑器 输入参数
3. 脚本会生成相应的 `powercfg` 脚本

### 参数格式

#### 模式(可选，默认为balance): 
- balance
- powersave 
- performance
- fast
- 附加模式
  - HMP：在第一次运行脚本时修改HMP参数
  - runonce：在第一次运行脚本时执行动作
  - before_modify：在应用调度前执行动作
  - after_modify：在应用调度后执行动作

#### 调度参数(必需)
##### 格式
```ini
timer_rate=big/little[可选]=value
timer_rate=
big/little=value
```

##### 示例
```ini
[performance]
hispeed_freq=big=1401000
hispeed_freq=little=902000
target_loads=
big=40 1804000:59
little=40 1612000:64
[balance]
hispeed_freq=633000
target_loads=55 1113000:39
[before_modify]
echo "ready to modify"
[after_modify]
echo "modified!"
[runonce]
echo "first run!"
[HMP]
sched_spill_load= 90
```

