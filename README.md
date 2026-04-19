# 学习记录 App

一个面向 Android 的 Flutter 本地离线学习记录 App。

它保留了现有的主导航结构，并在原有基础上做了增量扩展：
- 新增记录
- 总记录
- 积分奖励

在原有分类、内容、番茄钟、积分、统计、CSV 导入导出基础上，这一版补齐了更适合长期使用的记录逻辑：
- 原“奖励内容”统一改为“本轮反馈”
- 新增真正的“奖励兑换”模块
- 内容支持默认积分与可调范围
- 新增详细记录字段
- 总记录页增加内容维度统计，并将薄弱点 / 改进措施汇总收纳到二级页入口
- 积分相关能力独立拆分到“积分奖励”页

## 1. 当前功能

### 新增记录
- 选择分类
- 选择内容
- 自动带出内容默认积分
- 按配置决定积分是否允许微调
- 选择番茄钟数
- 选择本轮反馈
- 修改记录时间
- 填写详细记录
- 保存 / 保存并继续新增
- 编辑既有记录

### 总记录
- 按日 / 周 / 月 / 年查看统计
- 查看总番茄钟数量
- 查看总积分数量
- 查看分类汇总、环比、同比
- 查看内容维度统计
- 通过二级入口查看薄弱点 TOP 5
- 通过二级入口查看改进措施 TOP 5
- 查看学习明细列表

### 积分奖励
- 查看累计获得积分、已兑换积分、当前可用积分
- 在奖励中心直接兑换奖励
- 查看兑换记录
- 支持撤销兑换并返还积分

### 设置
- 分类管理
- 内容管理
- 本轮反馈管理
- 薄弱点管理
- 改进措施管理
- 奖励兑换管理
- CSV 导入导出

## 2. 本轮反馈 与 奖励兑换

### 本轮反馈
本轮反馈是每条学习记录结束后的轻量恢复方式，仍然绑定单条记录。

默认项：
- 默认短休息
- 拉伸
- 喝水
- 起身走动
- 闭眼休息3分钟
- 上厕所

说明：
- 数据库底层仍兼容旧 reward 字段
- UI 和业务层统一解释为“本轮反馈”
- 历史记录不会丢失

### 奖励兑换
奖励兑换是真正的积分消费模块，不再绑定单条记录，而是独立管理。

默认奖励：
- 听歌10分钟：6分
- 看视频20分钟：10分
- 散步15分钟：12分
- 买饮料：15分
- 周末多休息半小时：20分

积分口径：
- 累计获得积分 = 所有学习记录 points 累加
- 已兑换积分 = 所有兑换记录 cost_points 累加
- 当前可用积分 = 累计获得积分 - 已兑换积分

## 3. 内容积分逻辑

每个内容项都支持以下配置：
- `default_points`
- `allow_adjust`
- `min_points`
- `max_points`

录入逻辑：
1. 先选分类
2. 再选内容
3. 自动带出默认积分
4. 如果 `allow_adjust = true`，则允许在 `min_points ~ max_points` 内微调
5. 如果 `allow_adjust = false`，则积分固定

默认内容与积分范围：

### 行测
- 判断推理：默认 2，范围 1~3
- 资料分析：默认 3，范围 2~4
- 言语理解：默认 2，范围 1~3
- 常识：默认 1，范围 1~2
- 数量关系：默认 3，范围 2~4

### 申论
- 练字：默认 1，范围 1~2
- 摘抄：默认 1，范围 1~2
- 概括题：默认 2，范围 1~3
- 对策题：默认 3，范围 2~4
- 公文题：默认 3，范围 2~4
- 大作文：默认 4，范围 3~4

### 英语
- 单词：默认 1，范围 1~2
- 精听：默认 2，范围 1~3
- 跟读：默认 2，范围 1~3
- 阅读：默认 2，范围 1~3
- 口语：默认 3，范围 2~4
- 写作：默认 3，范围 2~4

## 4. 详细记录结构

### 行测类
显示字段：
- 做题数
- 错题数
- 薄弱点（多选）
- 改进措施（多选）
- 备注

默认薄弱点：
- 审题不清
- 速度慢
- 公式不熟
- 逻辑混乱
- 粗心
- 时间分配差
- 知识点遗忘

默认改进措施：
- 重做错题
- 复盘笔记
- 总结题型
- 限时训练
- 查漏补缺
- 背公式
- 看解析

### 申论类
显示字段：
- 完成量
- 输出类型
- 薄弱点（多选）
- 改进措施（多选）
- 备注

默认输出类型：
- 练字
- 摘抄
- 概括
- 对策
- 公文
- 作文

默认薄弱点：
- 字迹不稳
- 概括不准
- 要点遗漏
- 语言空泛
- 逻辑不清
- 结构松散
- 无法下笔

默认改进措施：
- 抄写范文
- 重写答案
- 提炼要点
- 积累表达
- 列提纲
- 看参考答案
- 限时训练

