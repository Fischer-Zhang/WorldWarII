# WorldWarII — 戰術六角格戰棋

一款以二戰戰術級交戰為主題的回合制六角格戰棋遊戲。重心放在**歷史戰役還原**:玩家在重現自真實戰場(色當、基輔、史達林格勒、庫斯克、突出部)的關卡中指揮裝甲、步兵、砲兵單位完成任務。

技術棧:**Godot 4.x + GDScript**,資料驅動(單位/地形/關卡皆 JSON)。

## 目前狀態(第 1 週進度)

- ✅ 專案骨架、目錄結構、autoload 設定
- ✅ Hex 軸向座標數學 (`scripts/grid/hex_coord.gd`) + 單元測試
- ✅ JSON 資料載入器 + 單位/地形型錄
- ✅ Hex 地圖渲染 (`scripts/grid/hex_map.gd`,Polygon2D)
- ✅ 攝影機平移/縮放/拖曳
- ✅ 點擊 hex 顯示座標 + 地形資訊
- ⏳ Week 2 起:單位、移動範圍、戰鬥、AI、戰役

完整實作計畫:[CLAUDE plan file](/home/fischer/.claude/plans/ww2-mellow-river.md)(本機)

## 執行

需要先安裝 Godot 4.2+。

```bash
# 1) 用 Godot 編輯器開啟 project.godot
godot --editor project.godot

# 2) 直接執行主場景
godot project.godot

# 3) 執行 hex 座標單元測試
godot --headless --script res://tests/test_hex_coord.gd
```

操作:
- **WASD / 方向鍵**: 攝影機平移
- **滾輪**: 縮放
- **中鍵拖曳**: 拖動視野
- **左鍵**: 點選 hex 看資訊

## 專案結構

```
assets/      美術資產(後期使用 Kenney CC0)
data/        JSON 資料(units / terrains / scenarios)
scenes/      Godot 場景檔
scripts/     GDScript
  autoload/    全域 singleton(DataLoader / GameState)
  grid/        六角格座標、地圖、尋路
  units/       單位邏輯
  combat/      戰鬥解算
  turn/        回合管理、AI
  scenario/    關卡載入、勝負判定
  ui/          UI 控制
tests/       獨立 GDScript 測試
```

## 設計檔案

- [data/terrains.json](data/terrains.json) — 平原、森林、山地、城鎮、河流、道路;`move_cost`/`defense`/`blocks_los`
- [data/units.json](data/units.json) — 步兵、機槍、反戰車砲、輕/中戰車、砲兵;`hp`/`attack`/`defense`/`range`/`move`/`vs_armor`/`armor`
- [data/scenarios/00_sandbox.json](data/scenarios/00_sandbox.json) — 測試用 10x8 沙盒地圖
