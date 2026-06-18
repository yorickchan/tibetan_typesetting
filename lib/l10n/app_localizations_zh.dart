// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '藏文排版';

  @override
  String get projects => '项目';

  @override
  String get newProject => '新建项目';

  @override
  String get searchProjects => '搜索项目';

  @override
  String get noProjectsYet => '暂无项目，创建一个开始吧。';

  @override
  String get open => '打开';

  @override
  String get exportPdf => '导出 PDF';

  @override
  String get exportJson => 'JSON';

  @override
  String get importJson => '导入 JSON';

  @override
  String get deleteProject => '删除项目';

  @override
  String areYouSureDelete(String name) {
    return '确定要删除 $name 吗？此操作无法撤销。';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get create => '创建';

  @override
  String get save => '保存';

  @override
  String get projectCreated => '项目已创建';

  @override
  String get projectUpdated => '项目已更新';

  @override
  String get projectDeleted => '项目已删除';

  @override
  String get projectDuplicated => '项目已复制';

  @override
  String get projectExported => '项目已导出';

  @override
  String get projectImported => '项目已导入';

  @override
  String get failedToCreateProject => '创建项目失败';

  @override
  String get failedToUpdateProject => '更新项目失败';

  @override
  String get failedToDeleteProject => '删除项目失败';

  @override
  String get failedToDuplicateProject => '复制项目失败';

  @override
  String get failedToExportProject => '导出项目失败';

  @override
  String get failedToImportProject => '导入项目失败';

  @override
  String get renameProject => '重命名项目';

  @override
  String get name => '名称';

  @override
  String get tags => '标签';

  @override
  String get tagsHint => '用逗号分隔标签';

  @override
  String get projectName => '项目名称';

  @override
  String updated(String date) {
    return '更新于 $date';
  }

  @override
  String get editor => '编辑器';

  @override
  String get addBlock => '添加段落';

  @override
  String get deleteBlock => '删除段落';

  @override
  String get moveBlockUp => '上移';

  @override
  String get moveBlockDown => '下移';

  @override
  String get lineBreak => '换列';

  @override
  String get newPage => '换页';

  @override
  String get smallText => '小字';

  @override
  String get freeText => '自由文本';

  @override
  String get freeTextContent => '中文或英文文本';

  @override
  String get openingMark => '开篇标记';

  @override
  String get tibetanText => '藏文';

  @override
  String get chinesePronunciation => '中文注音';

  @override
  String get chineseTranslation => '中文翻译';

  @override
  String get selectBlockToEdit => '请在上方选择一个段落开始编辑。';

  @override
  String blockNumber(int current, int total) {
    return '第 $current 段，共 $total 段';
  }

  @override
  String get pageSetup => '页面设置';

  @override
  String get pageWidth => '宽度 (mm)';

  @override
  String get pageHeight => '高度 (mm)';

  @override
  String get margins => '页边距';

  @override
  String get top => '上';

  @override
  String get bottom => '下';

  @override
  String get left => '左';

  @override
  String get right => '右';

  @override
  String get columns => '栏数';

  @override
  String get autoPerPage => '每页自动';

  @override
  String get sentenceSpacing => '句距';

  @override
  String get showFrame => '显示边框';

  @override
  String get showRowLines => '显示行线';

  @override
  String get leftVerticalTitle => '左侧竖排标题';

  @override
  String get pageNumberLabel => '页码';

  @override
  String get exportPdfHint => '使用导出 PDF 输出。缩放：Cmd +/−/0';

  @override
  String get titlePage => '封面';

  @override
  String get showTitlePage => '显示封面';

  @override
  String get titleTibetanLabel => '标题（藏文）';

  @override
  String get titleChineseLabel => '标题（中文）';

  @override
  String get projectFonts => '项目字体';

  @override
  String get resetToDefault => '重置为默认';

  @override
  String get tibetanLabel => '藏文';

  @override
  String get chineseLabel => '中文';

  @override
  String get titleTibetanFont => '封面藏文字体';

  @override
  String get titleChineseFont => '封面中文字体';

  @override
  String defaultValueWithName(String name) {
    return '默认：$name';
  }

  @override
  String get dharmaWheel => '法轮';

  @override
  String get fonts => '字体';

  @override
  String get tibetanFont => '藏文字体';

  @override
  String get pronunciationFont => '注音字体';

  @override
  String get translationFont => '翻译字体';

  @override
  String get defaultValue => '默认';

  @override
  String defaultFont(String name) {
    return '默认值：$name';
  }

  @override
  String get reset => '重置';

  @override
  String get fontSize => '字号';

  @override
  String get preferences => '偏好设置';

  @override
  String get settings => '设置';

  @override
  String get export => '导出';

  @override
  String get exportSettings => '导出设置';

  @override
  String get preview => '预览';

  @override
  String get printing => '打印中';

  @override
  String get print => '打印';

  @override
  String get savePdf => '保存 PDF';

  @override
  String pageNumber(int number) {
    return '第 $number 页';
  }

  @override
  String get projectNotFound => '项目未找到';

  @override
  String get saving => '保存中...';

  @override
  String get saved => '已保存';

  @override
  String get saveError => '保存失败';

  @override
  String get undo => '撤销';

  @override
  String get redo => '重做';

  @override
  String get cut => '剪切';

  @override
  String get copy => '复制';

  @override
  String get paste => '粘贴';

  @override
  String get selectAll => '全选';

  @override
  String get about => '关于藏文排版';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get systemDefault => '跟随系统';

  @override
  String get untitled => '未命名';

  @override
  String get exportProjectJson => '导出项目 JSON';

  @override
  String get applicationSettings => '应用设置';

  @override
  String get configureFonts => '请配置默认字体以开始使用。';

  @override
  String get defaultFonts => '默认字体';

  @override
  String get defaultPageSize => '默认页面大小';

  @override
  String get tibetan => '藏文';

  @override
  String get pronunciation => '注音';

  @override
  String get translation => '翻译';

  @override
  String get width => '宽度';

  @override
  String get height => '高度';

  @override
  String get size => '字号';

  @override
  String get pronunciationDictionary => '发音字典';

  @override
  String deleteEntry(String syllable) {
    return '删除\"$syllable\"？';
  }

  @override
  String get charactersInPronunciation => '注音字符数：';

  @override
  String syllableMapsToChars(int count) {
    return '此音节在自动填充时对应 $count 个中文字符。';
  }

  @override
  String get exportDictionary => '导出字典';

  @override
  String get import => '导入';

  @override
  String get searchEntries => '搜索词条';

  @override
  String get noEntriesYet => '暂无词条。在编辑器中输入藏文和注音即可自动保存。';

  @override
  String get noMatchingEntries => '没有匹配的词条。';

  @override
  String get edit => '编辑';

  @override
  String importedCount(int count) {
    return '已导入 $count 个词条';
  }

  @override
  String get block => '段落';

  @override
  String get move => '移动';

  @override
  String get tibetanLabelShort => '藏文';

  @override
  String get pronunciationLabelShort => '注音';

  @override
  String get translationLabelShort => '翻译';

  @override
  String get titlePageTemplates => '封面模板';

  @override
  String get titlePageTemplate => '模板';

  @override
  String get addTemplate => '添加模板';

  @override
  String get deleteTemplate => '删除模板';

  @override
  String get templateName => '模板名称';

  @override
  String get templateInset => '模板邊距 (mm)';

  @override
  String get templateInsetHint => '自訂模板周圍的邊距';

  @override
  String get titleTextInset => '标题文字框邊距 (mm)';

  @override
  String get titleTextInsetHint => '标题文字框周圍的邊距';

  @override
  String get invalidSvgFile => '无效的 SVG 文件';

  @override
  String get defaultLayout => '默认布局';
}

