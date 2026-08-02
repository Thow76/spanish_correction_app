# Two-Pass Production-Style Benchmark (issues #97/#98/#101 POC)

Derived from the same live run as `docs/two_pass_integration_harness.md` (diagnostic mode) — no extra API calls. Every fixture below still had naturalness run on both the original and first-pass corrected text so the diagnostic report could compare them; this report instead only counts the second (fallback) naturalness call when `runTwoPassCorrectionPipeline` would actually have made it — i.e. **fallback is conditional here**, only triggered when the parallel merge had a skipped edit, exactly matching production behavior.

**Latency methodology (issue #98)**: the first pass and naturalness-on-original calls are started concurrently — mirroring `runTwoPassCorrectionPipeline`'s own parallel phase. Each per-phrase table below shows "First-pass latency" and "Naturalness (parallel) latency" as each call's own individual latency, for debugging which call is slower — but "Production total latency" uses the real measured concurrent-phase wall-clock time (plus fallback latency, only when fallback actually ran), not a sum of those two per-call figures.

## Run configuration

- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixture selection: all (85 fixtures) (issue #85)
- Fixture count: `85`
- Generated: 2026-08-02T22:29:36.978010Z
- Report layout: one section per benchmark group (language point), each with a readable pass/fail + fallback summary and a per-phrase table (issue #101)

## Accents / Diacritics

6 fixtures — 5 pass / 1 fail. Fallback: 2 not_needed, 1 called_changed_text, 3 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Vi mucho trafico ayer.` | `Vi mucho tráfico ayer.` | `Había mucho tráfico ayer.` | called_changed_text | fail | 1815 | 3438 | 2048 | 5488 | $0.003073 |
| `Voy al parque manana por la tarde.` | `Voy al parque mañana por la tarde.` | `Voy al parque mañana por la tarde.` | not_needed | pass | 745 | 1183 | 0 | 1184 | $0.001044 |
| `El medico llego despues de la reunion.` | `El médico llegó después de la reunión.` | `El médico llegó después de la reunión.` | not_needed | pass | 680 | 984 | 0 | 984 | $0.001047 |
| `Espana es un pais muy diverso.` | `España es un país muy diverso.` | `España es un país muy diverso.` | called_unchanged_clean | pass | 576 | 1601 | 1024 | 2626 | $0.002098 |
| `Mi cumpleanos es en otono.` | `Mi cumpleaños es en otoño.` | `Mi cumpleaños es en otoño.` | called_unchanged_clean | pass | 679 | 2520 | 1024 | 3545 | $0.003099 |
| `Compre cafe en una cafeteria pequena.` | `Compré café en una cafetería pequeña.` | `Compré café en una cafetería pequeña.` | called_unchanged_clean | pass | 674 | 3036 | 1019 | 4055 | $0.003657 |

## Collocations / Strong Calques

6 fixtures — 6 pass / 0 fail. Fallback: 1 not_needed, 5 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Voy a hacer una decisión importante.` | `Voy a tomar una decisión importante.` | `Voy a tomar una decisión importante.` | called_unchanged_clean | pass | 807 | 1789 | 1095 | 2885 | $0.002265 |
| `Necesito hacer una decisión.` | `Necesito tomar una decisión.` | `Necesito tomar una decisión.` | called_unchanged_clean | pass | 576 | 1805 | 1331 | 3136 | $0.002363 |
| `Tenemos que hacer atención.` | `Tenemos que prestar atención.` | `Tenemos que prestar atención.` | called_unchanged_clean | pass | 682 | 2113 | 1024 | 3138 | $0.002200 |
| `El equipo tomó una reunión.` | `El equipo tuvo una reunión.` | `El equipo tuvo una reunión.` | called_unchanged_clean | pass | 594 | 1807 | 920 | 2728 | $0.002402 |
| `Ella hizo un paseo.` | `Ella hizo un paseo.` | `Ella dio un paseo.` | not_needed | pass | 783 | 2162 | 0 | 2163 | $0.001780 |
| `Esto hace sentido.` | `Esto tiene sentido.` | `Esto tiene sentido.` | called_unchanged_clean | pass | 534 | 1711 | 1324 | 3036 | $0.002247 |

## Accents / Diacritics + Collocations / Strong Calques (independent spans)

1 fixture — 1 pass / 0 fail. Fallback: 1 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `El profesor dijo que devia estudiar más, y ella hizo una decisión importante.` | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | `El profesor dijo que debía estudiar más, y ella tomó una decisión importante.` | called_unchanged_clean | pass | 918 | 1469 | 1128 | 2597 | $0.002425 |

## Verb Morphology (spelling) overlapping Collocations / Strong Calques

1 fixture — 1 pass / 0 fail. Fallback: 1 called_changed_text.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Ayer iso una decisión importante.` | `Ayer hizo una decisión importante.` | `Ayer tomó una decisión importante.` | called_changed_text | pass | 570 | 1764 | 1952 | 3717 | $0.003215 |

## Ambiguous / Repeated Span Safety (Naturalness)

1 fixture — 0 pass / 1 fail. Fallback: 1 not_needed.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Vi mucho tráfico, y luego vi más tráfico.` | `Vi mucho tráfico, y luego vi más tráfico.` | `Había mucho tráfico, y luego todavía más.` | not_needed | fail | 672 | 2383 | 0 | 2384 | $0.002086 |

## Gender / Number Agreement

5 fixtures — 5 pass / 0 fail. Fallback: 3 not_needed, 2 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Los niño come muchas manzana.` | `Los niños comen muchas manzanas.` | `Los niños comen muchas manzanas.` | not_needed | pass | 620 | 1110 | 0 | 1111 | $0.001041 |
| `Las ventanas estaban abierto.` | `Las ventanas estaban abiertas.` | `Las ventanas estaban abiertas.` | not_needed | pass | 576 | 1087 | 0 | 1088 | $0.001010 |
| `Una puerta estaba cerrado.` | `Una puerta estaba cerrada.` | `Una puerta estaba cerrada.` | called_unchanged_clean | pass | 682 | 2421 | 1331 | 3753 | $0.002379 |
| `Los billetes estaban caro.` | `Los billetes estaban caros.` | `Los billetes estaban caros.` | not_needed | pass | 577 | 1499 | 0 | 1499 | $0.001021 |
| `Las fechas estaban escrito sin tilde.` | `Las fechas estaban escritas sin tilde.` | `Las fechas estaban escritas sin tilde.` | called_unchanged_clean | pass | 575 | 1650 | 970 | 2621 | $0.002367 |

## Verb Agreement / Morphology

5 fixtures — 5 pass / 0 fail. Fallback: 4 not_needed, 1 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Mis compañeros y yo fue a la biblioteca.` | `Mis compañeros y yo fuimos a la biblioteca.` | `Mis compañeros y yo fuimos a la biblioteca.` | not_needed | pass | 906 | 1106 | 0 | 1107 | $0.001063 |
| `Los niños come en el jardín.` | `Los niños comen en el jardín.` | `Los niños comen en el jardín.` | not_needed | pass | 779 | 1191 | 0 | 1192 | $0.001032 |
| `Yo fui al mercado y compra pan.` | `Yo fui al mercado y compré pan.` | `Yo fui al mercado y compré pan.` | not_needed | pass | 676 | 1393 | 0 | 1394 | $0.001052 |
| `Ellos estudia todas las noches.` | `Ellos estudian todas las noches.` | `Ellos estudian todas las noches.` | not_needed | pass | 686 | 1005 | 0 | 1006 | $0.001044 |
| `Nosotros vive cerca del centro.` | `Nosotros vivimos cerca del centro.` | `Nosotros vivimos cerca del centro.` | called_unchanged_clean | pass | 1192 | 2393 | 1121 | 3515 | $0.002645 |

## Required Prepositions

5 fixtures — 4 pass / 1 fail. Fallback: 1 called_changed_text, 4 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Insisto que revises el contrato.` | `Insisto en que revises el contrato.` | `Insisto en que revises el contrato.` | called_unchanged_clean | pass | 689 | 1909 | 985 | 2895 | $0.002477 |
| `La empresa que trabajo está cerca.` | `La empresa en que trabajo está cerca.` | `La empresa donde trabajo está cerca.` | called_changed_text | fail | 592 | 2356 | 2252 | 4609 | $0.003084 |
| `Dependo que me ayudes mañana.` | `Dependo de que me ayudes mañana.` | `Dependo de que me ayudes mañana.` | called_unchanged_clean | pass | 677 | 2009 | 1022 | 3032 | $0.002447 |
| `Pienso ti todos los días.` | `Pienso en ti todos los días.` | `Pienso en ti todos los días.` | called_unchanged_clean | pass | 581 | 2014 | 1135 | 3150 | $0.002414 |
| `Soñé mi antiguo colegio.` | `Soñé con mi antiguo colegio.` | `Soñé con mi antiguo colegio.` | called_unchanged_clean | pass | 569 | 1899 | 2615 | 4515 | $0.002524 |

## Articles / Determiners

5 fixtures — 3 pass / 2 fail. Fallback: 1 not_needed, 4 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Abrió puerta principal.` | `Abrió la puerta principal.` | `Abrió la puerta principal.` | called_unchanged_clean | pass | 694 | 3289 | 1177 | 4466 | $0.002309 |
| `Necesito comprar libro para la clase.` | `Necesito comprar un libro para la clase.` | `Necesito comprar un libro para la clase.` | called_unchanged_clean | pass | 523 | 2060 | 975 | 3035 | $0.002527 |
| `Profesor explicó regla otra vez.` | `El profesor explicó la regla otra vez.` | `El profesor explicó la regla otra vez.` | called_unchanged_clean | pass | 525 | 1955 | 1367 | 3323 | $0.002351 |
| `Fui a tienda después del trabajo.` | `Fui a la tienda después del trabajo.` | `Fui a la la tienda después del trabajo.` | not_needed | fail | 542 | 2693 | 0 | 2694 | $0.001702 |
| `Tengo cita con médico mañana.` | `Tengo cita con el médico mañana.` | `Tengo cita con el médico mañana.` | called_unchanged_clean | fail | 773 | 1900 | 1332 | 3233 | $0.002252 |

## Subjunctive / Mood

5 fixtures — 4 pass / 1 fail. Fallback: 1 not_needed, 1 called_changed_text, 3 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Es importante que estudias.` | `Es importante que estudies.` | `Es importante que estudies.` | not_needed | pass | 561 | 1143 | 0 | 1144 | $0.001021 |
| `No creo que tiene razón.` | `No creo que tenga razón.` | `No creo que tenga razón.` | called_unchanged_clean | pass | 737 | 2424 | 1125 | 3550 | $0.002543 |
| `Quiero que vienes conmigo.` | `Quiero que vengas conmigo.` | `Quiero que vengas conmigo.` | called_unchanged_clean | pass | 679 | 2728 | 1328 | 4057 | $0.002425 |
| `Era necesario que enviaba su parte.` | `Era necesario que enviara su parte.` | `Era necesario que enviara su informe / su reporte / su formulario (según el contexto).` | called_changed_text | fail | 513 | 2012 | 3993 | 6006 | $0.003758 |
| `Busco a alguien que habla francés.` | `Busco a alguien que hable francés.` | `Busco a alguien que hable francés.` | called_unchanged_clean | pass | 659 | 3722 | 1156 | 4879 | $0.002407 |

## Required Additions / Omissions

5 fixtures — 5 pass / 0 fail. Fallback: 5 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Creo está bien terminar hoy.` | `Creo que está bien terminar hoy.` | `Creo que está bien terminar hoy.` | called_unchanged_clean | pass | 691 | 2114 | 981 | 3095 | $0.002432 |
| `A los niños expliqué la regla.` | `A los niños les expliqué la regla.` | `A los niños les expliqué la regla.` | called_unchanged_clean | pass | 619 | 1985 | 1162 | 3147 | $0.002434 |
| `Vi mi profesor en la estación.` | `Vi a mi profesor en la estación.` | `Vi a mi profesor en la estación.` | called_unchanged_clean | pass | 604 | 2054 | 1172 | 3227 | $0.002374 |
| `Levantó temprano ayer.` | `Se levantó temprano ayer.` | `Se levantó temprano ayer.` | called_unchanged_clean | pass | 726 | 2201 | 972 | 3173 | $0.002432 |
| `A Juan gusta el café.` | `A Juan le gusta el café.` | `A Juan le gusta el café.` | called_unchanged_clean | pass | 588 | 1826 | 1115 | 2942 | $0.002312 |

## Unnecessary Extras / Deletions

5 fixtures — 3 pass / 2 fail. Fallback: 3 not_needed, 1 called_changed_text, 1 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Yo trabajo mucho y yo estudio por las noches.` | `Yo trabajo mucho y yo estudio por las noches.` | `Trabajo mucho y estudio por las noches.` | called_changed_text | fail | 783 | 1897 | 2045 | 3943 | $0.003293 |
| `Ellos viajaron a México y ellos visitaron varias ciudades.` | `Ellos viajaron a México y ellos visitaron varias ciudades.` | `Ellos viajaron a México y visitaron varias ciudades.` | not_needed | pass | 694 | 1822 | 0 | 1823 | $0.001770 |
| `A mí me gusta el café a mí.` | `A mí me gusta el café.` | `A mí me gusta el café.` | called_unchanged_clean | pass | 629 | 2473 | 1127 | 3600 | $0.002312 |
| `Yo fui al mercado y yo compré pan.` | `Yo fui al mercado y yo compré pan.` | `Fui al mercado y compré pan.` | not_needed | pass | 680 | 2421 | 0 | 2422 | $0.002006 |
| `Nosotros salimos temprano y nosotros llegamos a tiempo.` | `Nosotros salimos temprano y nosotros llegamos a tiempo.` | `Salimos temprano y llegamos a tiempo.` | not_needed | fail | 639 | 1966 | 0 | 1966 | $0.001929 |

## Ser / Estar / Haber

5 fixtures — 5 pass / 0 fail. Fallback: 2 not_needed, 3 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Mi hermano está profesor.` | `Mi hermano es profesor.` | `Mi hermano es profesor.` | called_unchanged_clean | pass | 671 | 1888 | 1137 | 3025 | $0.002110 |
| `En la sala son veinte personas.` | `En la sala hay veinte personas.` | `En la sala hay veinte personas.` | called_unchanged_clean | pass | 681 | 1803 | 895 | 2699 | $0.002325 |
| `Madrid está la capital de España.` | `Madrid es la capital de España.` | `Madrid es la capital de España.` | called_unchanged_clean | pass | 902 | 1937 | 1024 | 2962 | $0.002395 |
| `Estoy muy contento con el resultado.` | `Estoy muy contento con el resultado.` | `Estoy muy contento con el resultado.` | not_needed | pass | 678 | 987 | 0 | 988 | $0.001044 |
| `La reunión es en la segunda planta.` | `La reunión es en la segunda planta.` | `La reunión es en la segunda planta.` | not_needed | pass | 577 | 1296 | 0 | 1297 | $0.001044 |

## Impersonal Haber / Se

5 fixtures — 5 pass / 0 fail. Fallback: 5 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Habían muchas personas en la entrada.` | `Había muchas personas en la entrada.` | `Había muchas personas en la entrada.` | called_unchanged_clean | pass | 784 | 2122 | 1217 | 3340 | $0.002547 |
| `Hubieron varios problemas durante la reunión.` | `Hubo varios problemas durante la reunión.` | `Hubo varios problemas durante la reunión.` | called_unchanged_clean | pass | 691 | 2730 | 1025 | 3755 | $0.002567 |
| `Se vende pisos en el centro.` | `Se venden pisos en el centro.` | `Se venden pisos en el centro.` | called_unchanged_clean | pass | 574 | 1965 | 1068 | 3033 | $0.002375 |
| `Se necesita voluntarios para el evento.` | `Se necesitan voluntarios para el evento.` | `Se necesitan voluntarios para el evento.` | called_unchanged_clean | pass | 682 | 2331 | 1125 | 3457 | $0.002407 |
| `Habían varias cifras incorrectas.` | `Había varias cifras incorrectas.` | `Había varias cifras incorrectas.` | called_unchanged_clean | pass | 518 | 1699 | 1021 | 2721 | $0.002415 |

## False Friends / Word Choice

5 fixtures — 4 pass / 1 fail. Fallback: 2 not_needed, 2 called_changed_text, 1 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Atendió la universidad en Madrid.` | `Asistió a la universidad en Madrid.` | `Estudió en la universidad en Madrid.` | called_changed_text | fail | 681 | 2269 | 2822 | 5092 | $0.003767 |
| `Aplicó para un trabajo.` | `Aplicó para un trabajo.` | `Solicitó un trabajo.` | not_needed | pass | 2211 | 2210 | 0 | 2211 | $0.001861 |
| `Realicé que estaba equivocado.` | `Me di cuenta de que estaba equivocado.` | `Me di cuenta de que estaba equivocado.` | called_unchanged_clean | pass | 568 | 1940 | 992 | 2933 | $0.002337 |
| `Estoy embarazado por llegar tarde.` | `Estoy avergonzado por llegar tarde.` | `Me da vergüenza llegar tarde.` | called_changed_text | pass | 681 | 2128 | 2120 | 4249 | $0.003777 |
| `Actualmente vivo en Londres.` | `Actualmente vivo en Londres.` | `Actualmente vivo en Londres.` | not_needed | pass | 610 | 1002 | 0 | 1002 | $0.001010 |

## Phrase-Level Naturalness

5 fixtures — 1 pass / 4 fail. Fallback: 4 not_needed, 1 called_changed_text.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Tuvimos un buen tiempo.` | `Tuvimos un buen tiempo.` | `Lo pasamos bien.` | not_needed | pass | 784 | 1707 | 0 | 1707 | $0.001862 |
| `Estoy corriendo tarde para la reunión.` | `Estoy llegando tarde para la reunión.` | `Estoy llegando tarde a la reunión.` | called_changed_text | fail | 528 | 2088 | 2065 | 4154 | $0.003138 |
| `Quiero pasar un buen tiempo.` | `Quiero pasar un buen tiempo.` | `Quiero pasarlo bien / pasar un buen rato.` | not_needed | fail | 661 | 1582 | 0 | 1583 | $0.001892 |
| `¿Puedo tener una cerveza?` | `¿Puedo tener una cerveza?` | `¿Me pones una cerveza? / ¿Me traes una cerveza? / ¿Me das una cerveza?` | not_needed | fail | 683 | 2118 | 0 | 2119 | $0.002213 |
| `Te llamo para atrás.` | `Te llamo para atrás.` | `Te devuelvo la llamada / Te llamo luego / Te vuelvo a llamar.` | not_needed | fail | 577 | 2070 | 0 | 2071 | $0.002051 |

## Valid Regional / Should Not Flag

5 fixtures — 4 pass / 1 fail. Fallback: 5 not_needed.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Voy para casa ahora mismo.` | `Voy a casa ahora mismo.` | `Voy a casa ahora mismo.` | not_needed | fail | 679 | 1135 | 0 | 1136 | $0.001021 |
| `Vos tenés razón.` | `Vos tenés razón.` | `Vos tenés razón.` | not_needed | pass | 576 | 975 | 0 | 975 | $0.001010 |
| `Cojo el autobús cada mañana.` | `Cojo el autobús cada mañana.` | `Cojo el autobús cada mañana.` | not_needed | pass | 640 | 1152 | 0 | 1152 | $0.001044 |
| `Esta mañana hablé con mi jefe.` | `Esta mañana hablé con mi jefe.` | `Esta mañana hablé con mi jefe.` | not_needed | pass | 535 | 891 | 0 | 892 | $0.001044 |
| `Dale, nos vemos más tarde.` | `Dale, nos vemos más tarde.` | `Dale, nos vemos más tarde.` | not_needed | pass | 645 | 851 | 0 | 852 | $0.001044 |

## Already Correct / Do Not Tinker

5 fixtures — 4 pass / 1 fail. Fallback: 5 not_needed.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Buenos días, ¿cómo estás?` | `Buenos días, ¿cómo estás?` | `Buenos días, ¿cómo estás?` | not_needed | pass | 689 | 1189 | 0 | 1189 | $0.001032 |
| `Voy a hacer una pregunta al profesor.` | `Voy a hacer una pregunta al profesor.` | `Voy a hacer una pregunta al profesor.` | not_needed | pass | 661 | 1513 | 0 | 1513 | $0.001044 |
| `Necesito tomar una foto del documento.` | `Necesito tomar una foto del documento.` | `Necesito sacar una foto / hacer una foto del documento.` | not_needed | fail | 586 | 2217 | 0 | 2217 | $0.001814 |
| `Mañana visitaré a mi abuela.` | `Mañana visitaré a mi abuela.` | `Mañana visitaré a mi abuela.` | not_needed | pass | 716 | 1294 | 0 | 1295 | $0.001066 |
| `Está lloviendo, así que me quedo en casa.` | `Está lloviendo, así que me quedo en casa.` | `Está lloviendo, así que me quedo en casa.` | not_needed | pass | 780 | 966 | 0 | 967 | $0.001100 |

## Mixed Operations

5 fixtures — 2 pass / 3 fail. Fallback: 4 called_changed_text, 1 called_unchanged_clean.

| Phrase | First-pass corrected phrase | Final corrected phrase | Fallback outcome | Pass/fail | First-pass latency (ms) | Naturalness (parallel) latency (ms) | Fallback latency (ms) | Production total latency (ms) | Production cost (USD) |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `Insisto que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | `Insisto en que revises el contrato, y yo trabajo mucho y yo estudio por las noches.` | `Insisto en que revises el contrato, yo trabajo mucho y estudio por las noches.` | called_changed_text | fail | 676 | 2287 | 2533 | 4820 | $0.004034 |
| `Necesito comprar libro para la clase, y compre cafe en una cafeteria pequena.` | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | `Necesito comprar un libro para la clase, y compré café en una cafetería pequeña.` | called_unchanged_clean | pass | 733 | 3633 | 1200 | 4833 | $0.004125 |
| `Vi mi profesor en la estación, y es importante que estudias.` | `Vi a mi profesor en la estación, y es importante que estudies.` | `Vi a mi profesor en la estación. Es importante que estudies.` | called_changed_text | fail | 678 | 2418 | 2150 | 4568 | $0.004072 |
| `Las ventanas estaban abierto, y a mí me gusta el café a mí.` | `Las ventanas estaban abiertas, y a mí me gusta el café a mí.` | `Las ventanas estaban abiertas, y a mí me gusta el café.` | called_changed_text | pass | 634 | 2250 | 2151 | 4402 | $0.004105 |
| `Ellos estudia todas las noches, y creo está bien terminar hoy.` | `Ellos estudian todas las noches, y creo que está bien terminar hoy.` | `Ellos estudian todas las noches y creo que está bien que hoy terminen / y creo que hoy pueden terminar / y creo que hoy está bien que terminen.` | called_changed_text | fail | 684 | 1971 | 2751 | 4723 | $0.003904 |

---

## Overall summary

| Fixtures | Errors | Production total latency (ms) | Production total tokens | Production total est. cost (USD) |
| --- | --- | --- | --- | --- |
| 85 | 0 | 235810 | 62302 | $0.185787 |

### Pass/fail summary

| Metric | Count | Rate |
| --- | --- | --- |
| Pass | 67 | 78.8% |
| Fail | 18 | 21.2% |

### Diagnostic vs. production-style totals

| Metric | Diagnostic (both naturalness calls always) | Production-style (conditional fallback) | Estimated savings |
| --- | --- | --- | --- |
| Latency (ms) | 286908 | 235810 | 51098 ms (17.8%) |
| Est. cost (USD) | $0.218540 | $0.185787 | $0.032754 (15.0%) |

### Fallback outcome summary

| Outcome | Count | Rate |
| --- | --- | --- |
| not_needed | 34 | 40.0% |
| called_changed_text | 12 | 14.1% |
| called_unchanged_clean | 39 | 45.9% |
| called_still_unsafe | 0 | 0.0% |

### Score summary

| Score | Count |
| --- | --- |
| correct_fix | 56 |
| partial_fix | 3 |
| overcorrection | 3 |
| acceptable_no_change | 11 |
| ambiguous | 12 |

### Language point summary

| Language point | Fixtures | correct_fix | partial_fix | missed_issue | overcorrection | acceptable_no_change | ambiguous | error |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Accents / Diacritics | 6 | 5 | 0 | 0 | 0 | 0 | 1 | 0 |
| Collocations / Strong Calques | 6 | 6 | 0 | 0 | 0 | 0 | 0 | 0 |
| Accents / Diacritics + Collocations / Strong Calques (independent spans) | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Verb Morphology (spelling) overlapping Collocations / Strong Calques | 1 | 1 | 0 | 0 | 0 | 0 | 0 | 0 |
| Ambiguous / Repeated Span Safety (Naturalness) | 1 | 0 | 0 | 0 | 1 | 0 | 0 | 0 |
| Gender / Number Agreement | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Verb Agreement / Morphology | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Required Prepositions | 5 | 4 | 0 | 0 | 0 | 0 | 1 | 0 |
| Articles / Determiners | 5 | 3 | 1 | 0 | 0 | 0 | 1 | 0 |
| Subjunctive / Mood | 5 | 4 | 0 | 0 | 0 | 0 | 1 | 0 |
| Required Additions / Omissions | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| Unnecessary Extras / Deletions | 5 | 3 | 0 | 0 | 0 | 0 | 2 | 0 |
| Ser / Estar / Haber | 5 | 3 | 0 | 0 | 0 | 2 | 0 | 0 |
| Impersonal Haber / Se | 5 | 5 | 0 | 0 | 0 | 0 | 0 | 0 |
| False Friends / Word Choice | 5 | 3 | 0 | 0 | 0 | 1 | 1 | 0 |
| Phrase-Level Naturalness | 5 | 1 | 1 | 0 | 0 | 0 | 3 | 0 |
| Valid Regional / Should Not Flag | 5 | 0 | 0 | 0 | 1 | 4 | 0 | 0 |
| Already Correct / Do Not Tinker | 5 | 0 | 0 | 0 | 1 | 4 | 0 | 0 |
| Mixed Operations | 5 | 2 | 1 | 0 | 0 | 0 | 2 | 0 |
