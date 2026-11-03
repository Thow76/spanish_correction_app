# Collocation Two-Pass Boundary Harness

## Run configuration

- First-pass prompt: `simple-spanish-grammar-spelling-punctuation-only` `v1`
- Naturalness prompt: `spanish-naturalness-only-variety-restraint` `v3`
- First-pass model: `gpt-4.1`
- Naturalness model: `gpt-5.1`
- Fixtures: `10`
- Runs per fixture: `5`
- Generated: 2026-08-01T13:31:45.005238Z

## Pricing

Verified estimated costs use:
- `gpt-4.1`: input=2.0 USD, output=8.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-4.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28
- `gpt-5.1`: input=1.25 USD, output=10.0 USD, unit=per 1M text tokens, source=https://developers.openai.com/api/docs/models/gpt-5.1, pricing version/effective date=OpenAI model page standard text-token pricing; no separate pricing effective date shown, checked=2026-07-28

## Overall summary

| Runs | First pass left alone | First pass changed | Invalid/error | Total latency (ms) | Total tokens | Total est. cost (USD) |
| --- | --- | --- | --- | --- | --- | --- |
| 50 | 18.0% (9/50) | 80.0% (40/50) | 2.0% (1/50) | 249693 | 44585 | unknown |

## Fixture summary

| Fixture | Problem phrase | Expected natural phrase | First pass left alone | First pass changed | Naturalness on original flagged | Naturalness on first-pass flagged | Distinct first-pass outputs |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `make-a-decision` | `hacer una decisión` | `tomar una decisión` | 0.0% (0/5) | 100.0% (5/5) | 100.0% (5/5) | 0.0% (0/5) | `Voy a tomar una decisión importante antes del viernes.` |
| `make-sense` | `hace sentido` | `tiene sentido` | 0.0% (0/5) | 100.0% (5/5) | 100.0% (5/5) | 0.0% (0/5) | `Tu explicación no tiene sentido en este contexto.` |
| `pay-attention` | `pagar atención` | `prestar atención` | 0.0% (0/5) | 100.0% (5/5) | 100.0% (5/5) | 0.0% (0/5) | `Tienes que prestar atención a los detalles del contrato.` |
| `take-a-meeting` | `tomó una reunión` | `tuvo una reunión` | 0.0% (0/5) | 100.0% (5/5) | 100.0% (5/5) | 0.0% (0/5) | `El equipo tuvo una reunión para hablar del problema.` |
| `apply-for-job` | `aplicó para un trabajo` | `solicitó un trabajo` | 40.0% (2/5) | 60.0% (3/5) | 100.0% (5/5) | 100.0% (5/5) | `Mi hermano aplicó a un trabajo en Madrid.`<br>`Mi hermano aplicó para un trabajo en Madrid.` |
| `attend-university` | `atendió la universidad` | `asistió a la universidad` | 0.0% (0/5) | 100.0% (5/5) | 100.0% (5/5) | 20.0% (1/5) | `Ella asistió a la universidad en Salamanca.` |
| `have-good-time` | `tuvimos un buen tiempo` | `lo pasamos bien` | 40.0% (2/5) | 60.0% (3/5) | 100.0% (5/5) | 40.0% (2/5) | `Tuvimos un buen tiempo en la fiesta anoche.`<br>`La pasamos bien en la fiesta anoche.`<br>`Lo pasamos bien en la fiesta anoche.` |
| `make-a-point` | `hizo un punto` | `planteó un punto` | 100.0% (5/5) | 0.0% (0/5) | 100.0% (5/5) | 100.0% (5/5) | `La profesora hizo un punto interesante durante la clase.` |
| `take-a-look` | `tomar una mirada` | `echar un vistazo` | 0.0% (0/5) | 100.0% (5/5) | 100.0% (5/5) | 0.0% (0/5) | `Voy a echar una mirada al documento esta tarde.` |
| `running-late` | `corriendo tarde` | `llegando tarde` | 0.0% (0/5) | 80.0% (4/5) | 100.0% (5/5) | 80.0% (4/5) | `Estoy llegando tarde para la reunión.` |

## Individual runs

