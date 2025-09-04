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
    "## คะแนนรวม: ", results$total_score %||% "0", "/100\n\n"
  )
  
  # คะแนนรายละเอียด
  if (!is.null(results$breakdown)) {
    report <- paste0(report, "## คะแนนรายละเอียด\n")
    for (item in names(results$breakdown)) {
      report <- paste0(report, "- ", item, ": ", results$breakdown[[item]], "\n")
    }
    report <- paste0(report, "\n")
  }
  
  # Feedback รายข้อ - แยกตามประเภทคำถาม
  if (!is.null(results$question_feedback)) {
    # ตรวจสอบว่าเป็น data.frame หรือ list
    if (is.data.frame(results$question_feedback)) {
      cat("Processing question_feedback as data.frame with", nrow(results$question_feedback), "rows\n")
      
      # แยกข้อปรนัยและข้ออัตนัย
      objective_questions <- list()
      subjective_questions <- list()
      
      for (i in 1:nrow(results$question_feedback)) {
        q <- results$question_feedback[i, ]
        question_type <- q$question_type %||% "objective"
        
        if (question_type == "objective") {
          objective_questions <- append(objective_questions, list(q))
        } else {
          subjective_questions <- append(subjective_questions, list(q))
        }
      }
    } else if (is.list(results$question_feedback) && length(results$question_feedback) > 0) {
      cat("Processing question_feedback as list with", length(results$question_feedback), "items\n")
      
      # แยกข้อปรนัยและข้ออัตนัย
      objective_questions <- list()
      subjective_questions <- list()
      
      for (i in seq_along(results$question_feedback)) {
        q <- results$question_feedback[[i]]
        if (!is.list(q)) next
        
        question_type <- q$question_type %||% "objective"
        
        if (question_type == "objective") {
          objective_questions <- append(objective_questions, list(q))
        } else {
          subjective_questions <- append(subjective_questions, list(q))
        }
      }
    } else {
      cat("No valid question_feedback found\n")
      objective_questions <- list()
      subjective_questions <- list()
    }
    
    # ส่วนข้อปรนัย (Objective Questions)
    if (length(objective_questions) > 0) {
      report <- paste0(report, "## ผลการประเมิน: ข้อปรนัย\n\n")
      
      for (i in seq_along(objective_questions)) {
        q <- objective_questions[[i]]
        
        # Handle data.frame row
        question_num <- as.character(q$question_number[1] %||% i)
        student_answer <- as.character(q$student_answer[1] %||% "")
        correct_answer <- as.character(q$correct_answer[1] %||% "")
        score <- as.character(q$score[1] %||% "0")
        max_score <- as.character(q$max_score[1] %||% "10")
        is_correct <- as.logical(q$is_correct[1] %||% FALSE)
        feedback <- as.character(q$feedback[1] %||% "")
        
        report <- paste0(report, "### ข้อที่ ", question_num, "\n")
        
        if (student_answer != "") {
          report <- paste0(report, "**คำตอบของนักเรียน:** ", student_answer, "\n")
        }
        
        if (correct_answer != "") {
          report <- paste0(report, "**คำตอบที่ถูกต้อง:** ", correct_answer, "\n")
        }
        
        status <- if (is_correct) "✅ ถูกต้อง" else "❌ ไม่ถูกต้อง"
        report <- paste0(report, "**ผลลัพธ์:** ", score, "/", max_score, " (", status, ")\n")
        
        if (feedback != "") {
          report <- paste0(report, "**คำอธิบาย:** ", feedback, "\n")
        }
        
        report <- paste0(report, "\n---\n\n")
      }
    }
    
    # ส่วนข้ออัตนัย (Subjective Questions)  
    if (length(subjective_questions) > 0) {
      report <- paste0(report, "## ผลการประเมิน: ข้ออัตนัย\n\n")
      
      for (i in seq_along(subjective_questions)) {
        q <- subjective_questions[[i]]
        
        # Handle data.frame row
        question_num <- as.character(q$question_number[1] %||% i)
        student_answer <- as.character(q$student_answer[1] %||% "")
        score <- as.character(q$score[1] %||% "0")
        max_score <- as.character(q$max_score[1] %||% "10")
        key_points <- as.character(q$key_points[1] %||% "")
        feedback <- as.character(q$feedback[1] %||% "")
        improvement_suggestions <- as.character(q$improvement_suggestions[1] %||% "")
        
        report <- paste0(report, "### ข้อที่ ", question_num, "\n")
        
        if (student_answer != "") {
          report <- paste0(report, "**คำตอบของนักเรียน:**\n", student_answer, "\n\n")
        }
        
        report <- paste0(report, "**คะแนนที่ได้:** ", score, "/", max_score, "\n\n")
        
        if (key_points != "") {
          report <- paste0(report, "**จุดสำคัญที่ควรมี:**\n", key_points, "\n\n")
        }
        
        if (feedback != "") {
          report <- paste0(report, "**การประเมิน:**\n", feedback, "\n\n")
        }
        
        if (improvement_suggestions != "") {
          report <- paste0(report, "**ข้อเสนอแนะเพื่อพัฒนา:**\n", improvement_suggestions, "\n\n")
        }
        
        report <- paste0(report, "---\n\n")
      }
    }
  }
  
  # ข้อเสนอแนะภาพรวม
  report <- paste0(report, "## ข้อเสนอแนะภาพรวม\n")
  if (!is.null(results$overall_feedback)) {
    report <- paste0(report, results$overall_feedback, "\n\n")
  } else if (!is.null(results$feedback)) {
    report <- paste0(report, results$feedback, "\n\n")
  } else {
    report <- paste0(report, "ไม่มีข้อเสนอแนะเพิ่มเติม\n\n")
  }
  
  # จุดเด่น
  if (!is.null(results$strengths)) {
    report <- paste0(report, "## จุดเด่น\n")
    report <- paste0(report, results$strengths, "\n\n")
  }
  
  # ข้อเสนอแนะเพื่อพัฒนา
  if (!is.null(results$improvements)) {
    report <- paste0(report, "## ข้อเสนอแนะเพื่อพัฒนา\n")
    report <- paste0(report, results$improvements, "\n\n")
  }
  
  # การวิเคราะห์เชิงลึก
  if (!is.null(results$detailed_analysis)) {
    report <- paste0(report, "## การวิเคราะห์เชิงลึก\n")
    report <- paste0(report, results$detailed_analysis, "\n\n")
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