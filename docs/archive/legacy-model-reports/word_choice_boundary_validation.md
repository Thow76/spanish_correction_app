# Word Choice vs. Natural Language Boundary Validation

Model: `gpt-5.5`  
Generated: 2026-06-17T22:18:42.108701

| id | sentence | target | expected | actual | result |
| --- | --- | --- | --- | --- | --- |
| es-wc-falsefriend-realice | Cuando llegué a casa, realicé que había olvidado las llaves. | realicé | Word Choice | Natural Language | ❌ |
| es-wc-falsefriend-atender | Mañana tengo que atender una clase de historia en la universidad. | atender | Word Choice | Word Choice | ✅ |
| es-nl-phrase-buen-tiempo | Tuvimos un buen tiempo en la fiesta de cumpleaños anoche. | Tuvimos | Natural Language | Natural Language | ✅ |
| es-nl-phrase-cerveza | ¿Puedo tener una cerveza, por favor? | tener | Natural Language | Natural Language | ✅ |
| es-register-guard-guay | La fiesta de anoche estuvo muy guay, lo pasamos genial. | guay | (no flag) | (not flagged) | ✅ |
| es-grammar-guard-conjugation | Ayer yo va al mercado para comprar verduras frescas. | va | Grammar | Grammar | ✅ |
| es-spelling-guard-manana | Voy a la playa con mis amigos manana por la tarde. | manana | Spelling | Spelling | ✅ |
| es-calque-cafe | ¿Puedo tener un café, por favor? | tener | Natural Language | Natural Language | ✅ |
| es-calque-cita | Necesito hacer una cita con el médico para la próxima semana. | hacer una cita | Natural Language | Natural Language | ✅ |
| es-calque-para-atras | Te voy a llamar para atrás esta tarde cuando llegue. | para atrás | Natural Language | Natural Language | ✅ |
| es-calque-cuidado | Tienes que tomar mejor cuidado de tu salud. | cuidado | Natural Language | Natural Language | ✅ |
| es-calque-tome-silla | Cuando entré a la sala de espera, tomé silla cerca de la puerta. | tomé silla | Natural Language | Natural Language | ✅ |
| es-fp-me-sente | Me senté cerca de la ventana para ver mejor el paisaje. | senté | (no flag) | (not flagged) | ✅ |
| es-fp-lo-pase-bien | Lo pasé muy bien en la fiesta de anoche con mis amigos. | pasé | (no flag) | (not flagged) | ✅ |
| es-fp-pedi-cita | Pedí cita con el médico para el lunes por la mañana. | cita | (no flag) | (not flagged) | ✅ |
| es-fp-final-del-dia-literal | Volví a casa al final del día porque estaba muy cansado. | al final del día | (no flag) | (not flagged) | ✅ |
| pt-wc-falsefriend-realizei | Quando cheguei em casa, realizei que tinha esquecido as chaves. | realizei | Word Choice | Word Choice | ✅ |
| pt-wc-anglicism-deletar | Preciso deletar esse arquivo antigo do meu computador hoje. | deletar | Word Choice | Word Choice | ✅ |
| pt-nl-phrase-fim-do-dia | No final do dia, o que realmente importa é a saúde da família. | No final do dia | Natural Language | Natural Language | ✅ |
| pt-register-guard-legal | Achei o show de ontem muito legal, foi bem divertido. | legal | (no flag) | (not flagged) | ✅ |
| pt-grammar-guard-conjugation | Ontem eu vai ao mercado para comprar frutas e legumes. | vai | Grammar | Grammar | ✅ |
| pt-spelling-guard-proximo | Vou viajar para o Brasil no proximo mes com a minha familia. | proximo | Spelling | Spelling | ✅ |

Cases: 22 · Pass: 21 · Fail: 1 · Grader errors: 0

---

### es-wc-falsefriend-realice  ❌

- Language: spanish
- Sentence: `Cuando llegué a casa, realicé que había olvidado las llaves.`
- Target: `realicé`
- Expected: **Word Choice** · Actual: **Natural Language**
- All corrections: Natural Language:"realicé que"->"me di cuenta de que"
- Note: Single-word false friend "realicé" (= I realised) -> Word Choice.

