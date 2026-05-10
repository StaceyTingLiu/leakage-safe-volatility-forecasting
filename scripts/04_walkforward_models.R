# 04_walkforward_models.R
# Leakage-safe walk-forward volatility forecasting models

library(dplyr)
library(randomForest)
library(xgboost)

dataset <- read.csv("data/processed/model_dataset.csv")
dataset$date <- as.Date(dataset$date)

# -----------------------------
# 1. Define features and target
# -----------------------------
feature_cols <- c(
  "spy_return",
  "qqq_return",
  "iwm_return",
  "tlt_return",
  "gld_return",
  "vxx_return",
  "rv_5",
  "rv_10",
  "rv_21",
  "rv_63",
  "momentum_21",
  "momentum_63",
  "ma_gap_21",
  "ma_gap_63"
)

target_col <- "future_rv_21"

# -----------------------------
# 2. Walk-forward settings
# -----------------------------
initial_train_size <- 1000
test_window <- 63

results <- data.frame()

# -----------------------------
# 3. Walk-forward loop
# -----------------------------
for (start_idx in seq(initial_train_size, nrow(dataset) - test_window, by = test_window)) {
  
  train_data <- dataset[1:start_idx, ]
  test_data <- dataset[(start_idx + 1):(start_idx + test_window), ]
  
  x_train <- train_data[, feature_cols]
  y_train <- train_data[, target_col]
  
  x_test <- test_data[, feature_cols]
  y_test <- test_data[, target_col]
  
  # Leakage-safe scaling:
  # training mean and sd are calculated only from training data
  train_mean <- sapply(x_train, mean, na.rm = TRUE)
  train_sd <- sapply(x_train, sd, na.rm = TRUE)
  train_sd[train_sd == 0] <- 1
  
  x_train_scaled <- as.data.frame(scale(x_train, center = train_mean, scale = train_sd))
  x_test_scaled <- as.data.frame(scale(x_test, center = train_mean, scale = train_sd))
  
  # -----------------------------
  # Model 1: Historical Average
  # -----------------------------
  hist_avg_pred <- rep(mean(y_train, na.rm = TRUE), nrow(test_data))
  
  # -----------------------------
  # Model 2: Linear Regression
  # -----------------------------
  lm_train_df <- data.frame(
    future_rv_21 = y_train,
    x_train_scaled
  )
  
  lm_test_df <- data.frame(
    future_rv_21 = y_test,
    x_test_scaled
  )
  
  lm_model <- lm(future_rv_21 ~ ., data = lm_train_df)
  
  lm_pred <- predict(
    lm_model,
    newdata = lm_test_df
  )
  
  # Avoid negative volatility forecasts
  lm_pred <- pmax(lm_pred, 0)
  
  # -----------------------------
  # Model 3: Random Forest
  # -----------------------------
  rf_train_df <- data.frame(
    future_rv_21 = y_train,
    x_train_scaled
  )
  
  rf_model <- randomForest(
    future_rv_21 ~ .,
    data = rf_train_df,
    ntree = 300
  )
  
  rf_pred <- predict(
    rf_model,
    newdata = x_test_scaled
  )
  
  rf_pred <- pmax(rf_pred, 0)
  
  # -----------------------------
  # Model 4: XGBoost
  # -----------------------------
  xgb_train <- xgb.DMatrix(
    data = as.matrix(x_train_scaled),
    label = y_train
  )
  
  xgb_test <- xgb.DMatrix(
    data = as.matrix(x_test_scaled),
    label = y_test
  )
  
  xgb_params <- list(
    objective = "reg:squarederror",
    eval_metric = "rmse",
    max_depth = 3,
    eta = 0.05,
    subsample = 0.8,
    colsample_bytree = 0.8
  )
  
  xgb_model <- xgb.train(
    params = xgb_params,
    data = xgb_train,
    nrounds = 150,
    verbose = 0
  )
  
  xgb_pred <- predict(
    xgb_model,
    newdata = xgb_test
  )
  
  xgb_pred <- pmax(xgb_pred, 0)
  
  # -----------------------------
  # Save fold results
  # -----------------------------
  fold_results <- data.frame(
    date = test_data$date,
    actual_rv_21 = y_test,
    hist_avg_pred = hist_avg_pred,
    lm_pred = lm_pred,
    rf_pred = rf_pred,
    xgb_pred = xgb_pred,
    train_end_date = train_data$date[nrow(train_data)]
  )
  
  results <- rbind(results, fold_results)
  
  cat("Finished fold ending at:", as.character(train_data$date[nrow(train_data)]), "\n")
}

# -----------------------------
# 4. Save predictions
# -----------------------------
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

write.csv(
  results,
  "outputs/tables/walkforward_volatility_predictions.csv",
  row.names = FALSE
)

cat("Walk-forward volatility forecasts saved successfully.\n")
cat("Output file: outputs/tables/walkforward_volatility_predictions.csv\n")
cat("Number of prediction rows:", nrow(results), "\n")
cat("Models included: Historical Average, Linear Regression, Random Forest, XGBoost\n")