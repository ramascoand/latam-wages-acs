# IPUMS USA Extract Specification — Latam Wages ACS

Variables y samples a solicitar en https://usa.ipums.org/usa/.

## Samples (ACS 1-year)

Pedir las 14 muestras anuales 2010–2023. **NO** usar PRCS (Puerto Rico) ni muestras 5-year (las 5-year reutilizan observaciones entre releases y no son apilables).

- 2010 ACS, 2011 ACS, …, 2023 ACS

## Variables a incluir

### Identificadores y pesos (preseleccionados por IPUMS)
- `YEAR`, `SAMPLE`, `SERIAL`, `PERNUM`, `HHWT`, `PERWT`

### Geografía
- `STATEFIP`
- `METRO` (opcional, para FE de área metro)

### Demografía
- `SEX`, `AGE`, `MARST`, `NCHILD`
- `RACE`, `RACED`
- `HISPAN`, `HISPAND`

### Lugar de nacimiento y migración *(núcleo del análisis)*
- `BPL` — país de nacimiento general (200=México, 210=C.Am, 300=S.Am, etc.)
- `BPLD` — **país de nacimiento detallado** (necesario para desagregar por país)
- `NATIVITY` — nativo vs extranjero
- `CITIZEN` — estatus de ciudadanía
- `YRIMMIG` — año de inmigración (años en USA)
- `YRSUSA1` — años en USA (continuo, redundante con YRIMMIG pero útil)
- `LANGUAGE`, `SPEAKENG` — idioma hablado y dominio del inglés

### Educación
- `EDUC` (general), `EDUCD` (detallado, necesario para mapear años de escolaridad)

### Mercado laboral
- `EMPSTAT`, `EMPSTATD`, `LABFORCE`
- `CLASSWKR`, `CLASSWKRD` — clase de trabajador (asalariado vs cuenta propia)
- `UHRSWORK` — horas usuales por semana
- `WKSWORK1` — semanas trabajadas el año pasado (continuo)
- `WKSWORK2` — semanas trabajadas (intervalado, fallback)
- `OCC2010` — ocupación armonizada
- `IND1990` — industria armonizada

### Ingreso *(crítico — el extract actual NO tiene `INCWAGE`)*
- `INCWAGE` — **salario y sueldos** (el outcome principal del Mincer)
- `INCEARN` — ingreso laboral total (incluye self-employment)
- `INCTOT`, `FTOTINC` — ingreso total individual y familiar

## Notas

- Output format: **.dta (Stata)** o CSV — el script `1_data_prep.do` espera el formato standard de IPUMS
- Estimar tamaño: ~3M obs/año × 14 años × ~25 vars ≈ archivo de 3–5 GB
- Guardar el archivo en `data/` con nombre `acs_2010_2023_raw.dta` (o ajustar `$rawdata` en `master.do`)

## Países latinoamericanos en BPLD

Codeframe esperado (verificar contra labels una vez descargado):

| BPLD | País |
|---|---|
| 200 | Mexico |
| 210 | Costa Rica |
| 211 | Guatemala |
| 212 | Honduras |
| 213 | Nicaragua |
| 214 | Panama |
| 215 | El Salvador |
| 250 | Cuba |
| 260 | Dominican Republic |
| 261 | Haiti |
| 300 | South America (n.s.) |
| 301 | Argentina |
| 302 | Bolivia |
| 303 | Brazil |
| 304 | Chile |
| 305 | Colombia |
| 306 | Ecuador |
| 307 | French Guiana / Guyana |
| 308 | Paraguay |
| 309 | Peru |
| 310 | Uruguay |
| 311 | Venezuela |

**Importante**: los códigos exactos varían levemente entre versiones de IPUMS. El script `1_data_prep.do` usa rangos amplios (`200/399`) y luego separa por etiqueta.
