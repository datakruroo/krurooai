# config_manager.R - YAML configuration management

library(yaml)

load_config <- function(config_path) {
  if (!file.exists(config_path)) {
    warning("Config file not found: ", config_path)
    return(list())
  }
  
  tryCatch({
    config <- yaml.load_file(config_path)
    return(config)
  }, error = function(e) {
    stop("Error loading config file ", config_path, ": ", e$message)
  })
}

save_config <- function(config, config_path) {
  tryCatch({
    yaml.write(config, config_path)
    return(TRUE)
  }, error = function(e) {
    stop("Error saving config file ", config_path, ": ", e$message)
  })
}

validate_llm_config <- function(config) {
  required_sections <- c("backends")
  
  for (section in required_sections) {
    if (is.null(config[[section]])) {
      stop("Missing required section in LLM config: ", section)
    }
  }
  
  if (!is.null(config$backends$local)) {
    validate_local_backend(config$backends$local)
  }
  
  if (!is.null(config$backends$openai)) {
    validate_openai_backend(config$backends$openai)
  }
  
  return(TRUE)
}

validate_local_backend <- function(local_config) {
  required_fields <- c("model", "endpoint")
  
  for (field in required_fields) {
    if (is.null(local_config[[field]])) {
      stop("Missing required field in local backend config: ", field)
    }
  }
  
  return(TRUE)
}

validate_openai_backend <- function(openai_config) {
  required_fields <- c("model", "api_key_env")
  
  for (field in required_fields) {
    if (is.null(openai_config[[field]])) {
      stop("Missing required field in OpenAI backend config: ", field)
    }
  }
  
  # Check if API key environment variable exists
  api_key <- Sys.getenv(openai_config$api_key_env)
  if (api_key == "") {
    warning("API key environment variable not set: ", openai_config$api_key_env)
  }
  
  return(TRUE)
}

validate_privacy_config <- function(config) {
  if (is.null(config$sensitive_patterns) && is.null(config$redaction_rules)) {
    warning("Privacy config has no sensitive patterns or redaction rules")
  }
  
  return(TRUE)
}

get_active_backend <- function(config, mode = "local") {
  if (!mode %in% names(config$backends)) {
    stop("Backend mode not configured: ", mode)
  }
  
  return(config$backends[[mode]])
}

merge_configs <- function(default_config, user_config) {
  if (is.null(user_config)) return(default_config)
  if (is.null(default_config)) return(user_config)
  
  merged <- default_config
  
  for (key in names(user_config)) {
    if (is.list(user_config[[key]]) && is.list(default_config[[key]])) {
      merged[[key]] <- merge_configs(default_config[[key]], user_config[[key]])
    } else {
      merged[[key]] <- user_config[[key]]
    }
  }
  
  return(merged)
}