# ============================================================
#  theme_anthropic.R
#  A clean, modern ggplot2 + bslib theme inspired by Anthropic's
#  visual identity: warm off-whites, charcoal, coral accent,
#  generous whitespace, refined typography.
#
#  Usage:
#    source("theme_anthropic.R")
#    ggplot(...) + theme_anthropic()
# ============================================================

# ── Palette ──────────────────────────────────────────────────────────────────

anthropic <- list(

  # Core
  bg          = "#F5F4EF",   # Warm off-white (Anthropic page bg)
  bg_card     = "#ECEAE3",   # Slightly deeper card surface
  fg          = "#1A1A1A",   # Near-black body text
  fg_muted    = "#6B6860",   # Secondary / axis labels
  fg_subtle   = "#A8A49E",   # Gridlines, borders

  # Accent
  coral       = "#C96442",   # Primary Anthropic coral/terracotta
  coral_light = "#E8957A",   # Lighter variant
  coral_dark  = "#9E4A2E",   # Darker variant

  # Categorical (warm-neutral, harmonises with coral)
  cat = c(
    "#C96442",   # Coral        — series 1
    "#5B7FA6",   # Steel blue   — series 2
    "#7A9E7E",   # Sage green   — series 3
    "#9B7BB5",   # Mauve        — series 4
    "#B8956B",   # Warm taupe   — series 5
    "#4E9EA8"    # Slate teal   — series 6
  ),

  # Sequential (light → dark coral, for heatmaps / single-variable)
  seq_low  = "#F5E6DF",
  seq_high = "#7A2E10"
)

# ── ggplot2 theme ─────────────────────────────────────────────────────────────

theme_anthropic <- function(base_size = 12, grid = "y") {

  # Requires: ggplot2, optionally sysfonts/showtext for web fonts
  # Fallback font if showtext not loaded: "sans"
  base_family <- tryCatch({
    if (requireNamespace("showtext", quietly = TRUE) &&
        requireNamespace("sysfonts", quietly = TRUE)) {
      sysfonts::font_add_google("DM Sans", "dm_sans")
      showtext::showtext_auto()
      "dm_sans"
    } else "sans"
  }, error = function(e) "sans")

  half_line <- base_size / 2

  t <- ggplot2::theme_minimal(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      # ── Plot area
      plot.background  = ggplot2::element_rect(fill = anthropic$bg,      colour = NA),
      panel.background = ggplot2::element_rect(fill = anthropic$bg,      colour = NA),
      panel.border     = ggplot2::element_blank(),

      # ── Grid
      panel.grid.major.x = if (grid %in% c("x", "both"))
        ggplot2::element_line(colour = anthropic$fg_subtle, linewidth = 0.35)
      else ggplot2::element_blank(),
      panel.grid.major.y = if (grid %in% c("y", "both"))
        ggplot2::element_line(colour = anthropic$fg_subtle, linewidth = 0.35)
      else ggplot2::element_blank(),
      panel.grid.minor   = ggplot2::element_blank(),

      # ── Axes
      axis.line        = ggplot2::element_blank(),
      axis.ticks       = ggplot2::element_blank(),
      axis.text        = ggplot2::element_text(colour = anthropic$fg_muted, size = ggplot2::rel(0.85)),
      axis.title       = ggplot2::element_text(colour = anthropic$fg,       size = ggplot2::rel(0.9),
                                               margin = ggplot2::margin(t = half_line)),
      axis.title.x     = ggplot2::element_text(margin = ggplot2::margin(t = half_line)),
      axis.title.y     = ggplot2::element_text(margin = ggplot2::margin(r = half_line), angle = 90),

      # ── Titles
      plot.title       = ggplot2::element_text(colour = anthropic$fg,      size = ggplot2::rel(1.3),
                                               face = "bold",
                                               margin = ggplot2::margin(b = half_line * 0.75)),
      plot.subtitle    = ggplot2::element_text(colour = anthropic$fg_muted, size = ggplot2::rel(0.95),
                                               margin = ggplot2::margin(b = half_line * 1.5)),
      plot.caption     = ggplot2::element_text(colour = anthropic$fg_subtle, size = ggplot2::rel(0.75),
                                               hjust = 0,
                                               margin = ggplot2::margin(t = half_line)),
      plot.title.position   = "plot",
      plot.caption.position = "plot",

      # ── Legend
      legend.background = ggplot2::element_rect(fill = anthropic$bg, colour = NA),
      legend.key        = ggplot2::element_rect(fill = anthropic$bg, colour = NA),
      legend.title      = ggplot2::element_text(colour = anthropic$fg,      size = ggplot2::rel(0.85), face = "bold"),
      legend.text       = ggplot2::element_text(colour = anthropic$fg_muted, size = ggplot2::rel(0.82)),
      legend.position   = "top",
      legend.justification = "left",
      legend.key.size   = ggplot2::unit(0.9, "lines"),

      # ── Facets
      strip.background = ggplot2::element_rect(fill = anthropic$bg_card, colour = NA),
      strip.text       = ggplot2::element_text(colour = anthropic$fg, size = ggplot2::rel(0.88), face = "bold"),

      # ── Spacing
      plot.margin = ggplot2::margin(half_line * 2, half_line * 2, half_line * 2, half_line * 2)
    )

  t
}

