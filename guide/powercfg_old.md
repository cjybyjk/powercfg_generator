## 已弃用。保留此文档仅用于兼容性

### 参数格式
注意：参数必须以**全角冒号 ：** 分隔

- 模式[可选]: 
  - 省电
  - 性能 
  - 均衡
  - 低延迟
- 调度参数[必需]
  - 格式:
``` 
timer_rate：big/little[可选]：value

timer_rate：
big/little：value
```
- 示例
```
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

