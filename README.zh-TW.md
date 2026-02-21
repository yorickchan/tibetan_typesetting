# 藏文排版

一個用於創建和匯出藏文文檔的 Flutter 桌面應用程式，採用傳統排版格式並包含中文翻譯。

![主畫面](screenshot/main%20screen.png)

## 功能特色

### 📝 豐富的文字編輯
- 創建和管理多個藏文文檔專案
- 將內容組織為文字區塊，包含：
  - 藏文文字（支援標題）
  - 中文讀音（音標轉寫）
  - 中文翻譯
- 視覺化的區塊導航和管理
- 自動儲存功能

### 🔤 讀音詞典
- 本地音節級藏文轉中文讀音詞典
- 輸入藏文時自動填入中文讀音
- 未知音節在藏文欄位以黃色高亮顯示，在讀音欄位顯示為 `X`
- 輸入讀音時自動儲存至詞典
- 支援縮寫音節的多字讀音設定（例如 པདྨ → 2 個中文字）
- 詞典管理頁面，支援搜尋、編輯和刪除
- 支援將詞典匯出／匯入為 JSON 格式以便分享

![自動讀音](screenshot/auto%20pronunciation.png)

![編輯畫面](screenshot/edit%20screen.png)

### 📄 傳統排版格式
- 傳統藏文書籍排版（橫向方向）
- 可自訂的頁面尺寸和邊距
- 多欄排版支援（1-8 欄）
- 分頁和分欄控制
- 自訂封面頁，帶有法輪符號
- 彈性的文字大小選項

### 🖨️ PDF 匯出
- 高品質的 PDF 生成，完美呈現藏文字型
- 匯出前即時預覽
- 直接從應用程式列印
- 分享或儲存 PDF 檔案
- 正確處理複雜的藏文 OpenType 功能

![匯出 PDF](screenshot/export%20pdf.png)

## 技術亮點

### 藏文字型渲染
應用程式採用精密的方式處理 PDF 中的藏文字型渲染：
- 使用 Flutter 原生文字引擎預渲染藏文文字
- 將文字轉換為高解析度 PNG 圖片（288 DPI）
- 將圖片嵌入 PDF 以保留複雜的 OpenType 字型塑形
- 這個解決方案確保完美的藏文字型顯示，這是標準 PDF 文字渲染無法達成的

### 資料持久化
- 使用 SQLite 資料庫進行可靠的本地儲存
- 專案以 JSON 格式儲存，並建立索引的中繼資料
- 支援專案匯入/匯出
- 專案複製和標籤功能

## 開始使用

### 系統需求
- Flutter SDK (^3.11.0)
- 桌面平台支援（macOS、Windows 或 Linux）

### 安裝

1. 複製儲存庫：
```bash
git clone <repository-url>
cd tibetan_typesetting
```

2. 安裝相依套件：
```bash
flutter pub get
```

3. 執行應用程式：
```bash
flutter run
```

### 字型需求

應用程式使用系統字型：
- **藏文**：BabelStoneTibetan（或其他藏文 Unicode 字型）
- **中文**：STHeiti（通常在 macOS 上預先安裝）

請確保這些字型已安裝在您的系統上，以正確顯示文字。

## 使用方式

1. **創建專案**：從主畫面開始創建新專案
2. **新增內容**：新增包含藏文文字、讀音和翻譯的文字區塊
3. **讀音自動填入**：輸入藏文時，編輯器會自動從詞典填入讀音；未知音節以高亮和 `X` 標示
4. **編輯排版**：設定頁面設定、邊距和欄數
5. **預覽**：即時預覽您的文檔排版
6. **匯出**：生成 PDF 或直接從應用程式列印
7. **管理詞典**：開啟讀音詞典頁面，檢視、搜尋、編輯或刪除已儲存的音節項目，並可匯出／匯入 JSON

![讀音詞典](screenshot/pronunciation%20dictionary.png)

## 專案結構

```
lib/
├── main.dart                    # 應用程式進入點
├── models/                      # 資料模型
│   ├── project.dart            # Project、TextBlock、PageSetup
│   ├── app_settings.dart       # 應用程式設定
│   ├── font_config.dart        # 字型設定
│   └── pronunciation_entry.dart # 讀音詞典項目
├── pages/                       # 主要應用程式頁面
│   ├── projects_page.dart      # 專案管理
│   ├── editor_page.dart        # 文字編輯器
│   ├── export_page.dart        # PDF 匯出和預覽
│   ├── settings_page.dart      # 應用程式設定
│   └── dictionary_page.dart    # 讀音詞典管理
├── services/                    # 業務邏輯
│   ├── database_service.dart   # SQLite 持久化
│   ├── pdf_service.dart        # PDF 生成
│   ├── font_service.dart       # 字型管理
│   ├── settings_service.dart   # 設定管理
│   └── pronunciation_service.dart # 讀音詞典 CRUD
├── utils/                       # 工具程式
│   ├── colors.dart             # 色彩配置
│   ├── sample_layout.dart      # 分頁邏輯
│   ├── text_renderer.dart      # 文字轉圖片渲染
│   ├── font_utils.dart         # 字型工具
│   └── tibetan_segmenter.dart  # 藏文音節切分（基於 tsheg）
└── widgets/                     # 可重複使用的 UI 元件
    ├── app_shell.dart          # 通用架構
    ├── block_editor.dart       # 區塊編輯面板
    ├── block_strip.dart        # 區塊導航
    ├── font_picker.dart        # 字型選擇器
    ├── sample_page.dart        # 頁面預覽
    ├── sample_pages.dart       # 多頁面預覽
    └── title_page_widget.dart  # 封面頁預覽
```

## 開發

### 程式碼分析
```bash
flutter analyze
```

### 執行測試
```bash
flutter test
```

### 建置發佈版本

**macOS:**
```bash
flutter build macos
```

**Windows:**
```bash
flutter build windows
```

**Linux:**
```bash
flutter build linux
```

## 架構

### 核心元件

- **DatabaseService**：管理 SQLite 操作的單例服務，用於專案持久化
- **PdfService**：處理 PDF 生成的單例服務，包含藏文文字預渲染
- **FontService**：系統字型探測和管理
- **SettingsService**：應用程式設定持久化
- **PronunciationService**：本地讀音詞典的 CRUD 單例服務
- **TibetanSegmenter**：藏文音節切分工具，基於 tsheg（་）分割

### 頁面排版演算法

`sample_layout.dart` 工具實作了兩階段分頁系統：
1. 根據欄數將區塊組織為列
2. 將列分配到各頁面，遵循分隔標記
3. 處理分頁和分欄控制

### 文字渲染流程

1. 文字輸入 → `TextPainter`（Flutter 的文字引擎）
2. 以 4 倍比例渲染為 `Picture`，以達到高 DPI
3. 轉換為 PNG 位元組
4. 以圖片形式嵌入 PDF

這個方法確保完美的藏文字型渲染，並正確支援 OpenType 功能（GSUB/GPOS）。

## 授權條款

本專案採用 GNU 通用公共授權條款 2.0 版授權 - 詳見 [LICENSE](LICENSE) 檔案。

## 貢獻

歡迎貢獻！請隨時提交問題或拉取請求。

## 致謝

- 使用 [Flutter](https://flutter.dev/) 建置
- 使用 [BabelStoneTibetan](https://www.babelstone.co.uk/Fonts/Tibetan.html) 字型顯示藏文字型
- PDF 生成由 [pdf](https://pub.dev/packages/pdf) 套件提供支援