# ── ggplot2 colour/fill scales ────────────────────────────────────────────────

#' Categorical colour scale (up to 6 series)
scale_colour_anthropic <- function(...) {
  ggplot2::scale_colour_manual(values = anthropic$cat, ...)
}
scale_color_anthropic <- scale_colour_anthropic   # alias

#' Categorical fill scale
scale_fill_anthropic <- function(...) {
  ggplot2::scale_fill_manual(values = anthropic$cat, ...)
}

#' Sequential fill scale (single variable, e.g. heatmap)
scale_fill_anthropic_seq <- function(...) {
  ggplot2::scale_fill_gradient(
    low  = anthropic$seq_low,
    high = anthropic$seq_high,
    ...
  )
}

#' Diverging fill scale (e.g. correlation matrix)
scale_fill_anthropic_div <- function(midpoint = 0, ...) {
  ggplot2::scale_fill_gradient2(
    low      = anthropic$coral_dark,
    mid      = anthropic$bg,
    high     = anthropic$steel_blue %||% "#5B7FA6",
    midpoint = midpoint,
    ...
  )
}

# ── bslib Shiny theme ─────────────────────────────────────────────────────────

# Uncomment when using in a Shiny app:
#
# library(bslib)
#
# shiny_theme_anthropic <- bs_theme(
#   bg         = anthropic$bg,
#   fg         = anthropic$fg,
#   primary    = anthropic$coral,
#   secondary  = anthropic$fg_muted,
#   success    = "#7A9E7E",
#   warning    = "#D97706",
#   danger     = "#C0392B",
#   base_font  = font_google("DM Sans"),
#   heading_font = font_google("DM Serif Display"),
#   `border-radius` = "0.5rem",
#   `box-shadow`    = "0 1px 3px rgba(0,0,0,0.06)"
# )

# ── Quick preview ─────────────────────────────────────────────────────────────

# Run this to preview the theme:
#
# library(ggplot2)
# source("theme_anthropic.R")
#
# ggplot(mpg, aes(displ, hwy, colour = class)) +
#   geom_point(size = 2.5, alpha = 0.85) +
#   scale_colour_anthropic() +
#   theme_anthropic() +
#   labs(
#     title    = "Engine displacement vs fuel efficiency",
#     subtitle = "Each point is a car model; colour encodes vehicle class",
#     x        = "Displacement (L)",
#     y        = "Highway MPG",
#     colour   = NULL,
#     caption  = "Source: EPA fuel economy data"
#   )
