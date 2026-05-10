# 05_evaluate_forecasts.R
# Evaluate leakage-safe volatility forecasting performance

library(dplyr)

preds <- read.csv("outputs/tables/walkforward_volatility_predictions.csv")
preds$date <- as.Date(preds$date)

# -----------------------------
# 1. Evaluation helper function
# -----------------------------
evaluate_forecast <- function(actual, predicted, model_name) {
  
  actual <- as.numeric(actual)
  predicted <- as.numeric(predicted)
  
  # Avoid division issues for QLIKE
  eps <- 1e-8
  predicted_safe <- pmax(predicted, eps)
  actual_safe <- pmax(actual, eps)
  
  rmse <- sqrt(mean((predicted - actual)^2, na.rm = TRUE))
  mae <- mean(abs(predicted - actual), na.rm = TRUE)
  
  qlike <- mean(
    log(predicted_safe^2) + (actual_safe^2 / predicted_safe^2),
    na.rm = TRUE
  )
  
  correlation <- suppressWarnings(
    cor(actual, predicted, use = "complete.obs")
  )
  
  data.frame(
    model = model_name,
    rmse = round(rmse, 6),
    mae = round(mae, 6),
    qlike = round(qlike, 6),
    correlation = round(correlation, 6)
  )
}

# -----------------------------
# 2. Evaluate all models
# -----------------------------
evaluation_summary <- rbind(
  evaluate_forecast(preds$actual_rv_21, preds$hist_avg_pred, "Historical Average"),
  evaluate_forecast(preds$actual_rv_21, preds$lm_pred, "Linear Regression"),
  evaluate_forecast(preds$actual_rv_21, preds$rf_pred, "Random Forest"),
  evaluate_forecast(preds$actual_rv_21, preds$xgb_pred, "XGBoost")
)

# -----------------------------
# 3. Save evaluation summary
# -----------------------------
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

write.csv(
  evaluation_summary,
  "outputs/tables/volatility_model_evaluation.csv",
  row.names = FALSE
)

cat("Volatility forecast evaluation completed successfully.\n")
cat("Output file: outputs/tables/volatility_model_evaluation.csv\n")
cat("\nEvaluation summary:\n")
print(evaluation_summary)