# TypeScript Parser: Union を最外層で左結合に統一する改修メモ

目的: 残存している「union of objects」失敗を、Union を「外側の層」で左結合に統一する最小改修で解消する。既存の P0/P0b の方針維持・回帰ゼロを前提。

対象と現状

- 残失敗テスト: src/typesrcipt_parser/export_type_test.mbt:46 の "parse type alias with union of objects"
- 改修対象関数:
  - parse_type() at src/typesrcipt_parser/parser.mbt:52
  - parse_non_union_type() at src/typesrcipt_parser/parser.mbt:95
  - parse_object_type() at src/typesrcipt_parser/parser.mbt:207（必要に応じてセパレータ消費の厳密化のみ）

現状の挙動の要点（確認済み）

- parse_type は最外層で Union を扱う実装になっているが、'|' 検出に current と peek の双方を用い、その場で正規化しつつループしている。
- parse_non_union_type は Primary（Tuple/Literal/TypeRef/Parenthesized/Function/Object）+ 後置配列 T[] を処理。Primary の多くは終端を呼び出し側に委譲という方針。
- parse_object_type はプロパティの型を parse_type() で読み取った後に self.next_token() で「型の直後に一歩進む」処理が入っている。この一歩が '}' や次のセパレータを跨ぐことで、上位で想定する区切り位置とズレる可能性がある。

問題の仮説

- オブジェクトプロパティの「型」直後に設けている self.next_token() が、'|' をまたいだり、'}' を跨いだりしてしまうケースがあり、最外層 Union のトークナイズ位置が崩れている疑い。
- また、parse_type 側の '|' 判定で peek を広く使うことにより「右辺の先頭に入る前進量」との不整合が起きやすい。

最小改修方針（P0）

1. Union の外側化と左結合ループの単純化

   - parse_type(): left = parse_non_union_type(); while current == '|' { advance; right = parse_non_union_type(); types.push(right) } return Union(types?) を徹底
   - 右辺は常に parse_non_union_type() を呼ぶ。ループ内で parse_type() を再帰させない。
   - '|' 判定は基本 current ベース。必要な場合にのみ peek を 1 回用いて current を '|' に正規化（ズレの抑制）。

2. 非 Union 側の境界整合

   - parse_non_union_type(): Primary/後置配列を読み、'|', '}', ']', ')', ',', ';' など上位区切りに達したら戻る。余計に next_token しない。
   - parse_object_type(): プロパティの型読み取り後の self.next_token() を削除。区切り（, ;）のみを消費し、'}' は消費しないことを厳密化。

3. トークン前進規約の統一
   - Primary 直後は current が演算子（'|' など）または終端/区切りを指す状態に収束するよう、不要な next_token を排除する。
   - '|' 判定は current ベース。必要な場面のみ peek で整合。

予定パッチ概要

- src/typesrcipt_parser/parser.mbt:52 parse_type() を次の単純ループに置換：

  擬似コード
  left0 = parse_non_union_type()
  types = [left0]
  loop:
  if current == '|':
  next_token() // consume '|'
  rhs = parse_non_union_type()
  if rhs is None: break
  types.push(rhs)
  continue
  elif peek == '|':
  next_token() // normalize current to '|'
  continue
  else:
  break
  return Union(types) if types.len > 1 else types[0]

- src/typesrcipt_parser/parser.mbt:207 parse_object_type() のプロパティ型読取後にある self.next_token() を削除し、セパレータ（, ;）のみを消費。'}' は消費しない。

用意済みの差分（適用予定）

1. parse_type() の置換
   開始行目安: src/typesrcipt_parser/parser.mbt:52
   変更点: '|' の検出ロジックを current 基準のループに縮約。右辺は parse_non_union_type() 固定。

2. parse_object_type() のセパレータ厳密化
   開始行目安: src/typesrcipt_parser/parser.mbt:227 および 235 付近
   変更点: プロパティ型読取後の self.next_token() を削除。区切り（, ;）のみに反応し、'}' は消費しない。

テスト計画

- パッケージ単体: moon test -p typesrcipt_parser
- ルート全体: moon test
  期待: 失敗 0。特に src/typesrcipt_parser/export_type_test.mbt:46 の "union of objects" を通過。

ロールバック指針

- 変更は parse_type / parse_object_type の最小範囲に限定。差分適用で不具合が出た場合は、self.next_token の削除部分のみを元に戻して、現象の再現性を比較。

補足（現状コードの該当箇所）

- parse_type() 先頭: src/typesrcipt_parser/parser.mbt:52
- parse_non_union_type() 先頭: src/typesrcipt_parser/parser.mbt:95
- parse_object_type() 先頭: src/typesrcipt_parser/parser.mbt:207（プロパティ型後の self.next_token() は 230 行付近）

実施ステップ（再開時の作業順）

1. parse_type() を上記ループに置換
2. parse_object_type() の self.next_token() を削除し、セパレータ処理を厳密化
3. moon test -p typesrcipt_parser を実行し、失敗が残れば current/peek の整合を再点検
4. moon test でルート全体を確認（回帰ゼロ）

ステータス

- 改修設計: 完了（本メモ）
- 差分: 準備済み（適用は保留）
- 実装/テスト: 未実施（次回再開時に即時実行可）
