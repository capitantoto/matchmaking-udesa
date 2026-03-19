.PHONY: all notebook slides clean

SLIDES_ES  = slides.pdf slides_handout.pdf
SLIDES_EN  = slides_en.pdf slides_en_handout.pdf
ALL_SLIDES = $(SLIDES_ES) $(SLIDES_EN)

# SVGs generados por el notebook (no incluye logos estáticos)
NOTEBOOK_SVGS = img/adtech.svg img/kelly.svg \
                img/matching_gs.svg img/matching_greedy.svg img/matching_mwm.svg \
                img/matching_bar_chart.svg img/matching_results_table.svg \
                img/pred_vs_real_comparison.svg

all: $(ALL_SLIDES)

# ── Notebook ──────────────────────────────────────────────────────────────────
# Un solo run genera todos los SVGs; usamos un sentinel para no re-ejecutar
.notebook.ok: matchmaking.ipynb
	uv run jupyter nbconvert --to notebook --execute $< \
		--output $< --ExecutePreprocessor.timeout=900
	@touch $@

$(NOTEBOOK_SVGS): .notebook.ok

notebook: .notebook.ok

# ── Slides ────────────────────────────────────────────────────────────────────
slides.pdf: slides.typ $(NOTEBOOK_SVGS) bib/references.bib
	uv run typst compile slides.typ

slides_handout.pdf: slides.typ $(NOTEBOOK_SVGS) bib/references.bib
	uv run typst compile --input handout=true slides.typ slides_handout.pdf

slides_en.pdf: slides_en.typ $(NOTEBOOK_SVGS) bib/references.bib
	uv run typst compile slides_en.typ

slides_en_handout.pdf: slides_en.typ $(NOTEBOOK_SVGS) bib/references.bib
	uv run typst compile --input handout=true slides_en.typ slides_en_handout.pdf

slides: $(ALL_SLIDES)

# ── Limpieza ──────────────────────────────────────────────────────────────────
clean:
	rm -f $(ALL_SLIDES) .notebook.ok
