# Shared validation and participant bootstrap helpers.

assert_columns <- function(data, required, dataset_name) {
  missing <- setdiff(required, names(data))
  if (length(missing) > 0) {
    stop(
      dataset_name,
      " is missing required columns: ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  invisible(data)
}

assert_unique_key <- function(data, key, dataset_name) {
  duplicated_rows <- duplicated(data[key])
  if (any(duplicated_rows)) {
    stop(dataset_name, " contains duplicate key rows after cleaning.", call. = FALSE)
  }
  invisible(data)
}

bootstrap_mean <- function(values, iterations = 2000, seed = 20260819) {
  values <- values[is.finite(values)]
  if (length(values) < 2) {
    return(c(low = NA_real_, high = NA_real_))
  }
  set.seed(seed)
  draws <- replicate(
    iterations,
    mean(sample(values, length(values), replace = TRUE))
  )
  stats::quantile(draws, c(0.025, 0.975), names = FALSE, na.rm = TRUE) |>
    stats::setNames(c("low", "high"))
}

safe_coefficient <- function(model, term) {
  coefficients <- stats::coef(model)
  if (!term %in% names(coefficients)) {
    return(NA_real_)
  }
  unname(coefficients[[term]])
}
