# privacy_filter.R - Privacy filtering and data redaction

apply_privacy_filter <- function(text, rules) {
  if (is.null(rules) || is.null(text)) {
    return(list(
      filtered_text = text,
      restoration_map = list()
    ))
  }
  
  filtered_text <- text
  restoration_map <- list()
  
  # Apply sensitive pattern filters
  if (!is.null(rules$sensitive_patterns)) {
    for (pattern in rules$sensitive_patterns) {
      matches <- gregexpr(pattern, filtered_text, perl = TRUE)
      if (matches[[1]][1] != -1) {
        matched_text <- regmatches(filtered_text, matches)[[1]]
        
        for (i in seq_along(matched_text)) {
          placeholder <- generate_placeholder(pattern, i)
          restoration_map[[placeholder]] <- matched_text[i]
          filtered_text <- gsub(matched_text[i], placeholder, filtered_text, fixed = TRUE)
        }
      }
    }
  }
  
  # Apply specific redaction rules
  if (!is.null(rules$redaction_rules)) {
    if (!is.null(rules$redaction_rules$replace_names)) {
      name_patterns <- c("ชื่อ.*?:", "นาย.*?\\s", "นางสาว.*?\\s", "นาง.*?\\s")
      for (pattern in name_patterns) {
        filtered_text <- gsub(pattern, rules$redaction_rules$replace_names, filtered_text, perl = TRUE)
      }
    }
    
    if (!is.null(rules$redaction_rules$replace_ids)) {
      id_patterns <- c("รหัส.*?:", "เลขที่.*?:", "\\d{8,}")
      for (pattern in id_patterns) {
        filtered_text <- gsub(pattern, rules$redaction_rules$replace_ids, filtered_text, perl = TRUE)
      }
    }
  }
  
  return(list(
    filtered_text = filtered_text,
    restoration_map = restoration_map
  ))
}

generate_placeholder <- function(pattern, index) {
  base_name <- gsub("[^A-Za-z]", "", pattern)
  if (nchar(base_name) == 0) base_name <- "REDACTED"
  return(paste0("[", toupper(base_name), "_", index, "]"))
}

restore_privacy_context <- function(text, restoration_map) {
  if (length(restoration_map) == 0) {
    return(text)
  }
  
  restored_text <- text
  for (placeholder in names(restoration_map)) {
    restored_text <- gsub(placeholder, restoration_map[[placeholder]], restored_text, fixed = TRUE)
  }
  
  return(restored_text)
}

test_privacy_filter <- function(input_text, privacy_rules) {
  result <- apply_privacy_filter(input_text, privacy_rules)
  
  cat("Original text:\n")
  cat(input_text, "\n\n")
  
  cat("Filtered text:\n")
  cat(result$filtered_text, "\n\n")
  
  cat("Restoration map:\n")
  if (length(result$restoration_map) > 0) {
    for (placeholder in names(result$restoration_map)) {
      cat(placeholder, " -> ", result$restoration_map[[placeholder]], "\n")
    }
  } else {
    cat("No sensitive data detected\n")
  }
  
  return(result)
}