| Fixture | Run | Input | First-pass output | First-pass result | Naturalness on original | Naturalness on first-pass output | Latency (ms) | Tokens | Cost |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `make-a-decision` | 1 | `Voy a hacer una decisión importante antes del viernes.` | `Voy a tomar una decisión importante antes del viernes.` | changed | hacer una decisión -> tomar una decisión | (none) | 5053 | 847 | $0.002283 |
| `make-a-decision` | 2 | `Voy a hacer una decisión importante antes del viernes.` | `Voy a tomar una decisión importante antes del viernes.` | changed | hacer una decisión -> tomar una decisión | (none) | 5076 | 860 | $0.002413 |
| `make-a-decision` | 3 | `Voy a hacer una decisión importante antes del viernes.` | `Voy a tomar una decisión importante antes del viernes.` | changed | hacer una decisión -> tomar una decisión | (none) | 3218 | 841 | $0.002223 |
| `make-a-decision` | 4 | `Voy a hacer una decisión importante antes del viernes.` | `Voy a tomar una decisión importante antes del viernes.` | changed | hacer una decisión -> tomar una decisión | (none) | 3353 | 859 | $0.002403 |
| `make-a-decision` | 5 | `Voy a hacer una decisión importante antes del viernes.` | `Voy a tomar una decisión importante antes del viernes.` | changed | hacer una decisión -> tomar una decisión | (none) | 3547 | 858 | $0.002393 |
| `make-sense` | 1 | `Tu explicación no hace sentido en este contexto.` | `Tu explicación no tiene sentido en este contexto.` | changed | no hace sentido -> no tiene sentido | (none) | 3854 | 855 | $0.002390 |
| `make-sense` | 2 | `Tu explicación no hace sentido en este contexto.` | `Tu explicación no tiene sentido en este contexto.` | changed | no hace sentido -> no tiene sentido | (none) | 4057 | 851 | $0.002350 |
| `make-sense` | 3 | `Tu explicación no hace sentido en este contexto.` | `Tu explicación no tiene sentido en este contexto.` | changed | no hace sentido -> no tiene sentido | (none) | 3854 | 856 | $0.002400 |
| `make-sense` | 4 | `Tu explicación no hace sentido en este contexto.` | `Tu explicación no tiene sentido en este contexto.` | changed | no hace sentido -> no tiene sentido | (none) | 3753 | 863 | $0.002470 |
| `make-sense` | 5 | `Tu explicación no hace sentido en este contexto.` | `Tu explicación no tiene sentido en este contexto.` | changed | no hace sentido -> no tiene sentido | (none) | 3852 | 856 | $0.002400 |
| `pay-attention` | 1 | `Tienes que pagar atención a los detalles del contrato.` | `Tienes que prestar atención a los detalles del contrato.` | changed | pagar atención -> prestar atención | (none) | 4904 | 854 | $0.002325 |
| `pay-attention` | 2 | `Tienes que pagar atención a los detalles del contrato.` | `Tienes que prestar atención a los detalles del contrato.` | changed | pagar atención -> prestar atención | (none) | 3521 | 844 | $0.002225 |
| `pay-attention` | 3 | `Tienes que pagar atención a los detalles del contrato.` | `Tienes que prestar atención a los detalles del contrato.` | changed | pagar atención -> prestar atención | (none) | 3135 | 844 | $0.002225 |
| `pay-attention` | 4 | `Tienes que pagar atención a los detalles del contrato.` | `Tienes que prestar atención a los detalles del contrato.` | changed | pagar atención -> prestar atención | (none) | 3530 | 844 | $0.002225 |
| `pay-attention` | 5 | `Tienes que pagar atención a los detalles del contrato.` | `Tienes que prestar atención a los detalles del contrato.` | changed | pagar atención -> prestar atención | (none) | 3873 | 861 | $0.002395 |
| `take-a-meeting` | 1 | `El equipo tomó una reunión para hablar del problema.` | `El equipo tuvo una reunión para hablar del problema.` | changed | tomó una reunión -> tuvo una reunión / se reunió / convocó una reunión | (none) | 3752 | 884 | $0.002653 |
| `take-a-meeting` | 2 | `El equipo tomó una reunión para hablar del problema.` | `El equipo tuvo una reunión para hablar del problema.` | changed | tomó una reunión -> tuvo una reunión / se reunió | (none) | 3751 | 862 | $0.002433 |
| `take-a-meeting` | 3 | `El equipo tomó una reunión para hablar del problema.` | `El equipo tuvo una reunión para hablar del problema.` | changed | tomó una reunión -> tuvo una reunión / se reunió / convocó una reunión | (none) | 5501 | 887 | $0.002682 |
| `take-a-meeting` | 4 | `El equipo tomó una reunión para hablar del problema.` | `El equipo tuvo una reunión para hablar del problema.` | changed | tomó una reunión -> tuvo una reunión | (none) | 3641 | 859 | $0.002403 |
| `take-a-meeting` | 5 | `El equipo tomó una reunión para hablar del problema.` | `El equipo tuvo una reunión para hablar del problema.` | changed | tomó una reunión -> tuvo una reunión / se reunió | (none) | 4312 | 862 | $0.002433 |
| `apply-for-job` | 1 | `Mi hermano aplicó para un trabajo en Madrid.` | `Mi hermano aplicó a un trabajo en Madrid.` | changed | aplicó para un trabajo -> solicitó un trabajo / se postuló para un trabajo | aplicó a un trabajo -> solicitó un trabajo / se postuló para un trabajo | 4629 | 981 | $0.003622 |
| `apply-for-job` | 2 | `Mi hermano aplicó para un trabajo en Madrid.` | `Mi hermano aplicó a un trabajo en Madrid.` | changed | aplicó para un trabajo -> se postuló a un trabajo / solicitó un trabajo | aplicó a un trabajo -> se postuló a un trabajo / solicitó un trabajo | 4666 | 985 | $0.003662 |
| `apply-for-job` | 3 | `Mi hermano aplicó para un trabajo en Madrid.` | `Mi hermano aplicó a un trabajo en Madrid.` | changed | aplicó para un trabajo -> se postuló a un trabajo / solicitó un trabajo | aplicó a un trabajo -> solicitó un trabajo / se postuló para un trabajo | 5137 | 982 | $0.003633 |
| `apply-for-job` | 4 | `Mi hermano aplicó para un trabajo en Madrid.` | `Mi hermano aplicó para un trabajo en Madrid.` | left alone | aplicó para un trabajo -> solicitó un trabajo / presentó una solicitud para un trabajo | aplicó para un trabajo -> solicitó un trabajo / presentó una solicitud para un trabajo / se postuló para un trabajo | 4389 | 987 | $0.003683 |
| `apply-for-job` | 5 | `Mi hermano aplicó para un trabajo en Madrid.` | `Mi hermano aplicó para un trabajo en Madrid.` | left alone | aplicó para un trabajo -> se postuló a un trabajo / solicitó un trabajo | aplicó para un trabajo -> solicitó un trabajo / se postuló para un trabajo | 4390 | 978 | $0.003593 |
| `attend-university` | 1 | `Ella atendió la universidad en Salamanca.` | `Ella asistió a la universidad en Salamanca.` | changed | atendió la universidad -> asistió a la universidad | (none) | 3891 | 869 | $0.002547 |
| `attend-university` | 2 | `Ella atendió la universidad en Salamanca.` | `Ella asistió a la universidad en Salamanca.` | changed | atendió la universidad -> asistió a la universidad | (none) | 3613 | 865 | $0.002507 |
| `attend-university` | 3 | `Ella atendió la universidad en Salamanca.` | `Ella asistió a la universidad en Salamanca.` | changed | atendió la universidad -> estudió en la universidad / asistió a la universidad | (none) | 4296 | 863 | $0.002487 |
| `attend-university` | 4 | `Ella atendió la universidad en Salamanca.` | `Ella asistió a la universidad en Salamanca.` | changed | atendió la universidad -> asistió a la universidad | asistió a la universidad -> estudió en la universidad | 5153 | 942 | $0.003277 |
| `attend-university` | 5 | `Ella atendió la universidad en Salamanca.` | `Ella asistió a la universidad en Salamanca.` | changed | atendió la universidad -> asistió a la universidad | (none) | 4059 | 867 | $0.002527 |
| `have-good-time` | 1 | `Tuvimos un buen tiempo en la fiesta anoche.` | `Tuvimos un buen tiempo en la fiesta anoche.` | left alone | Tuvimos un buen tiempo -> Lo pasamos bien | Tuvimos un buen tiempo -> Lo pasamos bien | 4774 | 969 | $0.003448 |
| `have-good-time` | 2 | `Tuvimos un buen tiempo en la fiesta anoche.` | `Tuvimos un buen tiempo en la fiesta anoche.` | left alone | Tuvimos un buen tiempo en la fiesta anoche. -> Lo pasamos muy bien en la fiesta anoche. | Tuvimos un buen tiempo -> Lo pasamos bien | 6104 | 963 | $0.003387 |
| `have-good-time` | 3 | `Tuvimos un buen tiempo en la fiesta anoche.` | `La pasamos bien en la fiesta anoche.` | changed | Tuvimos un buen tiempo en la fiesta anoche. -> Lo pasamos muy bien en la fiesta anoche. | (none) | 4441 | 894 | $0.002719 |
| `have-good-time` | 4 | `Tuvimos un buen tiempo en la fiesta anoche.` | `Lo pasamos bien en la fiesta anoche.` | changed | Tuvimos un buen tiempo en la fiesta anoche. -> Lo pasamos muy bien en la fiesta anoche. | (none) | 4294 | 895 | $0.002729 |
| `have-good-time` | 5 | `Tuvimos un buen tiempo en la fiesta anoche.` | `Lo pasamos bien en la fiesta anoche.` | changed | Tuvimos un buen tiempo en la fiesta anoche. -> Lo pasamos bien en la fiesta anoche. | (none) | 3753 | 881 | $0.002589 |
| `make-a-point` | 1 | `La profesora hizo un punto interesante durante la clase.` | `La profesora hizo un punto interesante durante la clase.` | left alone | hizo un punto interesante -> planteó un punto interesante | hizo un punto interesante -> planteó un punto interesante | 5185 | 982 | $0.003632 |
| `make-a-point` | 2 | `La profesora hizo un punto interesante durante la clase.` | `La profesora hizo un punto interesante durante la clase.` | left alone | hizo un punto interesante -> hizo una observación interesante | hizo un punto interesante -> hizo una observación interesante | 4570 | 966 | $0.003472 |
| `make-a-point` | 3 | `La profesora hizo un punto interesante durante la clase.` | `La profesora hizo un punto interesante durante la clase.` | left alone | hizo un punto interesante -> planteó un punto interesante | hizo un punto interesante -> planteó / hizo / señaló un comentario (o un aporte) interesante | 4979 | 970 | $0.003512 |
| `make-a-point` | 4 | `La profesora hizo un punto interesante durante la clase.` | `La profesora hizo un punto interesante durante la clase.` | left alone | hizo un punto interesante -> hizo una observación interesante | hizo un punto interesante -> hizo una observación interesante | 5120 | 969 | $0.003502 |
| `make-a-point` | 5 | `La profesora hizo un punto interesante durante la clase.` | `La profesora hizo un punto interesante durante la clase.` | left alone | hizo un punto interesante -> hizo una observación interesante | hizo un punto interesante -> hizo un comentario interesante | 4128 | 950 | $0.003313 |
| `take-a-look` | 1 | `Voy a tomar una mirada al documento esta tarde.` | `Voy a echar una mirada al documento esta tarde.` | changed | tomar una mirada -> echar un vistazo / darle un vistazo / revisar / mirar | (none) | 3749 | 888 | $0.002693 |
| `take-a-look` | 2 | `Voy a tomar una mirada al documento esta tarde.` | `Voy a echar una mirada al documento esta tarde.` | changed | tomar una mirada -> echar un vistazo / darle un vistazo / mirar / revisar | (none) | 4262 | 884 | $0.002653 |
| `take-a-look` | 3 | `Voy a tomar una mirada al documento esta tarde.` | `Voy a echar una mirada al documento esta tarde.` | changed | tomar una mirada -> echar un vistazo / echar una ojeada / mirar | (none) | 3929 | 893 | $0.002743 |
| `take-a-look` | 4 | `Voy a tomar una mirada al documento esta tarde.` | `Voy a echar una mirada al documento esta tarde.` | changed | tomar una mirada -> echar un vistazo / mirar / revisar | (none) | 3984 | 876 | $0.002573 |
| `take-a-look` | 5 | `Voy a tomar una mirada al documento esta tarde.` | `Voy a echar una mirada al documento esta tarde.` | changed | tomar una mirada -> echar un vistazo / darle un vistazo / revisar / echarle un ojo | (none) | 3858 | 892 | $0.002733 |
| `running-late` | 1 | `Estoy corriendo tarde para la reunión.` | `Estoy llegando tarde para la reunión.` | changed | Estoy corriendo tarde para la reunión -> Llego tarde a la reunión / Voy tarde a la reunión | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | 4658 | 977 | $0.003648 |
| `running-late` | 2 | `Estoy corriendo tarde para la reunión.` | `(none)` | invalid/error | Estoy corriendo tarde para la reunión. -> Llego tarde a la reunión. | (not run) | 37352 | 383 | unknown |
| `running-late` | 3 | `Estoy corriendo tarde para la reunión.` | `Estoy llegando tarde para la reunión.` | changed | Estoy corriendo tarde para la reunión -> Llego tarde a la reunión | Estoy llegando tarde para la reunión -> Voy a llegar tarde a la reunión | 4554 | 965 | $0.003528 |
| `running-late` | 4 | `Estoy corriendo tarde para la reunión.` | `Estoy llegando tarde para la reunión.` | changed | Estoy corriendo tarde para la reunión. -> Voy tarde a la reunión. | Estoy llegando tarde para la reunión -> Voy a llegar tarde a la reunión | 5817 | 962 | $0.003498 |
| `running-late` | 5 | `Estoy corriendo tarde para la reunión.` | `Estoy llegando tarde para la reunión.` | changed | Estoy corriendo tarde para la reunión. -> Llego tarde a la reunión. | Estoy llegando tarde para la reunión. -> Voy a llegar tarde a la reunión. | 6422 | 960 | $0.003478 |
