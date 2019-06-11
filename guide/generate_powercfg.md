## powercfg_generator 使用方法

### 生成 powercfg
- 生成的 `powercfg` 会输出到 `projects/项目id/platforms/SoC名称/` 中
1. 在**主菜单**输入 `g`
2. 输入SoC名称 (可以在SoC名称后添加 `:CPU最高频率` 以区分不同版本的SoC)
3. 程序将打开**在设置中指定的**文本编辑器，以供输入参数
4. 按照模板的说明输入参数
5. 保存perf_text
6. 程序将根据输入的内容生成 `powercfg`
