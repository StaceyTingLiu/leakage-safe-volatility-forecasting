# run_pipeline.R
# Run full leakage-safe volatility forecasting benchmark pipeline

source("scripts/01_download_data.R")
source("scripts/02_build_features.R")
source("scripts/03_define_volatility_targets.R")
source("scripts/04_walkforward_models.R")
source("scripts/05_evaluate_forecasts.R")
source("scripts/06_generate_figures.R")

cat("Full volatility forecasting pipeline completed successfully.\n")