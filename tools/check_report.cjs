// 보고서 문항 점검: 해독하지 않고도 선택지만 보고 답이 보이는 곳을 찾는다.
//   node tools/check_report.cjs
// 게임이 읽는 레벨 파일(data/chapters/chapter_00_01.json 꼴)만 본다. 번호가 하나뿐인 chapter_00.json 꼴은 쓰이지 않는 옛 파일이다.
//
// 1. 정답이 선택지 안에 있고, 평문의 한 단어이며, 선택지가 서로 다르다.
// 2. 카이사르, 비즈네르, 치환, 에니그마는 암호문에 단어 경계가 그대로 남는다. 그래서 선택지 넷의 글자 수가 정답과 모두 같아야 한다.
//    플레이페어는 공백을 지우고 두 글자씩 묶으므로 경계가 안 보인다. 대신 정답만 글자 수가 다른 선택지가 되면 안 된다.
// 3. 오답 전용 피드백과 가짜 단서 오답이 지금 선택지에 있는 단어를 가리킨다(선택지를 바꾸고 피드백을 두고 오는 실수를 막는다).
// 질문 문장이 다른 문항의 답을 우리말로 알려 주는지는 기계로 잡지 못한다. known-issues.md #1 을 보고 사람이 읽는다.
const fs = require('fs');
const path = require('path');

const dir = path.join(__dirname, '..', 'data', 'chapters');
const keepsSpaces = new Set(['caesar', 'vigenere', 'substitution', 'enigma']);
const letters = w => w.replace(/[^A-Z]/gi, '').length;
let fail = 0;
let total = 0;
const bad = (f, q, msg) => { console.log(`FAIL ${f} ${q.id}: ${msg}`); fail++; };

for (const f of fs.readdirSync(dir).filter(n => /^chapter_\d\d_\d\d\.json$/.test(n)).sort()) {
  const level = JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8').replace(/^﻿/, ''));
  const words = String(level.plain_text || '').toUpperCase().split(/\s+/);
  for (const q of level.report_questions || []) {
    total++;
    const choices = (q.choices || []).map(c => String(c).toUpperCase());
    const answer = String(q.answer_key || '').toUpperCase();
    if (choices.length !== 4) bad(f, q, `선택지가 ${choices.length}개`);
    if (new Set(choices).size !== choices.length) bad(f, q, '같은 선택지가 두 번 있음');
    if (!choices.includes(answer)) bad(f, q, `정답 ${answer} 가 선택지에 없음`);
    if (!words.includes(answer)) bad(f, q, `정답 ${answer} 가 평문 "${level.plain_text}" 의 단어가 아님`);

    const n = letters(answer);
    if (keepsSpaces.has(level.cipher_type)) {
      const off = choices.filter(c => letters(c) !== n);
      if (off.length) bad(f, q, `${level.cipher_type} 는 단어 경계가 보이는데 글자 수가 정답(${n})과 다른 선택지: ${off.join(', ')}`);
    } else if (choices.filter(c => letters(c) === n).length === 1) {
      bad(f, q, `정답 ${answer} 만 글자 수가 ${n} 이라 길이로 답이 보임`);
    }

    for (const k of Object.keys(q.specific_wrong_feedback || {})) {
      if (!choices.includes(k.toUpperCase()) || k.toUpperCase() === answer) bad(f, q, `오답 피드백 ${k} 가 지금 선택지의 오답이 아님`);
    }
    for (const k of q.red_herring_answers || []) {
      if (!choices.includes(String(k).toUpperCase())) bad(f, q, `가짜 단서 오답 ${k} 가 선택지에 없음`);
    }
  }
}
console.log(fail ? `문항 ${total}개 중 문제 ${fail}건` : `문항 ${total}개 모두 통과`);
process.exit(fail ? 1 : 0);
