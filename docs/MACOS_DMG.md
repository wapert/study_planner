# macOS 直接發布（.dmg）

在 Mac App Store 之外自行發布。使用者下載 `.dmg`，拖進「應用程式」即可。
不需要 App Review、不需要沙箱（sandbox）。

- 簽署方式：**Developer ID Application** 憑證
- 需要 **Apple 公證（notarization）**，否則使用者開啟時會被 Gatekeeper 擋下
- Team ID：`NR6H8UUF43`

---

## 一次性設定（只有你能做）

### 1. 建立 Developer ID Application 憑證

Xcode → **Settings（⌘,）** → **Accounts** → 選擇你的 Apple ID →
**Manage Certificates…** → 左下角 **＋** → **Developer ID Application**

> 每個帳號最多 5 張，且**無法從 Apple 重新下載私鑰**。
> 建立後請到「鑰匙圈存取」把憑證 + 私鑰匯出成 `.p12` 備份，
> 換電腦時才不會需要撤銷重發。

驗證：
```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

### 2. 建立 App 專用密碼（給公證用）

到 [appleid.apple.com](https://appleid.apple.com) → **登入與安全性** →
**App 專用密碼** → 產生一組（格式如 `abcd-efgh-ijkl-mnop`）。

> 這不是你的 Apple ID 密碼。公證工具不接受主密碼。

### 3. 把憑證存進鑰匙圈

```bash
xcrun notarytool store-credentials notary \
  --apple-id 你的AppleID@example.com \
  --team-id NR6H8UUF43 \
  --password abcd-efgh-ijkl-mnop
```

存好之後密碼就留在鑰匙圈裡，之後不必再輸入。

---

## 每次發布

```bash
./scripts/release_dmg.sh
```

腳本會依序完成：

| 步驟 | 內容 |
|------|------|
| 0 | 檢查憑證與公證設定，缺少時直接停下並說明 |
| 1 | `flutter build macos --release` |
| 2 | 以 Developer ID 簽署（含 Hardened Runtime） |
| 3 | 用 `create-dmg` 打包成磁碟映像檔 |
| 4 | 上傳 Apple 公證並等待結果（約 1–5 分鐘） |
| 5 | 將公證票證 staple 進 `.dmg`，讓使用者離線也能開啟 |

產出：`build/dist/讀書計畫.dmg`

---

## 發布前檢查

在**另一台**沒有你開發者憑證的 Mac 上測試最準：

```bash
# 確認公證票證有效
xcrun stapler validate build/dist/讀書計畫.dmg

# 確認 Gatekeeper 放行
spctl -a -vvv -t install /Applications/study_planner.app
```

預期看到 `source=Notarized Developer ID`。

---

## 疑難排解

**公證被拒**——用回傳的 submission id 看原因：
```bash
xcrun notarytool log <submission-id> --keychain-profile notary
```
最常見是某個巢狀二進位檔沒有 Hardened Runtime 或缺少時間戳記。

**使用者看到「無法打開，因為無法驗證開發者」**——通常是 `.dmg` 沒有 staple，
或使用者下載到舊版。重跑步驟 5 即可。

**換電腦後簽署失敗**——需要匯入先前備份的 `.p12`；Apple 不會保留你的私鑰。

---

## 版本號

`.dmg` 沒有像 App Store 那樣的版本規則，但仍建議每次發布都調高
`pubspec.yaml` 的 `version:`，方便使用者辨識與你自己追蹤。
