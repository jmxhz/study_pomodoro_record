# Project Status

## 更新时间
- 2026-04-12

## 当前阶段
- 项目已从早期“可调积分 / 本轮反馈 / 多番茄单条记录”的旧逻辑，迁移到“固定积分 / 休息类型 / 单条固定 1 个番茄 / 内容级复盘模板”的新逻辑。
- 当前工作方式仍然是增量修改，不做整体重构。

## 当前已完成

### 1. 固定积分与单条记录
- `ContentOption` 已以 `points` 作为新逻辑主字段
- 新增记录页不再手动调节积分
- 每条新增记录固定写入 `pomodoroCount = 1`

### 2. 休息逻辑
- 原“本轮反馈”已切换为“休息”逻辑
- 休息类型分为：
  - `short`
  - `long`
- `long_break_every` 已接入设置页，可配置 `2 / 3 / 4`
- 新增记录会根据当天完成记录数自动判断当前是短休息还是长休息

### 3. 详细记录内容级模板
- 详细记录模板已从按大类改为按具体内容
- 英语、申论、行测内容已支持独立薄弱点 / 改进措施模板
- 模板绑定优先使用 `content_option_id`
- 若无内容专属模板，则回退使用旧分类模板
- 申论已移除“输出类型”新 UI、默认值与新保存逻辑

### 4. 新增记录页轻量化
- 详细记录区域已拆成两组，默认全部收起：
  - 基础记录：完成量、错误数、备注
  - 复盘标签：薄弱点、改进措施
- 薄弱点与改进措施选择上限均为 2
- 备注输入框已调整为与其它单行输入同样高度
- 新增记录页当前时间显示已改为分钟级，以降低持续重建带来的卡顿

### 5. 标签设置页
- 薄弱点管理 / 改进措施管理已改为分组入口，不默认展开全部
- 当前按内容分组展示
- 旧分类绑定数据仍可保留显示，作为兼容数据

### 6. 总记录页
- 统计范围切换器已优化为稳定横向展示
- 顶部总番茄钟与总积分已合并为一个总览卡片
- 分类汇总已采用单卡片内双列展示
- 明细列表已改成分批展示，避免一次性拉太长
- 明细列表卡片已做过可读性增强，但仍可能继续微调

### 7. 积分奖励页
- 奖励中心兑换逻辑正常
- 首页“兑换记录”已改为只显示本周记录
- 旧周记录已放入单独“历史记录”页
- 历史记录页按周分组
- 空状态卡片宽度问题已修复

### 8. 主题
- 设置页已支持主题切换
- 已提供 4 组莫奈风取色方案

## 当前仍需继续确认

### 1. 外部静态检查
- 需要用户在外部继续执行 `flutter analyze`
- 当前未在代理内部运行 Flutter 命令

### 2. UI 细节仍可能继续打磨
- 总记录页顶部同比 / 环比信息仍可能需要继续压缩和提亮
- 明细列表虽然已增强辨识度，但整体视觉疲劳感仍可能继续优化
- 分类汇总与总览卡片之间的视觉统一性可以继续收口

### 3. 文档与测试
- `README.md` 还没有完全同步到最新产品口径
- 建议后续补充或更新以下验证：
  - 内容级模板选择与回退
  - `content_option_id` 迁移兼容
  - 本周兑换记录 / 历史记录分流
  - CSV 新旧表头兼容

## 当前关键文件

### 页面与入口
- `lib/app/app.dart`
- `lib/features/add_record/pages/record_entry_page_runtime.dart`
- `lib/features/records/pages/records_overview_page.dart`
- `lib/features/rewards/pages/rewards_center_page.dart`
- `lib/features/settings/pages/settings_home_page_runtime.dart`

### 控制器
- `lib/features/add_record/controllers/record_entry_controller_runtime.dart`
- `lib/features/records/controllers/records_overview_controller.dart`
- `lib/features/rewards/controllers/rewards_center_controller.dart`
- `lib/features/settings/controllers/settings_controller_runtime.dart`

### 数据层
- `lib/core/db/app_database_runtime.dart`
- `lib/data/repositories/options_repository.dart`
- `lib/data/repositories/study_record_repository.dart`
- `lib/data/repositories/reward_redemption_repository.dart`
- `lib/data/repositories/csv_service_runtime.dart`

## 风险提示
- 项目中旧文件与 runtime 文件并存，误改旧文件可能不生效
- 个别文件与文档曾出现编码损坏；若再次出现异常，优先整体重写为 UTF-8
- 兼容旧数据优先于字段彻底清理，因此模型和数据库中仍保留部分旧字段

## 建议的下一步
1. 外部执行 `flutter analyze`
2. 真机继续验证新增记录页交互流畅度
3. 继续观察总记录页的可读性问题是否还需要新一轮 UI 收口
4. 更新 `README.md`
