## CipherLib.gd
## 모든 암호/복호화 알고리즘을 담은 순수 함수 라이브러리.
## GameManager 또는 각 해독기 씬에서 autoload("CipherLib")로 호출.
extends Node

# ───────────────────────────────────────────────
#  에니그마 머신 상수 데이터
# ───────────────────────────────────────────────

const ROTOR_WIRING: Dictionary = {
	"I":   "EKMFLGDQVZNTOWYHXUSPAIBRCJ",
	"II":  "AJDKSIRUXBLHWTMCQGZNPYFVOE",
	"III": "BDFHJLCPRTXVZNYEIWGAKMUSQO",
	"IV":  "ESOVPZJAYQUIRHXLNFTGKDCMWB",
	"V":   "VZBRGITYUPSDNHLXAWMJQOFECK",
}

## 각 로터의 노치 위치 (이 위치에서 왼쪽 로터가 한 칸 전진)
const ROTOR_NOTCH: Dictionary = {
	"I":   "Q",
	"II":  "E",
	"III": "V",
	"IV":  "J",
	"V":   "Z",
}

const REFLECTOR_WIRING: Dictionary = {
	"A": "EJMZALYXVBWFCRQUONTSPIKHGD",
	"B": "YRUHQSLDPXNGOKMIEBFZCWVJAT",
}

## 영어 알파벳 빈도 순서 (높은 빈도 → 낮은 빈도)
const ENGLISH_FREQ_ORDER: String = "ETAOINSHRDLCUMWFGYPBVKJXQZ"


# ───────────────────────────────────────────────
#  1. 시저 암호 (Caesar Cipher)
# ───────────────────────────────────────────────

## ── 통합 암호화 진입점 ──────────────────────────────────────
## 평문을 받아 cipher_type + params 에 따라 암호문을 반환한다.
## GameManager.load_level() 에서 런타임 cipher_text 생성에 사용.
func encrypt(plain: String, cipher_type: String, params: Dictionary) -> String:
	match cipher_type:
		"caesar":
			return caesar_encode(
				plain,
				params.get("shift", 3),
				params.get("shift_right", true)
			)
		"vigenere":
			return vigenere_encode(plain, params.get("key", "A"))
		"substitution":
			return substitution_encode(plain, params.get("map", {}))
		"enigma":
			return enigma_process(
				plain,
				params.get("rotors",          ["I", "II", "III"]),
				params.get("rotor_positions", [0, 0, 0]),
				params.get("reflector",       "B"),
				params.get("plugboard",       {})
			)
		"playfair":
			return playfair_process(plain, params.get("key", "KEY"), true)
	return plain


## cipher     : 암호문 (대·소문자 모두 허용, 공백·특수문자 보존)
## shift      : 이동 칸 수 (0~25)
## shift_right: true → 오른쪽 이동으로 암호화 (복호 시 왼쪽), false → 반대
func caesar_decode(cipher: String, shift: int, shift_right: bool) -> String:
	var result := ""
	var s := shift % 26
	if not shift_right:
		s = (26 - s) % 26   # 방향 반전

	for ch in cipher.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			result += char((code - 65 - s + 26) % 26 + 65)
		else:
			result += ch
	return result


## 시저 암호화 — decode 의 방향 반전으로 구현
func caesar_encode(plain: String, shift: int, shift_right: bool) -> String:
	return caesar_decode(plain, shift, not shift_right)


# ───────────────────────────────────────────────
#  2. 비즈네르 암호 (Vigenère Cipher)
# ───────────────────────────────────────────────

## key: 키워드 문자열 (알파벳만, 대소문자 무관)
## 공백·특수문자는 키 인덱스를 전진시키지 않고 그대로 출력
func vigenere_decode(cipher: String, key: String) -> String:
	if key.is_empty():
		return cipher

	var clean_key := key.to_upper()
	var result    := ""
	var key_idx   := 0
	var key_len   := clean_key.length()

	for ch in cipher.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			var c     := code - 65
			var k     := clean_key[key_idx % key_len].unicode_at(0) - 65
			var plain := (c - k + 26) % 26
			result   += char(plain + 65)
			key_idx  += 1
		else:
			result += ch
	return result


## 비즈네르 암호화
func vigenere_encode(plain: String, key: String) -> String:
	if key.is_empty():
		return plain

	var clean_key := key.to_upper()
	var result    := ""
	var key_idx   := 0
	var key_len   := clean_key.length()

	for ch in plain.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			var p      := code - 65
			var k      := clean_key[key_idx % key_len].unicode_at(0) - 65
			var cipher := (p + k) % 26
			result   += char(cipher + 65)
			key_idx  += 1
		else:
			result += ch
	return result


