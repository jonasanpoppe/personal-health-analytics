# ============================================================
#  Health Dashboard — Palette System
#  Two independent layers: semantic (status) + categorical (series)
#  Never mix them visually — see design rule below
# ============================================================

# ── Semantic layer (status signals ONLY) ────────────────────
# Reserved for: good/warning/critical/neutral/primary UI
semantic_colors <- c(
  good     = "#10B981",  # Positive biomarkers, goals met
  warning  = "#D97706",  # Approaching threshold
  critical = "#DC2626",  # Out of range, urgent
  neutral  = "#94A3B8",  # Inactive, no data
  primary  = "#0891B2"   # UI actions, highlights
)

# ── Categorical layer (data series) ─────────────────────────
# CVD-safe, cool-leaning. For labeling metrics and chart lines.
# If using ≤3 series, prefer: C1, C2, C4 for best separation.
categorical_colors <- c(
  C1_steel_blue  = "#5B8DB8",  # e.g. HRV
  C2_sage        = "#6BAE8E",  # e.g. Sleep
  C3_mauve       = "#9B7BB5",  # e.g. Steps
  C4_dusty_rose  = "#C47E8A",  # e.g. Calories
  C5_warm_taupe  = "#B8956B",  # e.g. Weight
  C6_slate_teal  = "#4E9EA8"   # e.g. Stress
)

# ── Base / UI layer ──────────────────────────────────────────
base_colors <- c(
  background = "#F8FAFC",
  surface    = "#F1F5F9",
  border     = "#E2E8F0",
  muted_text = "#64748B",
  body_text  = "#1E293B"
)

# ── bslib Shiny theme ────────────────────────────────────────
# library(bslib)
# health_theme <- bs_theme(
#   bg      = base_colors["background"],
#   fg      = base_colors["body_text"],
#   primary = semantic_colors["primary"],
#   warning = semantic_colors["warning"],
#   danger  = semantic_colors["critical"],
#   success = semantic_colors["good"],
#   base_font = font_google("DM Sans")
# )

# ── ggplot2 scales ───────────────────────────────────────────
# Drop-in scale functions for consistent plot styling

scale_color_health <- function(...) {
  ggplot2::scale_color_manual(values = unname(categorical_colors), ...)
}

scale_fill_health <- function(...) {
  ggplot2::scale_fill_manual(values = unname(categorical_colors), ...)
}

scale_color_status <- function(...) {
  ggplot2::scale_color_manual(values = semantic_colors, ...)
}

scale_fill_status <- function(...) {
  ggplot2::scale_fill_manual(values = semantic_colors, ...)
}

# ── Usage examples ───────────────────────────────────────────

# -- Line chart with categorical scale
# ggplot(my_data, aes(date, value, color = metric)) +
#   geom_line(linewidth = 0.9) +
#   scale_color_health() +
#   theme_minimal(base_size = 13)

# -- Status indicator with semantic scale
# ggplot(status_data, aes(x, y, color = status)) +
#   geom_point(size = 4) +
#   scale_color_status() +
#   theme_minimal()

# -- Quick palette preview (requires scales package)
# scales::show_col(c(semantic_colors, categorical_colors))
