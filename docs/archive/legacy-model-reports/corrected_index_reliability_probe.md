# Corrected-text index self-report reliability

Model: `gpt-5.5`  
Generated: 2026-06-18T23:24:38.911154

Question: are the model's self-reported corrected_text positions accurate (slice == corrected_phrase)?

| case type | sentence id | corrected_phrase | reported [cs,ce) | slice at that index | match? | offset |
| --- | --- | --- | --- | --- | --- | --- |
| silent-edit / repeated-word | silent-edit-volvi | `a` | [139,140) | `a` | ✅ | 0 |
| repeated-word | repeated-word-banco | `al` | [4,6) | `al` | ✅ | 0 |
| repeated-word | repeated-word-banco | `del` | [19,22) | `del` | ✅ | 0 |
| single-char | single-char-a | `a` | [31,32) | `a` | ✅ | 0 |
| single-char / accented | single-char-accent-ano | `España` | [8,14) | `España` | ✅ | 0 |
| single-char / accented | single-char-accent-ano | `años` | [31,35) | `años` | ✅ | 0 |
| accented | accented-habia | `había` | [5,10) | `había` | ✅ | 0 |
| accented | accented-habia | `tráfico` | [17,24) | `tráfico` | ✅ | 0 |
| multi-correction | multi-correction-trip | `fui` | [14,17) | `fui` | ✅ | 0 |
| multi-correction | multi-correction-trip | `México` | [20,26) | `México` | ✅ | 0 |
| multi-correction | multi-correction-trip | `comimos` | [44,51) | `comimos` | ✅ | 0 |
| multi-correction | multi-correction-trip | `mucha` | [52,57) | `mucha` | ✅ | 0 |
| multi-correction | multi-correction-trip | `típica` | [65,71) | `típica` | ✅ | 0 |

## Accuracy

Overall: 13 / 13 correct (100%)

| case type | correct / total |
| --- | --- |
| silent-edit / repeated-word | 1 / 1 |
| repeated-word | 2 / 2 |
| single-char | 1 / 1 |
| single-char / accented | 2 / 2 |
| accented | 2 / 2 |
| multi-correction | 5 / 5 |

---

### silent-edit-volvi  (silent-edit / repeated-word)

- Sentence: `Ayer fui al supermercado para comprar fruta y leche. Había mucha gente, pero encontré todo rápidamente. Después, pagué mis compras y volví para casa para preparar la cena.`
- Note: Bug 1 scenario: "para" appears 3x; the only error is "volví para casa" -> "volví a casa". The model may also tidy "para comprar" without itemising it.
- corrected_text: `Ayer fui al supermercado para comprar fruta y leche. Había mucha gente, pero encontré todo rápidamente. Después, pagué mis compras y volví a casa para preparar la cena.`

  - `a` -> reported [139,140), slice `a` OK

### repeated-word-banco  (repeated-word)

- Sentence: `Fui a el banco cerca de el parque para sacar dinero esta mañana.`
- Note: Repeated "el" / "a el" -> "al": positions must pick the RIGHT occurrence.
- corrected_text: `Fui al banco cerca del parque para sacar dinero esta mañana.`

  - `al` -> reported [4,6), slice `al` OK
  - `del` -> reported [19,22), slice `del` OK

### single-char-a  (single-char)

- Sentence: `Cuando termino el trabajo, voy para casa en autobús.`
- Note: Single-character corrected phrase "a" (para -> a). The hard case.
- corrected_text: `Cuando termino el trabajo, voy a casa en autobús.`

  - `a` -> reported [31,32), slice `a` OK

### single-char-accent-ano  (single-char / accented)

- Sentence: `Vivo en Espana desde hace tres anos y medio.`
- Note: Adds ñ to "Espana"->"España" and "anos"->"años": tests whether the model counts ñ as one user-perceived character the way the app does.
- corrected_text: `Vivo en España desde hace tres años y medio.`

  - `España` -> reported [8,14), slice `España` OK
  - `años` -> reported [31,35), slice `años` OK

### accented-habia  (accented)

- Sentence: `Ayer habia mucho trafico en el centro de la ciudad.`
- Note: Accent restorations "habia"->"había", "trafico"->"tráfico": corrected phrases contain accented graphemes mid-string.
- corrected_text: `Ayer había mucho tráfico en el centro de la ciudad.`

  - `había` -> reported [5,10), slice `había` OK
  - `tráfico` -> reported [17,24), slice `tráfico` OK

### multi-correction-trip  (multi-correction)

- Sentence: `El año pasado yo va a Mexico con mi familia y nosotros comemos mucho comida tipico en muchos restaurantes.`
- Note: 4+ errors (va->fui/iba, Mexico->México, mucho comida->mucha comida, tipico->típica): do positions stay accurate late in the string?
- corrected_text: `El año pasado fui a México con mi familia y comimos mucha comida típica en muchos restaurantes.`

  - `fui` -> reported [14,17), slice `fui` OK
  - `México` -> reported [20,26), slice `México` OK
  - `comimos` -> reported [44,51), slice `comimos` OK
  - `mucha` -> reported [52,57), slice `mucha` OK
  - `típica` -> reported [65,71), slice `típica` OK

