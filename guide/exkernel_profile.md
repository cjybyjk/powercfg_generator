## EX Kernel Manager 配置文件转换
仅支持从 EX Kernel Manager 的调度配置文件转换成生成器使用的格式

### 用法
1. 在主菜单中选择 *转换 EX Kernel Manager 配置文件*
2. 输入SoC型号，脚本将打开文本编辑器
3. 将配置文件的内容复制到文本编辑器中
   - 小技巧：在复制的内容之前可以添加模式头，例如[balance]
4. 保存内容，将生成可用的 `perf_text` 文件
