# 02_build_features.R
# Build leakage-safe volatility forecasting features

library(dplyr)
library(zoo)
library(TTR)

prices <- read.csv("data/raw/etf_adjusted_prices.csv")
prices$date <- as.Date(prices$date)

# -----------------------------
# 1. Compute daily log returns
# -----------------------------
returns <- prices
returns[-1] <- lapply(prices[-1], function(x) c(NA, diff(log(x))))
returns <- na.omit(returns)

# -----------------------------
# 2. Helper functions
# -----------------------------
rolling_realized_vol <- function(x, window) {
  sqrt(rollapply(
    x^2,
    width = window,
    FUN = sum,
    align = "right",
    fill = NA
  ))
}

rolling_momentum <- function(price, window) {
  price / lag(price, window) - 1
}

moving_average_gap <- function(price, window) {
  ma <- SMA(price, n = window)
  price / ma - 1
}

# -----------------------------
# 3. Build SPY volatility and trend features
# -----------------------------
features <- data.frame(
  date = returns$date,
  spy_return = returns$SPY,
  qqq_return = returns$QQQ,
  iwm_return = returns$IWM,
  tlt_return = returns$TLT,
  gld_return = returns$GLD,
  vxx_return = returns$VXX
)

features$rv_5 <- rolling_realized_vol(features$spy_return, 5)
features$rv_10 <- rolling_realized_vol(features$spy_return, 10)
features$rv_21 <- rolling_realized_vol(features$spy_return, 21)
features$rv_63 <- rolling_realized_vol(features$spy_return, 63)

# Align price-based features with returns date after first return observation
price_aligned <- prices[-1, ]

features$momentum_21 <- rolling_momentum(price_aligned$SPY, 21)
features$momentum_63 <- rolling_momentum(price_aligned$SPY, 63)

features$ma_gap_21 <- moving_average_gap(price_aligned$SPY, 21)
features$ma_gap_63 <- moving_average_gap(price_aligned$SPY, 63)

features <- na.omit(features)

# -----------------------------
# 4. Save features
# -----------------------------
dir.create("data/processed", recursive = TRUE, showWarnings = FALSE)

write.csv(
  features,
  "data/processed/features.csv",
  row.names = FALSE
)

cat("Volatility forecasting features built successfully.\n")
cat("Output file: data/processed/features.csv\n")
cat("Number of observations:", nrow(features), "\n")
cat("Number of features:", ncol(features) - 1, "\n")