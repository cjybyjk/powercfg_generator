### 支持的SoC列表
#### 格式
codename:型号:big.LITTLE(y/n):cluster0[:cluster1]
- codename 用于识别对应的SoC，并且支持正则表达式
- 型号即一般所看到的 sd_820 sd_835
- big.LITTLE：标识这个SoC是否采用了big.LITTLE架构
  - 如果该SoC有多个簇，这个参数也要设为y
- cluster0：第0簇
- cluster1：可选，第1簇

