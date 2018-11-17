
### 生成 `powercfg`
1. 输入 SoC 型号
  - 如果SoC不在支持列表中，则需要输入附加信息
2. 使用 vim 输入参数
  - 建议使用 *规范化调度参数* 选项
3. 脚本会生成相应的 `powercfg`

#### 参数格式
注意：参数必须以**全角冒号 ：** 分隔

- 模式[可选]: 
  - 省电
  - 性能 
  - 均衡
  - 低延迟
- 调度参数[必需]
  - 格式:
     - ``` 
      timer_rate：big/little[可选]：value ```
     - ```
      timer_rate：
      big/little：value
       ```
- 示例
  - ```
性能
hispeed_freq：big：1401000
hispeed_freq：little：902000
target_loads：
big：40 1804000:59
little：40 1612000:64
均衡
hispeed_freq：633000
target_loads：55 1113000:39
```

