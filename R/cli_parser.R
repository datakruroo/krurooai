# cli_parser.R - Command line argument parsing

library(optparse)

parse_cli_args <- function(args) {
  
  if (length(args) == 0) {
    show_help()
    stop("No command provided")
  }
  
  command <- args[1]
  remaining_args <- args[-1]
  
  switch(command,
    "grade" = parse_grade_args(remaining_args),
    "batch-grade" = parse_batch_grade_args(remaining_args),
    "csv-import" = parse_csv_import_args(remaining_args),
    "init" = parse_init_args(remaining_args),
    "config-check" = parse_config_check_args(remaining_args),
    "test-privacy" = parse_test_privacy_args(remaining_args),
    "help" = {show_help(); return(list(command = "help"))},
    stop("Unknown command: ", command, ". Use 'krurooai help' for usage.")
  )
}

parse_grade_args <- function(args) {
  option_list <- list(
    make_option(c("--context"), type = "character", default = NULL,
                help = "Context markdown file", metavar = "FILE"),
    make_option(c("--mode"), type = "character", default = "local",
                help = "LLM backend mode: local, api, or hybrid", metavar = "MODE"),
    make_option(c("--output"), type = "character", default = NULL,
                help = "Output file path", metavar = "FILE")
  )
  
  parser <- OptionParser(option_list = option_list, usage = "krurooai grade INPUT_FILE [options]")
  opt <- parse_args(parser, args = args, positional_arguments = TRUE)
  
  if (length(opt$args) == 0) {
    stop("Input file required for grade command")
  }
  
  return(list(
    command = "grade",
    input_file = opt$args[1],
    context = opt$options$context,
    mode = opt$options$mode,
    output = opt$options$output
  ))
}

parse_batch_grade_args <- function(args) {
  option_list <- list(
    make_option(c("--context"), type = "character", default = NULL,
                help = "Context markdown file", metavar = "FILE"),
    make_option(c("--mode"), type = "character", default = "local",
                help = "LLM backend mode: local, api, or hybrid", metavar = "MODE"),
    make_option(c("--output-dir"), type = "character", default = "output",
                help = "Output directory", metavar = "DIR"),
    make_option(c("--batch-size"), type = "integer", default = 5,
                help = "Number of files to process in each batch for quality control", metavar = "N")
  )
  
  parser <- OptionParser(option_list = option_list, usage = "krurooai batch-grade DIRECTORY [options]")
  opt <- parse_args(parser, args = args, positional_arguments = TRUE)
  
  if (length(opt$args) == 0) {
    stop("Directory required for batch-grade command")
  }
  
  return(list(
    command = "batch-grade",
    input_dir = opt$args[1],
    context = opt$options$context,
    mode = opt$options$mode,
    output_dir = opt$options$`output-dir`,
    batch_size = opt$options$`batch-size`
  ))
}

parse_init_args <- function(args) {
  option_list <- list(
    make_option(c("--name"), type = "character", default = "krurooai-project",
                help = "Project name", metavar = "NAME"),
    make_option(c("--backends"), type = "character", default = "local",
                help = "Comma-separated backends: local,api", metavar = "BACKENDS")
  )
  
  parser <- OptionParser(option_list = option_list, usage = "krurooai init [options]")
  opt <- parse_args(parser, args = args)
  
  return(list(
    command = "init",
    name = opt$name,
    backends = strsplit(opt$backends, ",")[[1]]
  ))
}

parse_config_check_args <- function(args) {
  return(list(command = "config-check"))
}

parse_csv_import_args <- function(args) {
  option_list <- list(
    make_option(c("--output-dir"), type = "character", default = "submissions",
                help = "Output directory for individual files", metavar = "DIR"),
    make_option(c("--email-column"), type = "character", default = "Email Address",
                help = "Column name for email addresses", metavar = "COLUMN"),
    make_option(c("--timestamp-column"), type = "character", default = "Timestamp",
                help = "Column name for timestamps", metavar = "COLUMN"),
    make_option(c("--score-column"), type = "character", default = "Score",
                help = "Column name for existing scores", metavar = "COLUMN"),
    make_option(c("--skip-columns"), type = "character", default = NULL,
                help = "Comma-separated list of columns to skip", metavar = "COLUMNS"),
    make_option(c("--prefix"), type = "character", default = "student",
                help = "Prefix for output filenames", metavar = "PREFIX"),
    make_option(c("--auto-grade"), action = "store_true", default = FALSE,
                help = "Automatically grade after import"),
    make_option(c("--context"), type = "character", default = NULL,
                help = "Context file for auto-grading", metavar = "FILE")
  )
  
  parser <- OptionParser(option_list = option_list, usage = "krurooai csv-import CSV_FILE [options]")
  opt <- parse_args(parser, args = args, positional_arguments = TRUE)
  
  if (length(opt$args) == 0) {
    stop("CSV file required for csv-import command")
  }
  
  # Parse skip columns
  skip_columns <- c()
  if (!is.null(opt$options$`skip-columns`)) {
    skip_columns <- trimws(strsplit(opt$options$`skip-columns`, ",")[[1]])
  }
  
  return(list(
    command = "csv-import",
    csv_file = opt$args[1],
    output_dir = opt$options$`output-dir`,
    email_column = opt$options$`email-column`,
    timestamp_column = opt$options$`timestamp-column`,
    score_column = opt$options$`score-column`,
    skip_columns = skip_columns,
    prefix = opt$options$prefix,
    auto_grade = opt$options$`auto-grade`,
    context = opt$options$context
  ))
}

parse_test_privacy_args <- function(args) {
  if (length(args) == 0) {
    stop("Input file required for test-privacy command")
  }
  
  return(list(
    command = "test-privacy",
    input_file = args[1]
  ))
}

show_help <- function() {
  cat("KruRooAI - Educational AI Assistant for Grading\n\n")
  cat("Usage:\n")
  cat("  krurooai grade INPUT_FILE --context CONTEXT.md [--mode local|api|hybrid]\n")
  cat("  krurooai batch-grade DIRECTORY --context CONTEXT.md [--mode local|api|hybrid] [--batch-size N]\n")
  cat("  krurooai csv-import CSV_FILE [--output-dir DIR] [--auto-grade --context CONTEXT.md]\n")
  cat("  krurooai init --name PROJECT_NAME --backends local,api\n")
  cat("  krurooai config-check\n")
  cat("  krurooai test-privacy INPUT_FILE\n")
  cat("  krurooai help\n\n")
  cat("Commands:\n")
  cat("  grade        Grade a single file\n")
  cat("  batch-grade  Grade multiple files in a directory (with batch size control)\n")
  cat("  csv-import   Import CSV file and convert to individual submission files\n")
  cat("  init         Initialize a new project\n")
  cat("  config-check Check configuration files\n")
  cat("  test-privacy Test privacy filtering on input file\n")
  cat("  help         Show this help message\n\n")
  cat("Options:\n")
  cat("  --batch-size N    Process files in batches of N (default: 5) for quality control\n")
}