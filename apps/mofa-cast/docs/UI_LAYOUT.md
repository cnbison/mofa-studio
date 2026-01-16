# MoFA Cast UI Layout Structure

**Date**: 2026-01-15
**Version**: v0.6.0
**Author**: Claude Code

本文档详细描述了 MoFA Cast 应用的完整 UI 布局结构，包括所有组件的层次关系、尺寸配置和布局方向。

---

## 目录

- [布局常量](#布局常量)
- [完整布局层次结构](#完整布局层次结构)
- [关键尺寸总结](#关键尺寸总结)
- [布局计算](#布局计算)
- [设计说明](#设计说明)

---

## 布局常量

```rust
SECTION_SPACING = 12.0   // 主要区块之间的间距
PANEL_RADIUS = 4.0       // 面板圆角半径
PANEL_PADDING = 12.0     // 面板内边距
```

---

## 完整布局层次结构

### 📱 CastScreen (根容器)

```
CastScreen
├── 尺寸: width: Fill, height: Fill
├── 布局: flow: Down (垂直布局)
├── 间距: spacing: 12
├── 内边距: padding: {left: 16, right: 16, top: 12, bottom: 12}
└── 对齐: align: {y: 0.0}
```

---

### 🎨 1️⃣ header (标题栏)

```
header
├── 尺寸: width: Fill, height: Fit
├── 布局: flow: Right (水平布局)
├── 间距: spacing: 12
└── 对齐: align: {y: 0.5}
    ├── 📌 icon_label (图标)
    │   └── 文本: "🎙️" (font_size: 28.0, FONT_BOLD)
    ├── 📌 title_label (标题)
    │   └── 文本: "MoFA Cast" (font_size: 24.0, FONT_BOLD)
    ├── ↔️ Filler (弹性填充)
    └── 📌 description (描述)
        └── 文本: "Transform chat transcripts into podcast audio" (font_size: 13.0, FONT_REGULAR)
```

---

### 📦 2️⃣ main_content (主内容区)

```
main_content
├── 尺寸: width: Fill, height: Fill
├── 布局: flow: Right (水平布局)
└── 间距: spacing: 12
```

#### 2.1 📋 left_panel (左侧面板 - 导入与控制)

```
left_panel
├── 尺寸: width: 200, height: Fill
├── 布局: flow: Down (垂直布局)
└── 间距: spacing: 12
```

##### 2.1.1 📥 import_section (导入区)

```
import_section
├── 尺寸: width: Fill, height: Fit
├── 内边距: padding: 12
├── 布局: flow: Down
└── 组件:
    ├── 📌 PanelHeader
    │   └── 文本: "Import Transcript" (font_size: 14.0, FONT_SEMIBOLD)
    ├── 📋 format_dropdown (格式选择)
    │   ├── 尺寸: width: Fill
    │   ├── 选项: ["Auto Detect", "Plain Text", "JSON", "Markdown"]
    │   ├── 字体: font_size: 12.0 (FONT_MEDIUM)
    │   └── 样式: 浅蓝色背景 (#dbeafe) + 深灰边框 (vec4(0.4, 0.4, 0.4, 1.0))
    ├── 🔘 import_button (导入按钮)
    │   ├── 尺寸: width: Fill
    │   └── 文本: "Select File"
    └── 📌 file_info (文件信息)
        └── 文本: "No file selected" (font_size: 11.0, FONT_REGULAR)
```

##### 2.1.2 📁 recent_files_section (最近文件)

```
recent_files_section
├── 尺寸: width: Fill, height: Fit
├── 内边距: padding: 12
├── 布局: flow: Down
└── 组件:
    ├── 📌 PanelHeader
    │   └── 文本: "Recent Files" (font_size: 14.0, FONT_SEMIBOLD)
    └── 📋 recent_files_list (文件列表)
        ├── 尺寸: width: Fill, height: Fit
        ├── 间距: spacing: 4
        └── 占位文本: "No recent files" (font_size: 11.0, FONT_REGULAR)
```

##### 2.1.3 🎤 speakers_section (说话人列表)

```
speakers_section
├── 尺寸: width: Fill, height: Fill  // 填充剩余高度
├── 内边距: padding: 12
├── 布局: flow: Down
└── 组件:
    ├── 📌 PanelHeader
    │   └── 文本: "Speakers" (font_size: 14.0, FONT_SEMIBOLD)
    └── 📋 speakers_list (列表)
        ├── 尺寸: width: Fill, height: Fit
        ├── 间距: spacing: 8
        └── 占位文本: "Import a transcript to see speakers" (font_size: 12.0, FONT_REGULAR)
```

#### 2.2 📝 right_panel (右侧面板 - 编辑器)

```
right_panel
├── 尺寸: width: Fill, height: Fill
├── 布局: flow: Down (垂直布局)
└── 间距: spacing: 12
```

##### 2.2.1 🎛️ control_bar (控制栏)

```
control_bar
├── 尺寸: width: Fill, height: Fit
├── 内边距: {top: 8, bottom: 8, left: 16, right: 16}
├── 布局: flow: Right (水平布局)
├── 间距: spacing: 8
└── 对齐: align: {y: 0.5, x: 0.0}
    ├── 📝 open_editor_button (外部编辑器按钮)
    │   ├── 尺寸: width: Fit, height: 28
    │   ├── 文本: "📝 Open in Editor"
    │   └── 样式: 蓝色渐变 (#6366f1 → #818cf8)
    ├── 🎙️ synthesize_button (合成按钮)
    │   ├── 尺寸: width: Fit, height: 28
    │   ├── 文本: "🎙️ Synthesize Audio"
    │   └── 样式: 绿色渐变 (#10b981 → #34d399)
    ├── 💾 export_button (导出按钮)
    │   ├── 尺寸: width: Fit, height: 28
    │   ├── 文本: "💾 Export WAV"
    │   └── 样式: 紫色渐变 (#8b5cf6 → #a78bfa)
    ├── ↔️ Filler (弹性填充)
    └── 📊 progress_label (进度标签)
        └── 文本: "" (动态显示进度, font_size: 12.0, FONT_REGULAR)
```

##### 2.2.2 📄 editor_container (编辑器容器)

```
editor_container
├── 尺寸: width: 500, height: Fill
└── 布局: flow: Down
    └── 📄 script_panel (脚本面板)
        ├── 尺寸: width: Fill, height: Fill
        ├── 内边距: padding: 0
        ├── 布局: flow: Down
        └── 组件:
            ├── 📌 PanelHeader
            │   ├── 标题: "Podcast Script" (font_size: 14.0, FONT_SEMIBOLD)
            │   └── 副标题: "Import your optimized script (ChatGPT/Claude)" (font_size: 11.0, FONT_REGULAR)
            └── 📝 script_editor (文本编辑器)
                ├── 尺寸: width: 500, height: 300  // 固定尺寸
                ├── 内边距: {left: 12, right: 12, top: 10, bottom: 10}
                ├── 字体: font_size: 12.0 (FONT_REGULAR)
                ├── 自动换行: word: Wrap
                ├── 选区颜色: (INDIGO_200)
                └── 默认文本: "Click 'Import Script' to load your optimized podcast script..."
```

##### 2.2.3 📋 templates_section (模板区域)

```
templates_section
├── 尺寸: width: 200, height: Fit
├── 内边距: padding: 12
├── 布局: flow: Down
└── 组件:
    ├── 📌 PanelHeader
    │   └── 文本: "Templates" (font_size: 14.0, FONT_SEMIBOLD)
    ├── 📋 template_dropdown (模板下拉框)
    │   ├── 尺寸: width: Fill
    │   ├── 选项: ["2-Person Interview", "3-Person Discussion", "Narrative"]
    │   ├── 字体: font_size: 12.0 (FONT_MEDIUM)
    │   └── 样式: 浅蓝色背景 (#dbeafe) + 深灰边框
    └── 🎯 use_template_button (使用模板按钮)
        ├── 尺寸: width: Fill
        ├── 文本: "Use Template"
        └── 样式: 紫色 (#8b5cf6)
```

#### 2.3 📊 log_section (日志面板)

```
log_section
├── 尺寸: width: 320, height: Fill
├── 布局: flow: Right (水平布局)
├── 对齐: align: {y: 0.0}
└── 组件:
    ├── 🎛️ toggle_column (切换按钮列)
    │   ├── 尺寸: width: Fit, height: Fill
    │   ├── 内边距: {left: 4, right: 4, top: 8}
    │   └── 🔘 toggle_log_btn (切换按钮)
    │       ├── 尺寸: width: Fit, height: Fit
    │       ├── 内边距: {left: 8, right: 8, top: 6, bottom: 6}
    │       ├── 文本: "<" / ">" (可切换)
    │       └── 字体: font_size: 11.0 (FONT_BOLD)
    │
    └── 📋 log_content_column (日志内容)
        ├── 尺寸: width: Fill, height: Fill
        ├── 布局: flow: Down
        └── 组件:
            ├── 📌 log_header (日志头)
            │   ├── 尺寸: width: Fill, height: Fit
            │   ├── 布局: flow: Down
            │   └── 组件:
            │       ├── 📌 log_title_row (标题行)
            │       │   ├── 尺寸: width: Fill, height: Fit
            │       │   ├── 内边距: {left: 12, right: 12, top: 10, bottom: 6}
            │       │   └── 文本: "System Log" (font_size: 13.0, FONT_SEMIBOLD)
            │       │
            │       └── 🎛️ log_filter_row (过滤行)
            │           ├── 尺寸: width: Fill, height: 32
            │           ├── 内边距: {left: 8, right: 8, bottom: 6}
            │           ├── 布局: flow: Right
            │           ├── 间距: spacing: 6
            │           ├── 对齐: align: {y: 0.5}
            │           ├── 📋 level_filter (级别过滤)
            │           │   ├── 尺寸: width: 70, height: 24
            │           │   ├── 选项: ["ALL", "INFO", "WARN", "ERROR"]
            │           │   └── 字体: font_size: 10.0 (FONT_MEDIUM)
            │           └── 🔘 clear_log_btn (清除按钮)
            │               ├── 尺寸: width: 60, height: 24
            │               └── 文本: "Clear"
            │
            └── 📝 log_viewport (日志视口)
                └── 尺寸: width: Fill, height: Fill
```

---

## 关键尺寸总结

### 主要面板宽度

| 组件名称 | 宽度 | 高度 | 布局方向 | 说明 |
|---------|------|------|---------|------|
| **CastScreen** | Fill | Fill | Down | 根容器，padding: 16/12/12/12 |
| **header** | Fill | Fit | Right | 标题栏 |
| **main_content** | Fill | Fill | Right | 主内容区，spacing: 12 |
| **left_panel** | **200** | Fill | Down | 左侧面板，spacing: 12 |
| **import_section** | Fill | Fit | Down | 导入区 |
| **recent_files_section** | Fill | Fit | Down | 最近文件区 |
| **speakers_section** | Fill | Fill | Down | 说话人列表（填充剩余高度） |
| **right_panel** | **Fill** | Fill | Down | 右侧面板，spacing: 12 |
| **control_bar** | Fill | Fit | Right | 控制栏 |
| **editor_container** | **500** | Fill | Down | 编辑器容器 |
| **script_editor** | **500** | **300** | - | 文本编辑器（固定尺寸） |
| **templates_section** | **200** | Fit | Down | 模板区域 |
| **log_section** | **320** | Fill | Right | 日志面板 |
| **toggle_column** | Fit | Fill | Down | 切换按钮列 |
| **log_content_column** | Fill | Fill | Down | 日志内容 |

### 字体大小

| 用途 | 字体大小 | 字体样式 |
|------|---------|---------|
| 图标 (🎙️) | 28.0 | FONT_BOLD |
| 标题 (MoFA Cast) | 24.0 | FONT_BOLD |
| 描述文本 | 13.0 | FONT_REGULAR |
| Panel 标题 | 14.0 | FONT_SEMIBOLD |
| 下拉框 | 12.0 | FONT_MEDIUM |
| 文本编辑器 | 12.0 | FONT_REGULAR |
| 按钮文本 | 13.0 | FONT_MEDIUM |
| 文件信息 | 11.0 | FONT_REGULAR |
| 占位文本 | 11.0-12.0 | FONT_REGULAR |
| 日志标题 | 13.0 | FONT_SEMIBOLD |
| 日志过滤 | 10.0 | FONT_MEDIUM |
| 切换按钮 | 11.0 | FONT_BOLD |
| 进度标签 | 12.0 | FONT_REGULAR |

### 颜色方案

| 组件 | 背景色 | 边框/强调色 | 说明 |
|------|--------|-----------|------|
| 下拉框 | #dbeafe (浅蓝) | vec4(0.4, 0.4, 0.4, 1.0) (深灰) | 格式和模板选择 |
| 外部编辑器按钮 | #6366f1 → #818cf8 | - | 蓝色渐变 |
| 合成按钮 | #10b981 → #34d399 | - | 绿色渐变 |
| 导出按钮 | #8b5cf6 → #a78bfa | - | 紫色渐变 |
| 使用模板按钮 | #8b5cf6 | - | 紫色 |
| 选区颜色 | - | INDIGO_200 | 文本编辑器 |

---

## 布局计算

### 水平布局计算（main_content）

```
main_content 采用 flow: Right 布局

总宽度 = left_panel + spacing + right_panel + spacing + log_section
      = 200px + 12px + Fill + 12px + 320px
      = 544px + right_panel

其中 right_panel 实际宽度 = 窗口宽度 - 544px（动态填充剩余空间）
```

**示例计算**（假设窗口宽度 1400px）:
```
right_panel 实际宽度 = 1400 - 544 = 856px
```

### 垂直布局计算（right_panel）

```
right_panel 采用 flow: Down 布局

组件垂直排列：
1. control_bar (height: Fit, 约 44px)
2. spacing: 12px
3. editor_container (height: Fill)
4. spacing: 12px
5. templates_section (height: Fit, 约 120px)

editor_container 内部：
- script_panel (height: Fill)
  - script_editor: 500×300 (固定尺寸，但会被 Fill 撑开)
```

### 垂直布局计算（left_panel）

```
left_panel 采用 flow: Down 布局

组件垂直排列：
1. import_section (height: Fit, 约 160px)
2. spacing: 12px
3. recent_files_section (height: Fit, 动态)
4. spacing: 12px
5. speakers_section (height: Fill, 填充剩余高度)
```

---

## 设计说明

### 布局原则

1. **三栏布局**: 左侧控制面板 (200px) + 中间编辑区 (动态) + 右侧日志面板 (320px)
2. **固定宽度组件**: left_panel (200px)、editor_container (500px)、templates_section (200px)、log_section (320px)
3. **弹性填充**: right_panel 使用 Fill 宽度自动适应窗口大小
4. **间距统一**: 主要区间距使用 SECTION_SPACING (12px)

### 设计模式

1. **面板容器**: 所有主要区域使用 `RoundedView` 提供统一的圆角和背景
2. **PanelHeader**: 使用可复用的 `PanelHeader` 组件保持标题样式一致
3. **响应式高度**: 大部分面板使用 `height: Fit`，speakers_section 使用 `height: Fill` 占据剩余空间
4. **水平控制栏**: control_bar 使用 `Filler` 确保进度标签始终靠右显示

### 扩展性考虑

- right_panel 内部的 editor_container (500px) 和 templates_section (200px) 固定宽度后
- 剩余空间 (right_panel - 700px) 可用于未来功能扩展，如：
  - 波形显示组件
  - 音频控制面板
  - 导出选项（MP3 质量选择等）

### 颜色编码

- **蓝色**: 外部编辑器按钮 (#6366f1) - 辅助功能
- **绿色**: 合成按钮 (#10b981) - 主要操作
- **紫色**: 导出按钮 (#8b5cf6) 和使用模板按钮 - 次要操作
- **浅蓝**: 下拉框背景 (#dbeafe) - 选择输入

---

## 相关文件

- **UI 定义**: `apps/mofa-cast/src/screen.rs` (line 38-)
- **布局常量**: `apps/mofa-cast/src/screen.rs` (line 18-20)
- **颜色主题**: `mofa-widgets/src/theme.rs`

---

**最后更新**: 2026-01-15
**维护者**: Claude Code
