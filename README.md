# 花来 - 三角洲行动游戏辅助

## 项目概述
基于 Ghidra 逆向 ESPOnlyPureTrollLive (樱-R44-内核HUD原语交接-Hikari20.ipa) 的二开项目

## 技术栈
- 语言: Swift / ObjC
- 渲染: Dear ImGui + Metal
- 内存读取: libkrw (kread32/kread64)
- 注入方式: dyld hook + LaunchDaemon

## 二进制分析结果

### 关键函数地址
| 函数 | 地址 | 功能 |
|------|------|------|
| DrawGame | 0x1001d807c | 主渲染入口 |
| onEspStats | 0x100035c60 | ESP 统计回调 |
| toggleDrawingWindow | 0x1000904b4 | 切换 HUD 窗口 |
| init_offsets | 0x10032d0f0 | 偏移初始化 |

### 配置键名 (来自二进制字符串)
- ESP: SkeletonEnabled, BoxEnabled, HealthEnabled, DistanceEnabled, NameEnabled
- 自瞄: AimEnabled, AimPart, AimFovRange, AimStrength
- 颜色: HumanBoxColor, AIBoxColor, HumanSkeletonColor
- 样式: SkeletonThickness, BoxThickness, PlayerTextScale

### IPC 通知
- com.cb.esponly.runtime.pid - 目标进程 PID
- com.cb.esponly.runtime.ready - 运行时就绪
- com.cz.esp.runtime.show/hide - ESP 显示/隐藏

## 构建
需要越狱 iOS 设备 (iOS 15.0+)，使用 Swift Package Manager 或 Xcode 构建

## 文件结构
\\\
Huailai/
  Source/
    Config.swift      # 核心配置和数据结构
    MemoryReader.swift # 内核内存读取 (libkrw)
    MetalRenderer.swift # Metal 渲染器
    ESPRenderer.swift  # ESP 渲染逻辑
    Aimbot.swift       # 自瞄模块
    IPCManager.swift   # IPC 通信
    Huailai.swift      # 主入口
    DYLDHook.swift     # dyld Hook
  Info.plist
  project.json
