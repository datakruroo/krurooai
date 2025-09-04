# context_processor.R - Markdown context processing

process_context_md <- function(md_file) {
  if (is.null(md_file) || !file.exists(md_file)) {
    stop("Context file not found: ", md_file)
  }
  
  content <- readLines(md_file, warn = FALSE)
  
  context <- list(
    title = extract_title(content),
    question = extract_section(content, "คำถาม"),
    standard_answer = extract_section(content, "คำตอบมาตรฐาน"),
    grading_criteria = extract_section(content, "เกณฑ์การประเมิน"),
    notes = extract_section(content, "หมายเหตุ")
  )
  
  return(context)
}

extract_title <- function(content) {
  title_line <- grep("^# ", content, value = TRUE)[1]
  if (is.na(title_line)) {
    return("Untitled Assignment")
  }
  return(gsub("^# ", "", title_line))
}

extract_section <- function(content, section_name) {
  start_pattern <- paste0("^## ", section_name)
  start_idx <- grep(start_pattern, content)
  
  if (length(start_idx) == 0) {
    return(NULL)
  }
  
  start_idx <- start_idx[1]
  
  next_section_idx <- grep("^## ", content[(start_idx + 1):length(content)])
  if (length(next_section_idx) > 0) {
    end_idx <- start_idx + next_section_idx[1] - 1
  } else {
    end_idx <- length(content)
  }
  
  section_content <- content[(start_idx + 1):end_idx]
  section_content <- section_content[section_content != ""]
  
  return(paste(section_content, collapse = "\n"))
}

validate_context <- function(context) {
  required_fields <- c("question", "grading_criteria")
  missing_fields <- required_fields[!sapply(context[required_fields], function(x) !is.null(x) && nchar(x) > 0)]
  
  if (length(missing_fields) > 0) {
    stop("Missing required context fields: ", paste(missing_fields, collapse = ", "))
  }
  
  return(TRUE)
}