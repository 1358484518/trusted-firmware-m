# STM32H573 独立签名工具包

把未签名的 Secure / Non-Secure `.bin` 放进本目录，执行脚本并给出文件名即可。

## 用法

Linux / macOS：

```bash
cd sign_kit
./sign.sh tfm_ns.bin     # 非安全
./sign.sh sapp.bin       # 安全
```

Windows（命令提示符或 PowerShell）：

CubeIDE 的 post-build 会调用本目录 `sign.bat`。若日志出现 `1KIT:~0,-1"`、`'"=="nspe"` 或 `'et' 不是内部或外部命令`，是旧版脚本在 LF 换行下被 `\"` 拆行了；请更新本文件后再编。

```bat
cd sign_kit
sign.bat tfm_ns.bin
sign.bat sapp.bin
```

也可以把 `.bin` 拖到 `sign.bat` 上。

输出在本目录：`tfm_ns_signed.bin` / `sapp_signed.bin`。

文件名里带 `ns` 按非安全签；带 `sapp`、`tfm_s`、`_s.bin` 按安全签。看不出来时：

```bash
./sign.sh ns  app.bin
./sign.sh s   app.bin
```

```bat
sign.bat ns  app.bin
sign.bat s   app.bin
```

## 首次依赖

```bash
python3 -m pip install -r requirements.txt
```

Windows：

```bat
py -3 -m pip install -r requirements.txt
```

已有 `.venv` 时脚本会自动用它。

## 烧录地址（STM32H573I-DK）

| 镜像 | 地址 | 签完大小 |
|---|---|---|
| `*_s_signed.bin` | `0x0C038000` | 320 KB |
| `*_ns_signed.bin` | `0x0C088000` | 576 KB |

本目录的密钥是 TF-M 开发用 dummy RSA-3072，和当前 SPE/BL2 配套。量产请替换 `keys/` 并同步更新板上 ROTPK。
