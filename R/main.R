#!/usr/bin/env Rscript

# main.R - CLI entry point for KruRooAI
# Educational AI Assistant for grading and assessment

library(optparse)
library(jsonlite)

source("R/cli_parser.R")
source("R/context_processor.R")
source("R/privacy_filter.R")
source("R/report_generator.R")
source("R/config_manager.R")

main <- function() {
  args <- parse_cli_args(commandArgs(trailingOnly = TRUE))
  
  # Load configuration
  config <- load_config("config/llm.yaml")
  privacy_config <- load_config("config/privacy.yaml")
  
  # Execute command based on parsed arguments
  switch(args$command,
    "grade" = execute_grade(args, config, privacy_config),
    "batch-grade" = execute_batch_grade(args, config, privacy_config),
    "csv-import" = execute_csv_import(args, config, privacy_config),
    "init" = execute_init(args),
    "config-check" = execute_config_check(config, privacy_config),
    "test-privacy" = execute_test_privacy(args, privacy_config),
    "help" = invisible(TRUE), # Help already shown in parser
    stop("Unknown command: ", args$command)
  )
}

execute_grade <- function(args, config, privacy_config) {
  # Validate inputs
  if (!file.exists(args$input_file)) {
    stop("Input file not found: ", args$input_file)
  }
  
  if (!is.null(args$context) && !file.exists(args$context)) {
    stop("Context file not found: ", args$context)
  }
  
  cat("Processing grade command...\n")
  cat("Input file:", args$input_file, "\n")
  cat("Context:", args$context %||% "None", "\n")
  cat("Mode:", args$mode, "\n\n")
  
  # Read student submission
  student_text <- paste(readLines(args$input_file, warn = FALSE), collapse = "\n")
  
  # Process context if provided
  context <- NULL
  if (!is.null(args$context)) {
    context <- process_context_md(args$context)
    cat("Context loaded successfully!\n")
    cat("Assignment:", context$title, "\n\n")
  }
  
  # Apply privacy filter
  privacy_result <- apply_privacy_filter(student_text, privacy_config)
  cat("Privacy filter applied - detected", length(privacy_result$restoration_map), "sensitive items\n\n")
  
  # Call LLM for grading
  cat("=== CALLING LLM FOR GRADING ===\n")
  
  # Prepare context for LLM
  llm_context <- list()
  if (!is.null(context)) {
    llm_context <- list(
      question = context$question %||% "",
      standard_answer = context$standard_answer %||% "",
      grading_criteria = context$grading_criteria %||% "",
      notes = context$notes %||% ""
    )
  }
  
  # Call LLM router via Python
  cat("Calling LLM backend:", args$mode, "\n")
  
  # Prepare Python command
  python_cmd <- sprintf(
    "python3 python/llm_router.py '%s' '%s' '%s' '%s'",
    gsub("'", "\\'", privacy_result$filtered_text),
    gsub("'", "\\'", jsonlite::toJSON(llm_context, auto_unbox = TRUE)),
    args$mode,
    gsub("'", "\\'", jsonlite::toJSON(config, auto_unbox = TRUE))
  )
  
  # Execute Python command
  tryCatch({
    llm_output <- system(python_cmd, intern = TRUE)
    llm_response <- jsonlite::fromJSON(paste(llm_output, collapse = "\n"))
    
    if (!is.null(llm_response$error) && llm_response$error) {
      cat("LLM Error:", llm_response$message, "\n")
      cat("Falling back to mock grading...\n")
      llm_response <- create_fallback_results(student_text)
    }
    
    # Restore privacy context in results
    if (!is.null(llm_response$feedback)) {
      llm_response$feedback <- restore_privacy_context(llm_response$feedback, privacy_result$restoration_map)
    }
    
    llm_results <- llm_response
    
  }, error = function(e) {
    cat("Error calling LLM:", e$message, "\n")
    cat("Falling back to mock grading...\n")
    llm_results <<- create_fallback_results(student_text)
  })
  
  # Ensure student_id is properly set
  llm_results$student_id <- "[STUDENT]"
  
  # Generate report
  report <- generate_report(llm_results, "default", args$output)
  
  cat("\nGrading completed successfully!\n")
  if (!is.null(args$output)) {
    cat("Report saved to:", args$output, "\n")
  }
  
  return(invisible(llm_results))
}

