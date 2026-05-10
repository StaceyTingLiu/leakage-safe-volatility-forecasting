# Technical Report: Leakage-Safe Volatility Forecasting Benchmark

## 1. Executive Summary

This project develops a leakage-safe volatility forecasting benchmark system for financial risk monitoring and decision-support research. The system forecasts future realized volatility for SPY using ETF market data, historical volatility indicators, trend features, cross-asset return signals, and walk-forward machine-learning models.

The project compares four benchmark models: Historical Average, Linear Regression, Random Forest, and XGBoost. Forecasts are evaluated using RMSE, MAE, QLIKE, and prediction-realization correlation.

The project is designed as a reproducible research and decision-support framework rather than a trading-alpha strategy. Its main contribution is to demonstrate how volatility forecasting can be implemented under realistic walk-forward constraints while avoiding look-ahead bias and data leakage.

This project supports a broader research direction in leakage-safe AI/ML systems for financial risk forecasting, volatility monitoring, market fragility detection, and market-stress early warning.

## 2. Problem Statement

Volatility forecasting is a central problem in financial risk management. Volatility affects portfolio risk, margin requirements, hedging decisions, risk budgeting, drawdown monitoring, and volatility-targeting strategies.

Traditional volatility models and machine-learning methods can both be useful, but financial forecasting systems are especially vulnerable to unrealistic evaluation. If future information enters feature construction, scaling, model training, or model selection, the reported forecast performance may be overly optimistic.

The core problem addressed by this project is how to forecast future realized volatility using a transparent and reproducible machine-learning benchmark while preserving timing discipline. The project asks whether machine-learning models can forecast future SPY realized volatility under realistic walk-forward constraints using only information available at the prediction date.

## 3. Objective

The objective of this project is to build a leakage-safe volatility forecasting benchmark system for financial risk monitoring.

The project has six main goals:

1. Download ETF adjusted price data.
2. Construct historical volatility, return, momentum, moving-average, and cross-asset features.
3. Define future realized-volatility targets.
4. Train benchmark forecasting models under a walk-forward design.
5. Evaluate volatility forecast performance using multiple error metrics.
6. Generate tables and figures that make the forecasting results interpretable.

The project is intended to support research in financial risk monitoring, volatility forecasting, and AI-assisted decision-support systems.

## 4. Data and Asset Universe

The project uses daily adjusted ETF price data downloaded from Yahoo Finance through the `quantmod` package in R.

The asset universe includes SPY as the main U.S. equity-market benchmark and several cross-asset ETF predictors.

### Target Benchmark

- SPY: S&P 500 ETF

### Cross-Asset Predictors

- QQQ: Nasdaq-100 ETF
- IWM: Russell 2000 ETF
- TLT: Long-term U.S. Treasury ETF
- GLD: Gold ETF
- VXX: Volatility-linked ETF

This asset universe allows the system to capture broad equity-market behavior, growth-stock sensitivity, small-cap sensitivity, bond-market movement, gold-market behavior, and volatility-linked market stress.

## 5. Data Processing

The first script downloads adjusted ETF prices and saves the raw data to:

```text
data/raw/etf_adjusted_prices.csv
```

The second script computes daily log returns and constructs volatility forecasting features.

The main processed feature file is saved to:

```text
data/processed/features.csv
```

The model-ready dataset with future realized-volatility targets is saved to:

```text
data/processed/model_dataset.csv
```

Daily log returns are used because they are standard in financial time-series analysis and are suitable for volatility construction.

## 6. Feature Engineering

The project constructs several categories of features.

### 6.1 Daily Return Features

The system calculates daily log returns for SPY and cross-asset ETFs. These include:

- SPY return
- QQQ return
- IWM return
- TLT return
- GLD return
- VXX return

These variables provide information about equity-market movement, small-cap behavior, bond-market behavior, gold-market behavior, and volatility-linked stress.

### 6.2 Historical Realized Volatility Features

The system constructs historical realized volatility measures using SPY returns over several lookback windows:

