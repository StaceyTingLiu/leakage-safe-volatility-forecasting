# 03_define_volatility_targets.R
# Define future realized volatility forecasting targets

library(dplyr)
library(zoo)

features <- read.csv("data/processed/features.csv")
features$date <- as.Date(features$date)

# -----------------------------
# 1. Helper function for future realized volatility
# -----------------------------
future_realized_vol <- function(x, horizon) {
  target <- rep(NA, length(x))
  
  for (i in 1:(length(x) - horizon)) {
    future_returns <- x[(i + 1):(i + horizon)]
    target[i] <- sqrt(sum(future_returns^2, na.rm = TRUE))
  }
  
  return(target)
}

# -----------------------------
# 2. Define future volatility targets
# -----------------------------
features$future_rv_5 <- future_realized_vol(features$spy_return, 5)
features$future_rv_10 <- future_realized_vol(features$spy_return, 10)
features$future_rv_21 <- future_realized_vol(features$spy_return, 21)

# Remove rows without future targets
model_dataset <- features %>%
  na.omit()

# -----------------------------
# 3. Save model dataset
# -----------------------------
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

write.csv(
  model_dataset,
  "data/processed/model_dataset.csv",
  row.names = FALSE
)

cat("Future realized volatility targets created successfully.\n")
cat("Output file: data/processed/model_dataset.csv\n")
cat("Number of observations:", nrow(model_dataset), "\n")
cat("Targets included:\n")
cat("- future_rv_5\n")
cat("- future_rv_10\n")
cat("- future_rv_21\n")