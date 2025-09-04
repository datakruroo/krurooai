# report_generator.R - Report generation and formatting

generate_report <- function(results, template = "default", output_file = NULL) {
  if (is.null(results)) {
    stop("Results required for report generation")
  }
  
  switch(template,
    "default" = generate_default_report(results, output_file),
    "detailed" = generate_detailed_report(results, output_file),
    "summary" = generate_summary_report(results, output_file),
    stop("Unknown template: ", template)
  )
}

generate_default_report <- function(results, output_file) {
  report <- paste0(
    "# รายงานการตรวจงาน: ", results$student_id %||% "[STUDENT]", "\n\n",
    "## คะแนนรวม: ", results$total_score %||% "0", "/100\n\n",
    "## รายละเอียด\n"
  )
  
  if (!is.null(results$breakdown)) {
    for (item in names(results$breakdown)) {
      report <- paste0(report, "- ", item, ": ", results$breakdown[[item]], "\n")
    }
  }
  
  report <- paste0(report, "\n## ข้อเสนอแนะ\n")
  if (!is.null(results$feedback)) {
    report <- paste0(report, results$feedback)
  } else {
    report <- paste0(report, "ไม่มีข้อเสนอแนะเพิ่มเติม")
  }
  
  report <- paste0(report, "\n\n## ข้อมูลการประมวลผล\n")
  report <- paste0(report, "- วันที่ประมวลผล: ", Sys.Date(), "\n")
  report <- paste0(report, "- โมเดล LLM: ", results$model_used %||% "ไม่ระบุ", "\n")
  report <- paste0(report, "- ความมั่นใจ: ", results$confidence %||% "ไม่ระบุ", "\n")
  
  if (!is.null(output_file)) {
    writeLines(report, output_file)
    cat("Report saved to:", output_file, "\n")
  } else {
    cat(report)
  }
  
  return(report)
}

generate_detailed_report <- function(results, output_file) {
  report <- generate_default_report(results, NULL)
  
  if (!is.null(results$detailed_analysis)) {
    report <- paste0(report, "\n## การวิเคราะห์รายละเอียด\n")
    report <- paste0(report, results$detailed_analysis)
  }
  
  if (!is.null(results$rubric_scores)) {
    report <- paste0(report, "\n## คะแนนตามรูบริค\n")
    for (criteria in names(results$rubric_scores)) {
      report <- paste0(report, "- ", criteria, ": ", results$rubric_scores[[criteria]], "\n")
    }
  }
  
  if (!is.null(output_file)) {
    writeLines(report, output_file)
    cat("Detailed report saved to:", output_file, "\n")
  } else {
    cat(report)
  }
  
  return(report)
}

generate_summary_report <- function(results, output_file) {
  report <- paste0(
    "# สรุปผลการตรวจงาน\n\n",
    "คะแนน: ", results$total_score %||% "0", "/100\n",
    "ระดับ: ", get_grade_level(results$total_score), "\n",
    "สถานะ: ", if ((results$total_score %||% 0) >= 50) "ผ่าน" else "ไม่ผ่าน", "\n"
  )
  
  if (!is.null(output_file)) {
    writeLines(report, output_file)
    cat("Summary report saved to:", output_file, "\n")
  } else {
    cat(report)
  }
  
  return(report)
}

get_grade_level <- function(score) {
  if (is.null(score)) return("ไม่ระบุ")
  
  if (score >= 80) return("ดีเยี่ยม")
  if (score >= 70) return("ดี")
  if (score >= 60) return("พอใช้")
  if (score >= 50) return("ผ่าน")
  return("ไม่ผ่าน")
}

# Helper function for null coalescing
`%||%` <- function(x, y) {
  if (is.null(x) || length(x) == 0) y else x
}