### 英语类
显示字段：
- 学习量
- 错误数 / 卡顿点数
- 薄弱点（多选）
- 改进措施（多选）
- 备注

默认薄弱点：
- 发音不准
- 听不清
- 词义不熟
- 句子看不懂
- 反应慢
- 输出困难
- 语法薄弱

默认改进措施：
- 重听
- 跟读
- 查词
- 记笔记
- 复述
- 复习单词
- 精读句子

## 5. 数据库结构

### 现有学习记录表扩展字段
`study_records` 新增并兼容以下字段：
- `detail_amount_text`
- `question_count`
- `wrong_count`
- `output_type`
- `weakness_tags`
- `improvement_tags`
- `notes`
- `feedback_option_id`
- `feedback_name_snapshot`

说明：
- `weakness_tags` / `improvement_tags` 以 JSON 字符串存储
- 仍保留旧 reward 快照字段用于兼容历史数据

### 内容配置表扩展字段
`content_options` 增加：
- `default_points`
- `allow_adjust`
- `min_points`
- `max_points`

### 新增配置表
- `weakness_options`
- `improvement_options`
- `redeem_rewards`
- `reward_redemption_records`

其中：
- `redeem_rewards` 用于奖励池
- `reward_redemption_records` 用于兑换记录

## 6. CSV 导入导出

当前支持以下 CSV：
- `categories.csv`
- `content_options.csv`
- `feedback_options.csv`
- `weakness_options.csv`
- `improvement_options.csv`
- `redeem_rewards.csv`
- `study_records.csv`
- `reward_redemption_records.csv`

兼容旧文件名：
- `reward_options.csv`
  - 导入时会自动按 `feedback_options.csv` 处理

### 编码
- 导出编码：UTF-8 with BOM
- 目标：保证 Excel 打开中文不乱码

### 导入模式
- 追加导入
- 覆盖导入

### 导入规则
- 先校验表头
- 只覆盖本次选中的 CSV 类型
- 导入成功后刷新页面
- 历史快照字段仍然保留

## 7. CSV 字段说明

### content_options.csv
```csv
id,name,category_id,sort_order,is_enabled,default_points,allow_adjust,min_points,max_points,created_at,updated_at
```

### feedback_options.csv
```csv
id,name,sort_order,is_enabled,created_at,updated_at
```

### weakness_options.csv
```csv
id,name,category_id,sort_order,is_enabled,created_at,updated_at
```

### improvement_options.csv
```csv
id,name,category_id,sort_order,is_enabled,created_at,updated_at
```

### redeem_rewards.csv
```csv
id,name,cost_points,sort_order,is_enabled,note,created_at,updated_at
```

### study_records.csv
```csv
id,occurred_at,category_id,category_name_snapshot,content_option_id,content_name_snapshot,reward_option_id,reward_name_snapshot,feedback_option_id,feedback_name_snapshot,pomodoro_count,points,detail_amount_text,question_count,wrong_count,output_type,weakness_tags,improvement_tags,notes,created_at,updated_at
```

### reward_redemption_records.csv
```csv
id,reward_id,reward_name_snapshot,cost_points,redeemed_at,note,created_at
```

## 8. 总记录页显示逻辑

### 统计范围
- 日：自然日
- 周：ISO 周一到周日
- 月：自然月
- 年：自然年

### 积分奖励页
- 积分结算
  - 横向展示累计获得积分、已兑换积分、当前可用积分
- 奖励中心
  - 展示当前可兑换奖励
  - 可直接兑换并写入兑换记录
  - 支持撤销兑换并返还积分

### 总记录页新增区域
- 内容维度统计
  - 内容名称
  - 记录次数
  - 番茄钟总数
  - 积分总数
- 复盘标签入口
  - 点击进入二级页面查看薄弱点 TOP 5
  - 点击进入二级页面查看改进措施 TOP 5

### 明细摘要示例
- 行测：做题 20，错题 6，薄弱点 速度慢、粗心，改进 重做错题、限时训练
- 申论：完成量 1题，输出类型 概括，薄弱点 要点遗漏，改进 提炼要点
- 英语：学习量 20个单词，错误数 4，薄弱点 词义不熟，改进 复习单词

## 9. 运行与测试

### 安装依赖
```bash
flutter pub get
```

### 启动
```bash
flutter run
```

### 运行测试
```bash
flutter test
```

## 10. 测试覆盖

当前已补充或更新：
- 周期计算测试
- 环比 / 同比计算测试
- 聚合统计测试
- CSV 解析与导入测试
- StudyRecord 新字段兼容测试

## 11. 项目说明

本次改动遵循以下原则：
- 不推翻已有项目结构
- 不重做底部导航
- 不重建数据库
- 以迁移和局部扩展为主
- 保持本地离线与 Android 优先
- 尽量兼容已有历史数据和旧 CSV
