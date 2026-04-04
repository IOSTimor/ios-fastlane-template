# zh-Hans Screenshots

将 `zh-Hans` 语言的 App Store 截图放到这个目录。

推荐命名：

- `01-home.png`
- `02-feature.png`
- `03-results.png`

建议：

- 用数字前缀保持顺序稳定
- 优先使用 PNG
- 只放最终上传文件，不放设计源文件
- 这个目录只保留 `zh-Hans` 对应的截图
- 如果团队有固定截图流程，可以直接改写这份说明

建议流程：

1. 先确定每张截图的标题和卖点文案
2. 从 App 或设计工具导出最终图
3. 放入当前目录
4. 执行 `fastlane ios precheck_assets`
5. 再执行 `fastlane ios metadata_only` 或发布 lane