### es-wc-falsefriend-atender  ✅

- Language: spanish
- Sentence: `Mañana tengo que atender una clase de historia en la universidad.`
- Target: `atender`
- Expected: **Word Choice** · Actual: **Word Choice**
- All corrections: Word Choice:"atender"->"asistir"; Grammar:""->"a "
- Note: Single-word false friend "atender" (= to attend) -> Word Choice.

### es-nl-phrase-buen-tiempo  ✅

- Language: spanish
- Sentence: `Tuvimos un buen tiempo en la fiesta de cumpleaños anoche.`
- Target: `Tuvimos`
- Expected: **Natural Language** · Actual: **Natural Language**
- All corrections: Natural Language:"Tuvimos un buen tiempo"->"Lo pasamos bien"
- Note: English calque "tener un buen tiempo" (= have a good time); a native restructures to "lo pasamos bien" -> Natural Language (phrase, no single-word fix).

### es-nl-phrase-cerveza  ✅

- Language: spanish
- Sentence: `¿Puedo tener una cerveza, por favor?`
- Target: `tener`
- Expected: **Natural Language** · Actual: **Natural Language**
- All corrections: Natural Language:"Puedo tener"->"Me pone"
- Note: English request calque "Puedo tener una cerveza" (= can I have a beer); native restructures the request ("¿Me pones/das una cerveza?") -> Natural Language. GPT-4.1-mini flagged nothing here.

### es-register-guard-guay  ✅

- Language: spanish
- Sentence: `La fiesta de anoche estuvo muy guay, lo pasamos genial.`
- Target: `guay`
- Expected: **(no flag)** · Actual: **(not flagged)**
- All corrections: (none)
- Note: Colloquial-but-correct "guay" (= cool) must NOT be flagged on register grounds.

### es-grammar-guard-conjugation  ✅

- Language: spanish
- Sentence: `Ayer yo va al mercado para comprar verduras frescas.`
- Target: `va`
- Expected: **Grammar** · Actual: **Grammar**
- All corrections: Grammar:"yo va"->"fui"
- Note: Wrong conjugation "yo va" (should be "fui") -> Grammar, NOT WC/NL.

### es-spelling-guard-manana  ✅

- Language: spanish
- Sentence: `Voy a la playa con mis amigos manana por la tarde.`
- Target: `manana`
- Expected: **Spelling** · Actual: **Spelling**
- All corrections: Spelling:"manana"->"mañana"
- Note: Misspelling "manana" (should be "mañana") -> Spelling, NOT WC/NL.

### es-calque-cafe  ✅

- Language: spanish
- Sentence: `¿Puedo tener un café, por favor?`
- Target: `tener`
- Expected: **Natural Language** · Actual: **Natural Language**
- All corrections: Natural Language:"Puedo tener"->"Me pone"
- Note: Request calque "puedo tener un café" -> "¿me pone un café?" -> NL.

### es-calque-cita  ✅

- Language: spanish
- Sentence: `Necesito hacer una cita con el médico para la próxima semana.`
- Target: `hacer una cita`
- Expected: **Natural Language** · Actual: **Natural Language**
- All corrections: Natural Language:"hacer una cita"->"pedir cita"
- Note: Calque "hacer una cita" -> "pedir cita" / "pedir hora" -> NL.

### es-calque-para-atras  ✅

- Language: spanish
- Sentence: `Te voy a llamar para atrás esta tarde cuando llegue.`
- Target: `para atrás`
- Expected: **Natural Language** · Actual: **Natural Language**
- All corrections: Natural Language:"llamar para atrás"->"devolver la llamada"
- Note: Calque "llamar para atrás" -> "devolver la llamada" -> NL.

### es-calque-cuidado  ✅

- Language: spanish
- Sentence: `Tienes que tomar mejor cuidado de tu salud.`
- Target: `cuidado`
- Expected: **Natural Language** · Actual: **Natural Language**
- All corrections: Natural Language:"tomar mejor cuidado de tu salud"->"cuidar mejor tu salud"
- Note: Calque "tomar cuidado de" -> "cuidar (mejor)" -> NL.

### es-calque-tome-silla  ✅

