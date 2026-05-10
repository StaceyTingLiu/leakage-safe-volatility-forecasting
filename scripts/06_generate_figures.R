# 06_generate_figures.R
# Generate visualization outputs for leakage-safe volatility forecasting benchmark

library(dplyr)
library(ggplot2)
library(tidyr)

preds <- read.csv("outputs/tables/walkforward_volatility_predictions.csv")
eval_table <- read.csv("outputs/tables/volatility_model_evaluation.csv")

preds$date <- as.Date(preds$date)

dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)

# -----------------------------
# Helper: save readable PNG
# -----------------------------
save_plot_png <- function(plot_obj, filename, width = 14, height = 7, res = 300) {
  ggplot2::ggsave(
    filename = filename,
    plot = plot_obj,
    width = width,
    height = height,
    dpi = res,
    bg = "white",
    device = "png"
  )
}

# -----------------------------
# Common theme
# -----------------------------
my_theme <- theme_bw(base_size = 18) +
  theme(
    plot.title = element_text(size = 20, face = "bold", color = "black"),
    plot.subtitle = element_text(size = 15, color = "black"),
    axis.title = element_text(size = 16, face = "bold", color = "black"),
    axis.text = element_text(size = 14, color = "black"),
    legend.title = element_text(size = 15, face = "bold", color = "black"),
    legend.text = element_text(size = 14, color = "black"),
    legend.position = "right",
    panel.background = element_rect(fill = "white", color = "black"),
    plot.background = element_rect(fill = "white", color = "white"),
    legend.background = element_rect(fill = "white", color = "white"),
    legend.key = element_rect(fill = "white", color = "white"),
    panel.grid.major = element_line(color = "grey85", linewidth = 0.7),
    panel.grid.minor = element_line(color = "grey92", linewidth = 0.4)
  )

# -----------------------------
# Figure 1: Actual vs XGBoost predicted volatility
# -----------------------------
p1 <- ggplot(preds, aes(x = date)) +
  geom_line(aes(y = actual_rv_21, color = "Actual 21-Day RV"), linewidth = 1.0) +
  geom_line(aes(y = xgb_pred, color = "XGBoost Forecast"), linewidth = 0.9, alpha = 0.9) +
  scale_color_manual(
    values = c(
      "Actual 21-Day RV" = "firebrick",
      "XGBoost Forecast" = "steelblue4"
    )
  ) +
  labs(
    title = "Actual vs Predicted 21-Day Realized Volatility",
    subtitle = "XGBoost walk-forward volatility forecast compared with realized volatility",
    x = "Date",
    y = "Realized Volatility",
    color = "Series"
  ) +
  my_theme

save_plot_png(
  p1,
  "outputs/figures/actual_vs_xgboost_volatility.png"
)

# -----------------------------
# Figure 2: Model RMSE comparison
# -----------------------------
p2 <- ggplot(eval_table, aes(x = reorder(model, rmse), y = rmse, fill = model)) +
  geom_col(width = 0.65) +
  coord_flip() +
  labs(
    title = "Volatility Forecasting Model Comparison",
    subtitle = "Lower RMSE indicates better forecasting accuracy",
    x = "Model",
    y = "RMSE"
  ) +
  my_theme +
  theme(legend.position = "none")

save_plot_png(
  p2,
  "outputs/figures/model_rmse_comparison.png",
  width = 12,
  height = 7
)

# -----------------------------
# Figure 3: Forecast error timeline
# -----------------------------
preds$xgb_error <- preds$xgb_pred - preds$actual_rv_21

p3 <- ggplot(preds, aes(x = date, y = xgb_error)) +
  geom_line(color = "darkorange3", linewidth = 0.9) +
  geom_hline(yintercept = 0, color = "black", linetype = "dashed", linewidth = 0.8) +
  labs(
    title = "XGBoost Forecast Error Timeline",
    subtitle = "Forecast error = predicted realized volatility minus actual realized volatility",
    x = "Date",
    y = "Forecast Error"
  ) +
  my_theme

save_plot_png(
  p3,
  "outputs/figures/xgboost_forecast_error_timeline.png"
)

# -----------------------------
# Figure 4: All model forecasts
# -----------------------------
forecast_long <- preds %>%
  select(
    date,
    actual_rv_21,
    hist_avg_pred,
    lm_pred,
    rf_pred,
    xgb_pred
  ) %>%
  pivot_longer(
    cols = -date,
    names_to = "series",
    values_to = "volatility"
  )

forecast_long$series <- recode(
  forecast_long$series,
  actual_rv_21 = "Actual RV",
  hist_avg_pred = "Historical Average",
  lm_pred = "Linear Regression",
  rf_pred = "Random Forest",
  xgb_pred = "XGBoost"
)

p4 <- ggplot(forecast_long, aes(x = date, y = volatility, color = series)) +
  geom_line(linewidth = 0.8, alpha = 0.85) +
  labs(
    title = "Walk-Forward Volatility Forecasts",
    subtitle = "Actual and predicted 21-day realized volatility across benchmark models",
    x = "Date",
    y = "Realized Volatility",
    color = "Series"
  ) +
  my_theme

save_plot_png(
  p4,
  "outputs/figures/all_model_volatility_forecasts.png",
  width = 14,
  height = 8
)

# -----------------------------
# Figure 5: Actual volatility regime timeline
# -----------------------------
preds$volatility_regime <- cut(
  preds$actual_rv_21,
  breaks = quantile(preds$actual_rv_21, probs = c(0, 0.33, 0.66, 1), na.rm = TRUE),
  include.lowest = TRUE,
  labels = c("Low", "Medium", "High")
)

preds$volatility_regime <- factor(
  preds$volatility_regime,
  levels = c("Low", "Medium", "High")
)

p5 <- ggplot(preds, aes(x = date, y = actual_rv_21, color = volatility_regime)) +
  geom_point(size = 2.0, alpha = 0.85) +
  scale_color_manual(
    values = c(
      "Low" = "forestgreen",
      "Medium" = "darkorange",
      "High" = "red3"
    )
  ) +
  labs(
    title = "Realized Volatility Regime Timeline",
    subtitle = "Low / Medium / High regimes based on realized 21-day volatility terciles",
    x = "Date",
    y = "Actual 21-Day Realized Volatility",
    color = "Volatility Regime"
  ) +
  my_theme

save_plot_png(
  p5,
  "outputs/figures/volatility_regime_timeline.png"
)

cat("Figure generation completed successfully.\n")
cat("Created figures:\n")
cat("outputs/figures/actual_vs_xgboost_volatility.png\n")
cat("outputs/figures/model_rmse_comparison.png\n")
cat("outputs/figures/xgboost_forecast_error_timeline.png\n")
cat("outputs/figures/all_model_volatility_forecasts.png\n")
cat("outputs/figures/volatility_regime_timeline.png\n")