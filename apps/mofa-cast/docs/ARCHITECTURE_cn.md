# MoFA Cast - 架构指南

**版本**: 0.1.0 (规划中)
**状态**: 📋 设计阶段
**框架**: Makepad GPU 加速 UI + Dora 数据流
**模式**: 内容转换应用 (聊天 → 播客)

---

## 项目概述

**MoFA Cast** 使用 AI 编辑将聊天记录转换为精美的播客脚本。作为 MoFA Studio 的插件构建，展示了文档处理和批量 TTS 合成功能。

### 核心功能

- ⏳ 导入聊天记录 (纯文本、JSON、Markdown)
- ⏳ AI 脚本优化 (GPT-4、Claude、本地 LLM)
- ⏳ 多说话人脚本生成
- ⏳ 批量 TTS 合成 (多种声音)
- ⏳ 音频混合和导出 (MP3/WAV)
- ⏳ 带预览的脚本编辑器
- ⏳ 导出为常见播客格式

---

## 目录结构

```
apps/mofa-cast/
├── Cargo.toml                   # 依赖项
├── ARCHITECTURE.md              # 本文件
├── APP_DEVELOPMENT_GUIDE.md     # 开发教程
├── CHECKLIST.md                 # 实现检查清单
├── roadmap-claude.md            # 开发路线图
└── src/
    ├── lib.rs                   # MofaApp trait 实现
    ├── screen.rs                # 主 UI 界面
    ├── transcript_parser.rs     # 解析各种聊天格式
    ├── script_refiner.rs        # AI 脚本生成
    ├── tts_batch.rs             # 批量 TTS 合成
    └── audio_mixer.rs           # 合并音频片段
```

---

## 技术架构

### 1. 输入处理管道

```
聊天记录
    ↓ [解析格式]
结构化对话
    ├─ 说话人 1: [消息]
    ├─ 说话人 2: [消息]
    └─ 元数据 (时间、主题)
    ↓ [AI 优化]
播客脚本
    ├─ 开场白
    ├─ 主要内容 (已优化)
    ├─ 过渡语句
    └─ 结语
```

**支持的格式**:
- 纯文本 (说话人: 消息)
- JSON (OpenAI 聊天格式)
- Markdown (GitHub 讨论)
- WhatsApp 导出
- 微信导出

### 2. AI 脚本优化

```yaml
优化步骤:
  1. 提取关键点
  2. 添加结构 (开头/正文/结尾)
  3. 平滑过渡
  4. 添加主持人评论
  5. 为 TTS 格式化 (标点、停顿)
```

**LLM 提示词示例**:
```
将此聊天记录转换为播客脚本:
- 添加引人入胜的开场白
- 重新表述生硬的短语
- 添加主持人过渡语
- 保持对话语气
- 格式: [说话人] 对话
```

### 3. TTS 合成管道

```
脚本片段
    ↓ [按说话人分割]
说话人 1 → TTS 引擎 A (声音: 男声)
说话人 2 → TTS 引擎 B (声音: 女声)
    ↓ [并行处理]
音频片段
    ├─ segment_01_speaker1.wav
    ├─ segment_02_speaker2.wav
    └─ segment_03_speaker1.wav
    ↓ [连接 + 标准化]
最终播客音频
```

### 4. UI 组件

```
CastScreen
├── InputPanel
│   ├── FileSelector (导入记录)
│   ├── FormatDropdown (自动检测或手动)
│   └── ImportButton
├── EditorPanel
│   ├── OriginalView (只读记录)
│   ├── SplitterBar
│   └── ScriptEditor (已优化、可编辑)
├── SpeakerPanel
│   ├── Speaker 1 (名称、声音、颜色)
│   └── Speaker 2 (名称、声音、颜色)
├── ControlPanel
│   ├── RefineButton (AI)
│   ├── SynthesizeButton (TTS)
│   └── ExportButton (音频)
└── ProgressPanel
    ├── StatusText
    └── ProgressBar
```

---

## 数据模型

### 聊天记录

```rust
pub struct Transcript {
    pub messages: Vec<Message>,
    pub metadata: Metadata,
}

pub struct Message {
    pub speaker: String,
    pub text: String,
    pub timestamp: Option<DateTime<Utc>>,
}

pub struct Metadata {
    pub title: Option<String>,
    pub date: Option<DateTime<Utc>>,
    pub participants: Vec<String>,
}
```

### 播客脚本

```rust
pub struct PodcastScript {
    pub segments: Vec<Segment>,
    pub speakers: Vec<Speaker>,
    pub total_duration: Option<Duration>,
}

pub struct Segment {
    pub speaker_id: usize,
    pub text: String,
    pub audio_path: Option<PathBuf>,  // TTS 后
}

pub struct Speaker {
    pub name: String,
    pub voice_id: String,  // TTS 声音模型
    pub color: Color,      // UI 颜色编码
}
```

---

## Dora 集成

### 批量 TTS 数据流

```yaml
nodes:
  - id: text-segmenter
    operator: python
    inputs: { script: stdin }
    outputs: [segments]

  - id: tts-speaker1
    operator: python (dora-primespeech)
    inputs: { text: text-segmenter/segments }
    outputs: [audio]
    env:
      VOICE_NAME: "Male_01"

  - id: tts-speaker2
    operator: python (dora-primespeech)
    inputs: { text: text-segmenter/segments }
    outputs: [audio]
    env:
      VOICE_NAME: "Female_01"

  - id: audio-mixer
    operator: python
    inputs:
      audio1: tts-speaker1/audio
      audio2: tts-speaker2/audio
    outputs: [final_audio]
```

---

## 性能考虑

- **记录解析**: 10K 条消息 <100ms
- **AI 优化**: 5-30s (取决于 LLM，使用流式传输改善体验)
- **TTS 合成**: ~1s/100 字符 (2+ 个说话人并行处理)
- **音频混合**: 30分钟播客 <5s
- **总管道**: 典型聊天约 1-3min (500 条消息 → 30分钟播客)

---

## 成功标准

- [x] 架构已记录
- [ ] 记录解析器 (至少 3 种格式)
- [ ] AI 优化正常工作
- [ ] 批量 TTS 合成
- [ ] 音频导出 (MP3)
- [ ] 端到端测试: 100 条消息 → 5分钟播客

---

**最后更新**: 2026-01-07
**目标发布**: v0.2.0 (2026 年第一季度)