create_fallback_results <- function(student_text) {
  # Simple analysis for fallback
  word_count <- length(strsplit(student_text, "\\s+")[[1]])
  has_steps <- grepl("ขั้นตอน|1\\)|2\\)|3\\)", student_text)
  has_answer <- grepl("คำตอบ|x = ", student_text)
  has_check <- grepl("ตรวจสอบ", student_text)
  
  # Calculate fallback score
  base_score <- 50
  if (has_steps) base_score <- base_score + 20
  if (has_answer) base_score <- base_score + 20
  if (has_check) base_score <- base_score + 10
  
  return(list(
    total_score = base_score,
    student_id = "[STUDENT]",
    breakdown = list(
      accuracy = ceiling(base_score * 0.4),
      method = ceiling(base_score * 0.4),
      presentation = ceiling(base_score * 0.2)
    ),
    feedback = paste("งานนี้มีความยาว", word_count, "คำ",
                    if(has_steps) "แสดงขั้นตอนชัดเจน" else "ขาดขั้นตอน",
                    if(has_answer) "มีคำตอบ" else "ไม่มีคำตอบ",
                    if(has_check) "มีการตรวจสอบ" else "ไม่มีการตรวจสอบ",
                    "(Fallback grading)"),
    model_used = "fallback-analyzer",
    confidence = 0.3,
    error = FALSE
  ))
}

execute_csv_import <- function(args, config, privacy_config) {
  cat("=== CSV IMPORT ===\n")
  cat("Processing CSV file:", args$csv_file, "\n")
  
  # Validate CSV file
  if (!file.exists(args$csv_file)) {
    stop("CSV file not found: ", args$csv_file)
  }
  
  # Prepare Python command
  python_cmd <- sprintf(
    "python3 python/csv_processor.py '%s' --output-dir '%s' --email-column '%s' --timestamp-column '%s' --score-column '%s' --prefix '%s'",
    args$csv_file,
    args$output_dir,
    args$email_column,
    args$timestamp_column,
    args$score_column,
    args$prefix
  )
  
  # Add skip columns if provided
  if (length(args$skip_columns) > 0) {
    skip_cols <- paste(args$skip_columns, collapse = ",")
    python_cmd <- paste(python_cmd, sprintf("--skip-columns '%s'", skip_cols))
  }
  
  # Add auto-grade options if requested
  if (args$auto_grade && !is.null(args$context)) {
    if (!file.exists(args$context)) {
      stop("Context file not found for auto-grading: ", args$context)
    }
    python_cmd <- paste(python_cmd, sprintf("--auto-grade --context '%s'", args$context))
  }
  
  cat("Running:", python_cmd, "\n\n")
  
  # Execute Python script
  tryCatch({
    result <- system(python_cmd, intern = FALSE)
    
    if (result == 0) {
      cat("\n✅ CSV import completed successfully!\n")
      
      # If auto-grade was requested, run batch grading
      if (args$auto_grade && !is.null(args$context)) {
        cat("\n=== AUTO-GRADING IMPORTED FILES ===\n")
        
        # Create batch-grade args
        batch_args <- list(
          command = "batch-grade",
          input_dir = args$output_dir,
          context = args$context,
          mode = "local",
          output_dir = "reports"
        )
        
        # Run batch grading
        execute_batch_grade(batch_args, config, privacy_config)
      }
      
      # Show usage instructions
      cat("\n💡 Next steps:\n")
      cat("   1. Review created files in:", args$output_dir, "\n")
      if (!args$auto_grade) {
        cat("   2. Create context file with questions and answers\n")
        cat("   3. Run batch grading:\n")
        cat("      ./bin/krurooai batch-grade", args$output_dir, "--context your_context.md\n")
      } else {
        cat("   2. Check reports in: reports/\n")
      }
      
    } else {
      stop("CSV processing failed with exit code: ", result)
    }
    
  }, error = function(e) {
    cat("❌ CSV import failed:", e$message, "\n")
    stop(e$message)
  })
  
  return(invisible(TRUE))
}

execute_batch_grade <- function(args, config, privacy_config) {
  cat("Batch grade command - placeholder\n")
}

execute_init <- function(args) {
  cat("Init command - placeholder\n")
}