- 5-day realized volatility
- 10-day realized volatility
- 21-day realized volatility
- 63-day realized volatility

These features capture short-term, medium-term, and longer-horizon volatility conditions.

### 6.3 Momentum Features

The system constructs SPY momentum features over:

- 21 trading days
- 63 trading days

Momentum features help capture recent trend behavior, which may be related to future volatility conditions.

### 6.4 Moving-Average Gap Features

The system constructs moving-average gap features over:

- 21 trading days
- 63 trading days

The moving-average gap measures how far the current price is from a recent moving average. This helps capture trend deviation and potential market stress.

## 7. Target Variable Construction

The project defines future realized-volatility targets using future SPY returns.

The future realized volatility over horizon \(h\) is calculated as:

```text
future_rv_h = sqrt(sum of squared future SPY returns over the next h trading days)
```

The project constructs three targets:

```text
future_rv_5
future_rv_10
future_rv_21
```

The main modeling script uses `future_rv_21` as the primary target. This target represents future 21-trading-day realized volatility.

The model dataset is saved to:

```text
data/processed/model_dataset.csv
```

## 8. Leakage-Safe Design

The project emphasizes leakage-safe financial forecasting design.

The key leakage-safe principles are:

- data are split chronologically
- models are trained only on past data
- test observations are always out-of-sample
- feature scaling is based only on training-period statistics
- future realized volatility is used only as the prediction target
- no random train/test split is used

This is important because financial data are time-dependent. Random splitting can allow future market regimes to influence training and produce unrealistic results.

The project uses a walk-forward design to better approximate real-time forecasting.

## 9. Walk-Forward Forecasting Design

The walk-forward forecasting process works as follows:

1. Use an initial historical training sample.
2. Train each model on the available training data.
3. Predict the next out-of-sample test window.
4. Expand the training window forward.
5. Repeat until the end of the dataset.

The project uses:

- initial training size: 1000 observations
- test window: 63 trading days
- primary target: future 21-day realized volatility

The predictions are saved to:

```text
outputs/tables/walkforward_volatility_predictions.csv
```

This file includes:

- date
- actual 21-day realized volatility
- Historical Average forecast
- Linear Regression forecast
- Random Forest forecast
- XGBoost forecast
- training end date

## 10. Model Set

The current version includes four benchmark models.

### 10.1 Historical Average

The Historical Average model predicts future volatility using the average historical target value in the training sample. It provides a simple benchmark.

### 10.2 Linear Regression

Linear Regression provides an interpretable statistical baseline. It estimates future realized volatility as a linear function of the volatility, return, momentum, moving-average, and cross-asset features.

### 10.3 Random Forest

Random Forest is a nonlinear machine-learning model that can capture feature interactions and nonlinear relationships. It provides a flexible benchmark for volatility forecasting.

### 10.4 XGBoost

XGBoost is a gradient-boosting model that can capture nonlinear patterns and interaction effects. It is included as a modern machine-learning benchmark.

## 11. Evaluation Metrics

The project evaluates volatility forecasting performance using four metrics.

### 11.1 RMSE

Root Mean Squared Error measures the square root of the average squared forecast error. Lower RMSE indicates better forecasting accuracy.

### 11.2 MAE

Mean Absolute Error measures the average absolute forecast error. Lower MAE indicates better average forecast accuracy.

### 11.3 QLIKE

QLIKE is commonly used in volatility forecasting evaluation. It penalizes poor volatility forecasts and is useful when evaluating variance or volatility prediction performance.

### 11.4 Prediction-Realization Correlation

Prediction-realization correlation measures the relationship between predicted and realized volatility. A higher correlation indicates that the forecast captures variation in realized volatility more effectively.

The evaluation summary is saved to:

```text
outputs/tables/volatility_model_evaluation.csv
```

## 12. Output Files

The project generates several categories of output files.

### 12.1 Raw Data

```text
data/raw/etf_adjusted_prices.csv
```

### 12.2 Processed Data

```text
data/processed/features.csv
data/processed/model_dataset.csv
```

