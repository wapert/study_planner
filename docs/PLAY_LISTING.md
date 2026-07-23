# Google Play — Store Listing

Paste into Play Console → your app → **Grow → Store presence → Main store listing**.

---

## App name (max 30 chars)
```
讀書計畫 - 學習計畫與行事曆
```

## Short description (max 80 chars — Play only)
```
設定每週章節進度，自動分配到每一天。內建台灣學期行事曆，跨裝置雲端同步。
```

## Full description (max 4000 chars)
```
讀書計畫是專為台灣國中、高中學生設計的學習規劃 App，幫你把「要讀什麼」變成「每天讀多少」。

■ 今日視圖
一眼看見今天每個科目要完成的章節與待辦，打勾完成、掌握進度，像記事本一樣簡單。

■ 章節計畫，自動分配
輸入「第 1 課～第 20 課」與每週讀書日，App 會自動把範圍平均分配到你選的每一天，並顯示在今日、行事曆與讀書計畫頁。可設定本週、本月或自訂區間。

■ 內建台灣學期行事曆
預載台灣國定假日、開學、期中考、期末考、寒暑假等重要日期，考試不再忘記。

■ 進度追蹤
以圖表檢視每週讀書時數、各科目分佈與章節完成度，讀了多少一目了然。

■ 個人化科目
依國中或高中一鍵套用預設科目（國文、英文、數學、自然、物理、化學…），也可自訂顏色與每週目標。

■ 雲端同步與分享
用帳號登入即可在手機、平板之間自動同步。還能把你的讀書計畫（唯讀）分享給家長或老師，讓他們一起關心你的學習。

■ 隱私優先
沒有廣告、不追蹤、不販售資料。你的資料只用於同步與你主動選擇的分享。

現在就開始，把讀書計畫變成每天做得到的小目標！
```

---

## Graphics (all generated in docs/play/)
| Asset | File | Size |
|-------|------|------|
| App icon | `docs/play/icon_512.png` | 512×512 |
| Feature graphic | `docs/play/feature_graphic.png` | 1024×500 |
| Phone screenshots (×5) | `docs/play/screenshots/` | 1320×2640 |

## Categorization
- **App category**: Education
- **Tags**: study, planner, calendar, education, students
- **Contact email**: wapertech@gmail.com
- **Website** (optional): https://wapert.github.io/study_planner/
- **Privacy Policy**: https://wapert.github.io/study_planner/privacy.html

---

## Data safety form (App content → Data safety)
Answer the questionnaire as:

**Does your app collect or share any of the required user data types?** → **Yes**

**Data collected:**
- **Personal info → Email address**
  - Collected: Yes · Shared: No
  - Processed ephemerally: No
  - Required (not optional)
  - Purposes: **Account management**, **App functionality**
- **Personal info → User IDs** (Firebase UID)
  - Collected: Yes · Shared: No
  - Purposes: **Account management**, **App functionality**
- **App activity → Other user-generated content** (study plans, to-dos, chapters)
  - Collected: Yes · Shared: No
  - Purposes: **App functionality**

**Security practices:**
- **Is data encrypted in transit?** → **Yes**
- **Can users request data deletion?** → **Yes** (in-app: 帳號與同步 → 刪除帳號, and via email)
- **Committed to Play Families Policy?** → follow the prompts; app is not directed at children under 13 as its target audience is teens (國高中).

**Do you use data for tracking / advertising?** → **No** (no ads, no analytics, no third-party tracking)

---

## Content rating (App content → Content rating)
Run the IARC questionnaire; answer **No** to all violence/sexual/drugs/gambling questions → expected rating **Everyone / 3+**.
Category for the questionnaire: **Reference, News, or Educational**.

## App access
If Play review needs a login, provide test credentials under **App content → App access**:
- All functionality requires sign-in → provide:
  - Username: `demo@studyplanner.app`
  - Password: `demo123456`

## Release
- Upload **`build/app/outputs/bundle/release/app-release.aab`** to a release
  (start with **Internal testing** to verify, then promote to **Production**).
- Enrol in **Play App Signing** when prompted (recommended — Google manages the
  app signing key; your upload key just signs uploads).
```