execute_config_check <- function(config, privacy_config) {
  cat("=== CONFIGURATION CHECK ===\n\n")
  
  # Check LLM config
  cat("1. LLM Configuration:\n")
  tryCatch({
    validate_llm_config(config)
    cat("   ✅ LLM config is valid\n")
    cat("   - Default backend:", config$default_backend %||% "local", "\n")
    
    if (!is.null(config$backends$local)) {
      cat("   - Local model:", config$backends$local$model, "\n")
      cat("   - Local endpoint:", config$backends$local$endpoint, "\n")
    }
    
    if (!is.null(config$backends$openai)) {
      cat("   - OpenAI model:", config$backends$openai$model, "\n")
      api_key_var <- config$backends$openai$api_key_env
      api_key_exists <- Sys.getenv(api_key_var) != ""
      cat("   - API key (", api_key_var, "):", if(api_key_exists) "✅ Found" else "❌ Not found", "\n")
    }
  }, error = function(e) {
    cat("   ❌ LLM config error:", e$message, "\n")
  })
  
  cat("\n")
  
  # Check Privacy config
  cat("2. Privacy Configuration:\n")
  tryCatch({
    validate_privacy_config(privacy_config)
    cat("   ✅ Privacy config is valid\n")
    
    patterns_count <- length(privacy_config$sensitive_patterns %||% list())
    cat("   - Sensitive patterns:", patterns_count, "\n")
    
    has_redaction <- !is.null(privacy_config$redaction_rules)
    cat("   - Redaction rules:", if(has_redaction) "✅ Configured" else "⚠️  None", "\n")
    
    privacy_level <- privacy_config$default_privacy_level %||% "moderate"
    cat("   - Privacy level:", privacy_level, "\n")
    
  }, error = function(e) {
    cat("   ❌ Privacy config error:", e$message, "\n")
  })
  
  cat("\n")
  
  # Check dependencies
  cat("3. Dependencies:\n")
  
  # Check R packages
  required_packages <- c("optparse", "yaml", "jsonlite")
  for (pkg in required_packages) {
    if (require(pkg, character.only = TRUE, quietly = TRUE)) {
      cat("   ✅ R package:", pkg, "\n")
    } else {
      cat("   ❌ R package missing:", pkg, "\n")
    }
  }
  
  # Check Python and modules
  python_check <- system("python3 --version", ignore.stdout = TRUE, ignore.stderr = TRUE)
  cat("   ", if(python_check == 0) "✅" else "❌", "Python 3\n")
  
  requests_check <- system("python3 -c 'import requests'", ignore.stdout = TRUE, ignore.stderr = TRUE)
  cat("   ", if(requests_check == 0) "✅" else "❌", "Python requests module\n")
  
  cat("\n")
  
  # Check LLM backends
  cat("4. LLM Backend Status:\n")
  
  # Check local LLM (Ollama)
  ollama_check <- system("curl -s http://localhost:11434/api/tags", ignore.stdout = TRUE, ignore.stderr = TRUE)
  if (ollama_check == 0) {
    cat("   ✅ Ollama server (localhost:11434)\n")
    # Try to get model list
    tryCatch({
      models_result <- system("curl -s http://localhost:11434/api/tags", intern = TRUE)
      cat("   - Local models available\n")
    }, error = function(e) {
      cat("   ⚠️  Could not list models\n")
    })
  } else {
    cat("   ❌ Ollama server not running\n")
    cat("   💡 Run: ollama serve\n")
  }
  
  # Check OpenAI API
  if (!is.null(config$backends$openai)) {
    api_key_var <- config$backends$openai$api_key_env %||% "OPENAI_API_KEY"
    if (Sys.getenv(api_key_var) != "") {
      cat("   ✅ OpenAI API key configured\n")
    } else {
      cat("   ❌ OpenAI API key not found\n")
      cat("   💡 Set:", api_key_var, "\n")
    }
  }
  
  cat("\n=== CONFIGURATION CHECK COMPLETE ===\n")
}

execute_test_privacy <- function(args, privacy_config) {
  if (!file.exists(args$input_file)) {
    stop("Input file not found: ", args$input_file)
  }
  
  input_text <- paste(readLines(args$input_file, warn = FALSE), collapse = "\n")
  cat("Testing privacy filter on file:", args$input_file, "\n\n")
  
  result <- test_privacy_filter(input_text, privacy_config)
  
  return(invisible(result))
}

if (!interactive()) {
  main()
}