## 현재 입력된 키 길이만큼 각 글자가 어느 키 문자에 대응하는지 배열로 반환.
## 반환값: [{"cipher_char": "L", "key_char": "S", "key_pos": 0, "plain_char": "A"}, ...]
## 해독기 UI의 색상 하이라이트에 사용
func vigenere_breakdown(cipher: String, key: String) -> Array:
	if key.is_empty():
		return []

	var clean_key := key.to_upper()
	var key_len   := clean_key.length()
	var key_idx   := 0
	var breakdown : Array = []

	for ch in cipher.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			var c     := code - 65
			var k     := clean_key[key_idx % key_len].unicode_at(0) - 65
			var plain := (c - k + 26) % 26
			breakdown.append({
				"cipher_char": ch,
				"key_char":    clean_key[key_idx % key_len],
				"key_pos":     key_idx % key_len,
				"plain_char":  char(plain + 65),
			})
			key_idx += 1
		else:
			breakdown.append({
				"cipher_char": ch,
				"key_char":    "",
				"key_pos":     -1,
				"plain_char":  ch,
			})
	return breakdown


# ───────────────────────────────────────────────
#  3. 단일 치환 암호 (Monoalphabetic Substitution)
# ───────────────────────────────────────────────

## plain→cipher 맵으로 평문을 암호화
## map: {"A": "W", "B": "O", ...}  평문 글자 → 암호 글자
## 맵에 없는 글자는 그대로 출력
func substitution_encode(plain: String, map: Dictionary) -> String:
	var result := ""
	for ch in plain.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			result += map.get(ch, ch)
		else:
			result += ch
	return result


## mapping: {"A": "T", "B": "H", ...}  암호 글자 → 평문 글자
## 매핑이 없는 글자는 '_' 로 표시 (아직 해독 안 됨을 시각화)
func substitution_decode(cipher: String, mapping: Dictionary) -> String:
	var result := ""
	for ch in cipher.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			result += mapping.get(ch, "_")
		else:
			result += ch
	return result


## 텍스트에서 알파벳 빈도를 계산해 {글자: 횟수} 딕셔너리 반환
func frequency_analysis(text: String) -> Dictionary:
	var freq: Dictionary = {}
	for ch in text.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			freq[ch] = freq.get(ch, 0) + 1
	return freq


## 빈도 분석 결과를 횟수 내림차순으로 정렬한 배열 반환
## [{"char": "X", "count": 12}, ...]
func frequency_sorted(text: String) -> Array:
	var freq  := frequency_analysis(text)
	var pairs : Array = []
	for ch in freq:
		pairs.append({"char": ch, "count": freq[ch]})
	pairs.sort_custom(func(a, b): return a["count"] > b["count"])
	return pairs


# ───────────────────────────────────────────────
#  4. 에니그마 머신 (Enigma Machine)
# ───────────────────────────────────────────────
# 에니그마는 대칭 암호: encode == decode (같은 설정으로 재입력 시 원문 복원)
#
# rotor_types    : ["I", "II", "III"]  왼쪽→오른쪽 순서
# rotor_positions: [0, 0, 0]           A=0, B=1, ... Z=25
# reflector_type : "A" 또는 "B"
# plugboard      : {"A": "B", "B": "A", ...}  쌍방향으로 저장

func enigma_process(cipher: String, rotor_types: Array, rotor_positions: Array,
		reflector_type: String, plugboard: Dictionary) -> String:

	# 로터 위치 복사 (원본 배열 불변 유지, JSON 파싱 시 float 방지)
	var pos := [int(rotor_positions[0]), int(rotor_positions[1]), int(rotor_positions[2])]
	var result := ""

	for ch in cipher.to_upper():
		var code := ch.unicode_at(0)
		if code < 65 or code > 90:
			result += ch
			continue

		# ── 로터 스텝 (키 입력 전에 전진) ──
		var r_notch :int= ROTOR_NOTCH[rotor_types[2]].unicode_at(0) - 65
		var m_notch :int= ROTOR_NOTCH[rotor_types[1]].unicode_at(0) - 65

		if pos[1] == m_notch:          # 더블 스텝 이상 현상
			pos[0] = (pos[0] + 1) % 26
			pos[1] = (pos[1] + 1) % 26
		elif pos[2] == r_notch:        # 오른쪽 노치 → 가운데 전진
			pos[1] = (pos[1] + 1) % 26
		pos[2] = (pos[2] + 1) % 26    # 오른쪽 항상 전진

		var sig := code - 65

		# ── 플러그보드 입력 ──
		var ch_str := char(sig + 65)
		if plugboard.has(ch_str):
			sig = plugboard[ch_str].unicode_at(0) - 65

		# ── 로터 순방향 (오른쪽 → 가운데 → 왼쪽) ──
		sig = _rotor_fwd(ROTOR_WIRING[rotor_types[2]], pos[2], sig)
		sig = _rotor_fwd(ROTOR_WIRING[rotor_types[1]], pos[1], sig)
		sig = _rotor_fwd(ROTOR_WIRING[rotor_types[0]], pos[0], sig)

		# ── 반사판 ──
		sig = REFLECTOR_WIRING[reflector_type][sig].unicode_at(0) - 65

		# ── 로터 역방향 (왼쪽 → 가운데 → 오른쪽) ──
		sig = _rotor_bwd(ROTOR_WIRING[rotor_types[0]], pos[0], sig)
		sig = _rotor_bwd(ROTOR_WIRING[rotor_types[1]], pos[1], sig)
		sig = _rotor_bwd(ROTOR_WIRING[rotor_types[2]], pos[2], sig)

		# ── 플러그보드 출력 ──
		var out_ch := char(sig + 65)
		if plugboard.has(out_ch):
			out_ch = plugboard[out_ch]

		result += out_ch

	return result


