# Matchmaking UdeSA

Material para la charla *"Si nos organizamos, nos enamoramos todos"* — Data science y toma de decisiones en aplicaciones de citas.

Presentada en MCD10 (Seminario de aplicaciones de ciencia de datos al ámbito privado), Universidad de San Andrés, marzo 2026.

## Contenido

| Archivo | Descripción |
|---|---|
| `slides.pdf` | Diapositivas en español (con pausas para presentar en vivo) |
| `slides_handout.pdf` | Diapositivas en español sin pausas (para distribución) |
| `slides_en.pdf` | Diapositivas en inglés (con pausas) |
| `slides_en_handout.pdf` | Diapositivas en inglés sin pausas |
| `matchmaking.ipynb` | Notebook con todo el pipeline: datos sintéticos, modelo, algoritmos de matching, visualizaciones |

## Instalación

Requiere [uv](https://docs.astral.sh/uv/) y [Typst](https://typst.app/).

```bash
# Clonar e instalar dependencias Python
git clone https://github.com/capitantoto/matchmaking-udesa.git
cd matchmaking-udesa
uv sync
```

## Compilar

```bash
# Todo (notebook + 4 PDFs)
make

# Solo el notebook (genera los SVGs)
make notebook

# Solo las slides (requiere SVGs ya generados)
make slides

# Limpiar artefactos
make clean
```

### Compilar a mano (sin Make)

```bash
# 1. Ejecutar el notebook (genera todos los gráficos en img/)
uv run jupyter nbconvert --to notebook --execute matchmaking.ipynb \
    --output matchmaking.ipynb --ExecutePreprocessor.timeout=900

# 2. Compilar slides en español
uv run typst compile slides.typ                                        # con pausas
uv run typst compile --input handout=true slides.typ slides_handout.pdf  # sin pausas

# 3. Compilar slides en inglés
uv run typst compile slides_en.typ
uv run typst compile --input handout=true slides_en.typ slides_en_handout.pdf
```
