# libxr stm32 test

仅仅用于stm32编译测试，不保证能够在stm32上正常运行

Just for build test on stm32, not guaranteed to run on stm32

## Windows

基于STM32Cube for VS Code插件下载的包，配置PATH

Based on the package downloaded by the STM32Cube for VS Code plugin, configure the PATH

```powershell
C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\gnu-tools-for-stm32\13.3.1+st.9\bin;C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\gnu-gdb-for-stm32\13.3.1+st.10\bin;C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\st-arm-clang\19.1.6+st.8\bin;C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\st-arm-clangd\19.1.2+st.3\bin;C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\stlink-gdbserver\7.10.0+st.3\bin;C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\stlink-server\2.1.1+st.7\bin;C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\cmake\4.0.1+st.3\bin;C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\ninja\1.12.1+st.9\bin
```

设置环境变量

Set environment variables

```powershell
$env:GCC_TOOLCHAIN_ROOT = "C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\gnu-tools-for-stm32\13.3.1+st.9\bin"
$env:CLANG_GCC_CMSIS_COMPILER = "C:\Users\$env:USERNAME\AppData\Local\stm32cube\bundles\st-arm-clang\19.1.6+st.8"
```

运行test.ps1。

Run test.ps1

```powershell
pip install libxr
.\test.ps1
```

## Linux

基于docker镜像xrimage/xrimage-stm32

```bash
pip install libxr
./test.sh
```