- Language: spanish
- Sentence: `Cuando entré a la sala de espera, tomé silla cerca de la puerta.`
- Target: `tomé silla`
- Expected: **Natural Language** · Actual: **Natural Language**
- All corrections: Natural Language:"tomé silla"->"me senté"
- Note: Calque "tomé silla" -> "me senté" / "tomé asiento" -> NL.

### es-fp-me-sente  ✅

- Language: spanish
- Sentence: `Me senté cerca de la ventana para ver mejor el paisaje.`
- Target: `senté`
- Expected: **(no flag)** · Actual: **(not flagged)**
- All corrections: (none)
- Note: Correct Spanish "me senté" must NOT be flagged.

### es-fp-lo-pase-bien  ✅

- Language: spanish
- Sentence: `Lo pasé muy bien en la fiesta de anoche con mis amigos.`
- Target: `pasé`
- Expected: **(no flag)** · Actual: **(not flagged)**
- All corrections: (none)
- Note: Correct Spanish "lo pasé bien" must NOT be flagged.

### es-fp-pedi-cita  ✅

- Language: spanish
- Sentence: `Pedí cita con el médico para el lunes por la mañana.`
- Target: `cita`
- Expected: **(no flag)** · Actual: **(not flagged)**
- All corrections: (none)
- Note: Correct Spanish "pedí cita" must NOT be flagged.

### es-fp-final-del-dia-literal  ✅

- Language: spanish
- Sentence: `Volví a casa al final del día porque estaba muy cansado.`
- Target: `al final del día`
- Expected: **(no flag)** · Actual: **(not flagged)**
- All corrections: (none)
- Note: Literal time-of-day "al final del día" must NOT be flagged on calque grounds.

### pt-wc-falsefriend-realizei  ✅

- Language: portuguese
- Sentence: `Quando cheguei em casa, realizei que tinha esquecido as chaves.`
- Target: `realizei`
- Expected: **Word Choice** · Actual: **Word Choice**
- All corrections: Word Choice:"realizei"->"percebi"
- Note: Single-word false friend "realizei" (= I realised) -> Word Choice.

### pt-wc-anglicism-deletar  ✅

- Language: portuguese
- Sentence: `Preciso deletar esse arquivo antigo do meu computador hoje.`
- Target: `deletar`
- Expected: **Word Choice** · Actual: **Word Choice**
- All corrections: Word Choice:"deletar"->"excluir"
- Note: Single-word anglicism "deletar" (native: excluir/apagar) -> Word Choice.

### pt-nl-phrase-fim-do-dia  ✅

- Language: portuguese
- Sentence: `No final do dia, o que realmente importa é a saúde da família.`
- Target: `No final do dia`
- Expected: **Natural Language** · Actual: **Natural Language**
- All corrections: Natural Language:"No final do dia"->"No fim das contas"
- Note: Figurative calque phrase "no final do dia" (= at the end of the day) -> Natural Language.

### pt-register-guard-legal  ✅

- Language: portuguese
- Sentence: `Achei o show de ontem muito legal, foi bem divertido.`
- Target: `legal`
- Expected: **(no flag)** · Actual: **(not flagged)**
- All corrections: (none)
- Note: Colloquial-but-correct "legal" (= nice/cool) must NOT be flagged on register grounds.

### pt-grammar-guard-conjugation  ✅

- Language: portuguese
- Sentence: `Ontem eu vai ao mercado para comprar frutas e legumes.`
- Target: `vai`
- Expected: **Grammar** · Actual: **Grammar**
- All corrections: Grammar:"vai"->"fui"
- Note: Wrong conjugation "eu vai" (should be "fui") -> Grammar, NOT WC/NL.

### pt-spelling-guard-proximo  ✅

- Language: portuguese
- Sentence: `Vou viajar para o Brasil no proximo mes com a minha familia.`
- Target: `proximo`
- Expected: **Spelling** · Actual: **Spelling**
- All corrections: Spelling:"proximo"->"próximo"; Spelling:"mes"->"mês"; Spelling:"familia"->"família"
- Note: Misspelling "proximo" (should be "próximo") -> Spelling, NOT WC/NL.

