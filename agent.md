# Agent Notes

## 项目定位
- 这是一个 Flutter Android 优先、离线优先的学习记录 App。
- 当前协作原则是增量修改，优先在现有结构上迭代，不做大规模重构。
- 代码中存在旧文件与 `*runtime.dart` 并存的情况，修改前要先确认真实入口。

## 当前主导航
- 新增记录
- 总记录
- 积分奖励

## 当前主要入口
- `lib/app/app.dart`
- `lib/features/add_record/pages/record_entry_page_runtime.dart`
- `lib/features/records/pages/records_overview_page.dart`
- `lib/features/rewards/pages/rewards_center_page.dart`
- `lib/features/settings/pages/settings_home_page_runtime.dart`

## 当前主要数据层
- 数据库：`lib/core/db/app_database_runtime.dart`
- 配置仓库：`lib/data/repositories/options_repository.dart`
- 学习记录仓库：`lib/data/repositories/study_record_repository.dart`
- 积分兑换仓库：`lib/data/repositories/reward_redemption_repository.dart`
- CSV：`lib/data/repositories/csv_service_runtime.dart`

## 当前已落地的核心业务

### 1. 新增记录
- 每条记录固定 `pomodoroCount = 1`
- 内容积分改为固定 `points` 逻辑，不再在新增页手动调分
- 详细记录已按内容驱动，而不是按大类驱动
- 申论已移除“输出类型”新 UI 与新保存逻辑
- 详细记录已拆成两组，且默认都收起：
  - `完成量 / 错误数 / 备注`
  - `薄弱点 / 改进措施`
- 备注输入框已收敛为与其它单行输入同规格
- 新增页时间显示改为分钟级，自动更新时间频率已下调，用于减少滚动和点击卡顿

### 2. 薄弱点 / 改进措施
- 模板已从按分类绑定，改为优先按 `content_option_id` 绑定
- 若当前内容没有专属模板，会回退到旧的分类级模板
- 每个内容默认最多展示 5 个薄弱点候选、5 个改进措施候选
- 每次最多选择 2 个薄弱点、2 个改进措施
- 设置页相关入口已改成按内容分组查看，不再默认一次性展开全部标签

### 3. 数据兼容
- `weakness_options` 与 `improvement_options` 已增加 `content_option_id`
- 旧的 `category_id` 绑定仍保留作兼容回退
- `study_records.output_type` 旧数据仍可读，但新 UI 不再编辑，新保存显式写 `null`
- 历史记录中的旧标签、旧快照字段继续保留，避免崩溃

### 4. 总记录页
- 统计范围选择器已改为更稳定的横向选择器
- 顶部总番茄钟 / 总积分已合并为一个总览卡片
- 分类汇总卡片已改为同一张卡片内左右展示“番茄钟 / 积分”
- `同比 / 环比` 展示已做过多轮适配，目前以可读性优先
- 明细列表已支持分页式“继续查看剩余 X 条”
- 明细列表卡片已做过层级强化：时间、标签、详情分区更清晰

### 5. 积分奖励页
- 奖励池维持原有兑换逻辑
- 兑换记录首页现在只显示“本周兑换记录”
- 早于本周的兑换记录已移入“历史记录”页查看
- 兑换记录历史页按周分组显示
- 空状态卡片已修正为全宽，避免右侧留白

### 6. 主题
- 设置页已支持主题切换
- 当前已内置 4 组莫奈风配色：
  - `monet-mist`
  - `monet-water`
  - `monet-sunset`
  - `monet-garden`

## 当前设置页结构
- 分类管理
- 内容管理
- 休息管理
- 薄弱点管理
- 改进措施管理
- 奖励兑换管理
- CSV 导入导出
- 主题配色

## 当前代码注意事项
- `analysis_options.yaml` 当前优先关注 `*runtime.dart`
- 项目里部分文档与旧文件出现过编码问题；若再次编辑异常，优先整体重写为 UTF-8
- 用户要求 `flutter analyze` / `flutter test` / `flutter run` 由用户在外部执行，不要擅自运行

## 用户协作偏好
- 回答中要明确说明：
  - 改了哪些文件
  - 改了什么关键逻辑
  - 是否运行过验证命令
- 能直接落地的改动优先直接实现，不只停留在分析

## 推荐下一步检查点
- 外部执行 `flutter analyze`
- 重点验收：
  - 新增记录页两组折叠区交互与流畅度
  - 内容级薄弱点 / 改进措施展示是否正确
  - 总记录页顶部统计、分类汇总、明细列表的可读性
  - 积分奖励页“本周记录 + 历史记录”行为是否符合预期