/// The translations for Chinese, as used in Taiwan (`zh_TW`).
class AppLocalizationsZhTw extends AppLocalizationsZh {
  AppLocalizationsZhTw() : super('zh_TW');

  @override
  String get appTitle => '藏文排版';

  @override
  String get projects => '專案';

  @override
  String get newProject => '新建專案';

  @override
  String get searchProjects => '搜尋專案';

  @override
  String get noProjectsYet => '暫無專案，建立一個開始吧。';

  @override
  String get open => '開啟';

  @override
  String get exportPdf => '匯出 PDF';

  @override
  String get exportJson => 'JSON';

  @override
  String get importJson => '匯入 JSON';

  @override
  String get deleteProject => '刪除專案';

  @override
  String areYouSureDelete(String name) {
    return '確定要刪除 $name 嗎？此動作無法復原。';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '刪除';

  @override
  String get create => '建立';

  @override
  String get save => '儲存';

  @override
  String get projectCreated => '專案已建立';

  @override
  String get projectUpdated => '專案已更新';

  @override
  String get projectDeleted => '專案已刪除';

  @override
  String get projectDuplicated => '專案已複製';

  @override
  String get projectExported => '專案已匯出';

  @override
  String get projectImported => '專案已匯入';

  @override
  String get failedToCreateProject => '建立專案失敗';

  @override
  String get failedToUpdateProject => '更新專案失敗';

  @override
  String get failedToDeleteProject => '刪除專案失敗';

  @override
  String get failedToDuplicateProject => '複製專案失敗';

  @override
  String get failedToExportProject => '匯出專案失敗';

  @override
  String get failedToImportProject => '匯入專案失敗';

  @override
  String get renameProject => '重新命名專案';

  @override
  String get name => '名稱';

  @override
  String get tags => '標籤';

  @override
  String get tagsHint => '用逗號分隔標籤';

  @override
  String get projectName => '專案名稱';

  @override
  String updated(String date) {
    return '更新於 $date';
  }

  @override
  String get editor => '編輯器';

  @override
  String get addBlock => '新增段落';

  @override
  String get deleteBlock => '刪除段落';

  @override
  String get moveBlockUp => '上移';

  @override
  String get moveBlockDown => '下移';

  @override
  String get lineBreak => '換欄';

  @override
  String get newPage => '換頁';

  @override
  String get smallText => '小字';

  @override
  String get freeText => '自由文字';

  @override
  String get freeTextContent => '中文或英文文字';

  @override
  String get openingMark => '卷首標記';

  @override
  String get tibetanText => '藏文';

  @override
  String get chinesePronunciation => '中文拼音';

  @override
  String get chineseTranslation => '中文翻譯';

  @override
  String get selectBlockToEdit => '請在上方選擇一個段落開始編輯。';

  @override
  String blockNumber(int current, int total) {
    return '第 $current 段，共 $total 段';
  }

  @override
  String get pageSetup => '頁面設定';

  @override
  String get pageWidth => '寬度 (mm)';

  @override
  String get pageHeight => '高度 (mm)';

  @override
  String get margins => '頁邊距';

  @override
  String get top => '上';

  @override
  String get bottom => '下';

  @override
  String get left => '左';

  @override
  String get right => '右';

  @override
  String get columns => '欄數';

  @override
  String get autoPerPage => '每頁自動';

  @override
  String get sentenceSpacing => '句距';

  @override
  String get showFrame => '顯示邊框';

  @override
  String get showRowLines => '顯示行線';

  @override
  String get leftVerticalTitle => '左側豎排標題';

  @override
  String get pageNumberLabel => '頁碼';

  @override
  String get exportPdfHint => '使用匯出 PDF 輸出。縮放：Cmd +/−/0';

  @override
  String get titlePage => '封面';

  @override
  String get showTitlePage => '顯示封面';

  @override
  String get titleTibetanLabel => '標題（藏文）';

  @override
  String get titleChineseLabel => '標題（中文）';

  @override
  String get projectFonts => '專案字體';

  @override
  String get resetToDefault => '重設為預設';

  @override
  String get tibetanLabel => '藏文';

  @override
  String get chineseLabel => '中文';

  @override
  String get titleTibetanFont => '封面藏文字體';

  @override
  String get titleChineseFont => '封面中文字體';

  @override
  String defaultValueWithName(String name) {
    return '預設：$name';
  }

  @override
  String get dharmaWheel => '法輪';

  @override
  String get fonts => '字體';

  @override
  String get tibetanFont => '藏文字體';

  @override
  String get pronunciationFont => '拼音字體';

  @override
  String get translationFont => '翻譯字體';

  @override
  String get defaultValue => '預設';

  @override
  String defaultFont(String name) {
    return '預設值：$name';
  }

  @override
  String get reset => '重設';

  @override
  String get fontSize => '字型大小';

  @override
  String get preferences => '偏好設定';

  @override
  String get settings => '設定';

  @override
  String get export => '匯出';

  @override
  String get exportSettings => '匯出設定';

  @override
  String get preview => '預覽';

  @override
  String get printing => '列印中';

  @override
  String get print => '列印';

  @override
  String get savePdf => '儲存 PDF';

  @override
  String pageNumber(int number) {
    return '第 $number 頁';
  }

  @override
  String get projectNotFound => '專案未找到';

  @override
  String get saving => '儲存中...';

  @override
  String get saved => '已儲存';

  @override
  String get saveError => '儲存失敗';

  @override
  String get undo => '復原';

  @override
  String get redo => '重做';

  @override
  String get cut => '剪下';

  @override
  String get copy => '複製';

  @override
  String get paste => '貼上';

  @override
  String get selectAll => '全選';

  @override
  String get about => '關於藏文排版';

  @override
  String get language => '語言';

  @override
  String get theme => '主題';

  @override
  String get themeSystem => '跟隨系統';

  @override
  String get themeLight => '淺色';

  @override
  String get themeDark => '深色';

  @override
  String get systemDefault => '跟隨系統';

  @override
  String get untitled => '未命名';

  @override
  String get exportProjectJson => '匯出專案 JSON';

  @override
  String get applicationSettings => '應用程式設定';

  @override
  String get configureFonts => '請設定預設字體以開始使用。';

  @override
  String get defaultFonts => '預設字體';

  @override
  String get defaultPageSize => '預設頁面大小';

  @override
  String get tibetan => '藏文';

  @override
  String get pronunciation => '拼音';

  @override
  String get translation => '翻譯';

  @override
  String get width => '寬度';

  @override
  String get height => '高度';

  @override
  String get size => '大小';

  @override
  String get pronunciationDictionary => '發音字典';

  @override
  String deleteEntry(String syllable) {
    return '刪除「$syllable」？';
  }

  @override
  String get charactersInPronunciation => '拼音字元數：';

  @override
  String syllableMapsToChars(int count) {
    return '此音節在自動填寫時對應 $count 個中文字元。';
  }

  @override
  String get exportDictionary => '匯出字典';

  @override
  String get import => '匯入';

  @override
  String get searchEntries => '搜尋詞條';

  @override
  String get noEntriesYet => '暫無詞條。在編輯器中輸入藏文和拼音即可自動儲存。';

  @override
  String get noMatchingEntries => '沒有相符的詞條。';

  @override
  String get edit => '編輯';

  @override
  String importedCount(int count) {
    return '已匯入 $count 個詞條';
  }

  @override
  String get block => '段落';

  @override
  String get move => '移動';

  @override
  String get tibetanLabelShort => '藏文';

  @override
  String get pronunciationLabelShort => '拼音';

  @override
  String get translationLabelShort => '翻譯';

  @override
  String get titlePageTemplates => '封面範本';

  @override
  String get titlePageTemplate => '範本';

  @override
  String get addTemplate => '新增範本';

  @override
  String get deleteTemplate => '刪除範本';

  @override
  String get templateName => '範本名稱';

  @override
  String get templateInset => '範本邊距 (mm)';

  @override
  String get templateInsetHint => '自訂範本周圍的邊距';

  @override
  String get titleTextInset => '標題文字框邊距 (mm)';

  @override
  String get titleTextInsetHint => '標題文字框周圍的邊距';

  @override
  String get invalidSvgFile => '無效的 SVG 檔案';

  @override
  String get defaultLayout => '預設佈局';
}
