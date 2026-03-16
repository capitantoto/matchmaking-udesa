# Matchmaking UdeSA — Notebook para charla universitaria

## Qué es este proyecto

Notebook de Jupyter para una charla de 1h20 (45min + 25min Q&A) sobre el trabajo de un data scientist en una plataforma de matchmaking (dating). Enfocado en estadística aplicada. Para presentar en clase y entregar después — no se usa interactivamente.

## Estado actual

- Diseño aprobado en `docs/plans/2026-03-12-matchmaking-notebook-design.md`
- Pendiente: implementación del notebook

## Decisiones de diseño

- Dominio: dating, 100 usuarios, 6 dimensiones
- Idioma: todo en español (markdown, comentarios). Variables de código en inglés.
- Libs especializadas OK, pero siempre incluir implementación alternativa con libs comunes
- Fuerza bruta con scipy.minimize usa límite de iteraciones (no exhaustivo)
- Comparar: Gale-Shapley vs. max weight matching vs. brute force

## Convenciones

- Un solo notebook `.ipynb` con todo el pipeline end-to-end
- Secciones bien marcadas con markdown headers para navegar durante la presentación
- Visualizaciones claras y grandes (para proyectar en pantalla)