## 로터 순방향 통과: 오른쪽 접점 → 왼쪽 접점
func _rotor_fwd(wiring: String, pos: int, sig: int) -> int:
	var entry    := (sig + pos) % 26
	var exit_val := wiring[entry].unicode_at(0) - 65
	return (exit_val - pos + 26) % 26


## 로터 역방향 통과: 왼쪽 접점 → 오른쪽 접점 (역 치환)
func _rotor_bwd(wiring: String, pos: int, sig: int) -> int:
	var entry    := (sig + pos) % 26
	var exit_pos := wiring.find(char(entry + 65))
	return (exit_pos - pos + 26) % 26


# ───────────────────────────────────────────────
#  5. 플레이페어 암호 (Playfair Cipher)
# ───────────────────────────────────────────────
# 5×5 격자 기반 이중자(digraph) 치환 암호.
# I/J 통합. 암호화와 복호화 모두 같은 함수로 처리 (encrypt 플래그).
#
# key       : 격자 키워드 (중복 제거, 나머지 알파벳 순 채움)
# text      : 처리할 텍스트 (알파벳만 추출, 대문자 정규화)
# encrypt   : true → 암호화, false → 복호화

func playfair_process(text: String, key: String, encrypt: bool) -> String:
	var grid := _playfair_build_grid(key)
	var pos  := _playfair_positions(grid)
	var prep := _playfair_prepare(text)
	var result := ""
	var dir  := 1 if encrypt else -1

	var i := 0
	while i < prep.length() - 1:
		var a : String = prep[i]
		var b : String = prep[i + 1]
		var ra : int = pos[a][0];  var ca : int = pos[a][1]
		var rb : int = pos[b][0];  var cb : int = pos[b][1]

		if ra == rb:
			# 같은 행 → 열 방향 이동
			result += grid[ra][(ca + dir + 5) % 5]
			result += grid[rb][(cb + dir + 5) % 5]
		elif ca == cb:
			# 같은 열 → 행 방향 이동
			result += grid[(ra + dir + 5) % 5][ca]
			result += grid[(rb + dir + 5) % 5][cb]
		else:
			# 사각형 → 열 교환
			result += grid[ra][cb]
			result += grid[rb][ca]
		i += 2

	return result


## 키워드로 5×5 격자 생성 (I/J 통합, 중복 제거)
func _playfair_build_grid(key: String) -> Array:
	var used  : Dictionary = {}
	var order : Array      = []

	for ch in (key.to_upper() + "ABCDEFGHIJKLMNOPQRSTUVWXYZ"):
		var c : String = ch
		if c == "J":
			c = "I"
		if not used.has(c):
			used[c] = true
			order.append(c)

	var grid : Array = []
	for r in 5:
		var row : Array = []
		for col in 5:
			row.append(order[r * 5 + col])
		grid.append(row)
	return grid


## 격자에서 각 글자의 (행, 열) 위치를 딕셔너리로 반환
func _playfair_positions(grid: Array) -> Dictionary:
	var pos : Dictionary = {}
	for r in 5:
		for c in 5:
			var ch : String = grid[r][c]
			pos[ch] = [r, c]
	pos["J"] = pos.get("I", [0, 0])   # J → I 위치 동일
	return pos


## 평문을 이중자 처리용 문자열로 변환
## 1) 알파벳만 추출, 대문자, J→I
## 2) 같은 글자가 연속되면 X 삽입
## 3) 홀수 길이이면 X 추가
func _playfair_prepare(text: String) -> String:
	# 1) 정규화
	var clean := ""
	for ch in text.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			clean += "I" if ch == "J" else ch

	# 2) 이중자 분할 — 같은 글자 연속 시 X 삽입
	var out := ""
	var idx := 0
	while idx < clean.length():
		var first : String = clean[idx]
		out += first
		idx += 1
		if idx < clean.length():
			var second : String = clean[idx]
			if first == second:
				out += "X"
			else:
				out += second
				idx += 1
		# 홀수 처리는 3단계에서

	# 3) 홀수 길이 패딩
	if out.length() % 2 != 0:
		out += "X"

	return out


# ───────────────────────────────────────────────
#  유틸리티
# ───────────────────────────────────────────────

## 텍스트에서 알파벳만 추출 (공백·특수문자 제거, 대문자 통일)
func strip_to_alpha(text: String) -> String:
	var result := ""
	for ch in text.to_upper():
		var code := ch.unicode_at(0)
		if code >= 65 and code <= 90:
			result += ch
	return result


## 두 문자열이 알파벳 기준으로 일치하는지 비교 (공백·대소문자 무시)
func alpha_match(a: String, b: String) -> bool:
	return strip_to_alpha(a) == strip_to_alpha(b)