### 12.3 Forecast and Evaluation Tables

```text
outputs/tables/walkforward_volatility_predictions.csv
outputs/tables/volatility_model_evaluation.csv
```

### 12.4 Figures

```text
outputs/figures/actual_vs_xgboost_volatility.png
outputs/figures/model_rmse_comparison.png
outputs/figures/xgboost_forecast_error_timeline.png
outputs/figures/all_model_volatility_forecasts.png
outputs/figures/volatility_regime_timeline.png
```

## 13. Visualization Outputs

The project generates several figures to make the forecasting results interpretable.

### 13.1 Actual vs XGBoost Predicted Volatility

This figure compares actual 21-day realized volatility with the XGBoost walk-forward forecast.

### 13.2 Model RMSE Comparison

This figure compares models based on RMSE. Lower RMSE indicates better forecasting accuracy.

### 13.3 XGBoost Forecast Error Timeline

This figure shows the difference between the XGBoost predicted volatility and actual realized volatility over time.

### 13.4 All Model Volatility Forecasts

This figure compares actual volatility and forecasts from all benchmark models.

### 13.5 Realized Volatility Regime Timeline

This figure classifies realized volatility into low, medium, and high regimes based on realized volatility terciles.

## 14. Practical Use Case

This project can support financial risk monitoring and decision-support research.

Potential use cases include:

- volatility monitoring
- portfolio risk review
- volatility-targeting research
- market-risk dashboard development
- stress-period analysis
- AI-assisted financial decision support
- benchmark comparison for volatility forecasting models

The system is designed to help analysts understand future volatility conditions rather than to provide direct investment recommendations.

## 15. Relationship to Broader Research Direction

This project supports a broader research direction in leakage-safe AI/ML for financial risk forecasting, volatility monitoring, market fragility detection, and market-stress early warning.

It complements other projects in the same research portfolio:

1. A financial risk warning system focused on drawdown-risk early warning.
2. This volatility forecasting benchmark focused on future realized volatility prediction.
3. A market fragility risk monitor focused on systemic risk and market-structure fragility.

Together, these projects demonstrate a coherent implementation portfolio in AI-assisted financial risk monitoring.

## 16. Limitations

This project has several limitations.

First, the current version uses ETF market data only. It does not include macroeconomic variables, credit spreads, liquidity indicators, option-implied volatility surfaces, earnings information, or intraday data.

Second, the current modeling target focuses on future 21-day realized volatility for SPY. Different assets, horizons, or volatility definitions may produce different results.

Third, the current model set includes Historical Average, Linear Regression, Random Forest, and XGBoost. Additional models such as GARCH, GJR-GARCH, Elastic Net, LSTM, or Transformer-based models may provide useful extensions.

Fourth, this project is designed for research and decision-support demonstration. It does not provide investment advice and does not guarantee accurate prediction of future volatility.

## 17. Future Work

Future versions may extend the framework in several ways:

- add macroeconomic indicators
- include credit-market and liquidity indicators
- include option-implied volatility data
- add GARCH and GJR-GARCH benchmarks
- add Elastic Net and other regularized models
- evaluate multiple forecast horizons
- test multiple target assets
- add interpretability analysis
- build an interactive Shiny dashboard
- add volatility-targeting backtest overlays
- conduct broader robustness checks across historical regimes

## 18. Conclusion

This project implements a reproducible leakage-safe volatility forecasting benchmark system using ETF market data and walk-forward machine-learning models.

The system constructs volatility and cross-asset features, defines future realized-volatility targets, trains benchmark forecasting models, evaluates forecast performance, and generates interpretable visualization outputs.

The main contribution of the project is not a trading strategy, but a practical and reproducible volatility forecasting framework for financial risk monitoring and decision support. By emphasizing timing discipline, leakage-safe evaluation, and benchmark comparison, the project supports a broader research agenda in leakage-safe AI/ML systems for financial risk forecasting, volatility monitoring, market fragility detection, and market-stress early warning.