USE talentfit_db;

-- Truy vấn 1. Tìm các tin đang nhận đơn tại Hà Nội, toàn thời gian, yêu cầu tối đa 2 năm kinh nghiệm
SELECT j.job_id, j.title, c.company_name, j.salary, j.deadline
FROM JobPosting j
JOIN Company c ON c.company_id = j.company_id
WHERE j.status = 'open'
  AND CURDATE() BETWEEN j.open_date AND j.deadline
  AND j.location = 'Hà Nội' AND j.job_type = 'Full-time'
  AND j.min_experience_years <= 2
ORDER BY j.open_date DESC;

-- Truy vấn 2. Tìm ứng viên chờ duyệt của tin số 1 có tổng kinh nghiệm từ 12 tháng trở lên
SELECT c.full_name, a.submitted_at, SUM(e.months) AS total_months
FROM Application a
JOIN Candidate c  ON c.candidate_id = a.candidate_id
JOIN Experience e ON e.resume_id = a.resume_id
WHERE a.job_id = 1 AND a.status = 'pending'
GROUP BY c.candidate_id, c.full_name, a.submitted_at
HAVING SUM(e.months) >= 12
ORDER BY total_months DESC;

-- Truy vấn 3. Thống kê số tin và số đơn của từng công ty, chỉ giữ công ty có từ 5 đơn trở lên
SELECT c.company_name, COUNT(DISTINCT j.job_id) AS job_count,
       COUNT(a.job_id) AS application_count
FROM Company c
JOIN JobPosting j ON j.company_id = c.company_id
LEFT JOIN Application a ON a.job_id = j.job_id
GROUP BY c.company_id, c.company_name
HAVING application_count >= 5
ORDER BY application_count DESC;

-- Truy vấn 4. Liệt kê ứng viên chưa nộp đơn nào
SELECT c.candidate_id, c.full_name
FROM Candidate c
WHERE NOT EXISTS (SELECT 1 FROM Application a
                  WHERE a.candidate_id = c.candidate_id);

-- Truy vấn 5. Liệt kê các tin có số đơn nhiều hơn mức trung bình
SELECT j.title, COUNT(a.candidate_id) AS total
FROM JobPosting j
LEFT JOIN Application a ON a.job_id = j.job_id
GROUP BY j.job_id, j.title
HAVING COUNT(a.candidate_id) > (
  SELECT AVG(sub.cnt)
  FROM (
    SELECT COUNT(a2.candidate_id) AS cnt
    FROM JobPosting j2
    LEFT JOIN Application a2 ON a2.job_id = j2.job_id
    GROUP BY j2.job_id
  ) AS sub
)
ORDER BY total DESC, j.title;

-- Truy vấn 6. Tìm CV gốc (chưa khóa) có kỹ năng Python hoặc FastAPI
SELECT r.resume_id, c.full_name, r.skills
FROM Resume r
JOIN Candidate c ON c.candidate_id = r.candidate_id
WHERE r.is_locked = 0
  AND (r.skills LIKE '%Python%' OR r.skills LIKE '%FastAPI%')
ORDER BY r.resume_id;

-- Truy vấn 7. Xem các thông báo chưa đọc của tài khoản số 5
SELECT title, content, created_at
FROM Notification
WHERE account_id = 5 AND is_read = 0
ORDER BY created_at DESC;

-- Truy vấn 8. Xếp hạng các ứng viên đã chấm của tin số 1 theo điểm trung bình
SELECT c.full_name, a.education_score, a.skills_score,
       a.experience_score,
       ROUND((a.education_score + a.skills_score + a.experience_score) / 3, 2)
         AS avg_score
FROM Application a
JOIN Candidate c ON c.candidate_id = a.candidate_id
WHERE a.job_id = 1 AND a.is_scored = 1
ORDER BY avg_score DESC;

-- Truy vấn 9. Tìm các đơn của tin số 1 còn chờ chấm điểm
SELECT candidate_id, resume_id
FROM Application
WHERE job_id = 1 AND is_scored = 0;

-- Truy vấn 10. Đọc điểm và nhận xét đã lưu của đơn (ứng viên 1, tin 1)
SELECT education_score, education_comment,
       skills_score, skills_comment,
       experience_score, experience_comment
FROM Application
WHERE candidate_id = 1 AND job_id = 1 AND is_scored = 1;

-- Truy vấn 11. Tìm ứng viên có điểm trung bình cao nhất của mỗi tin
WITH s AS (
  SELECT job_id, candidate_id,
         ROUND((education_score + skills_score + experience_score) / 3, 2)
           AS avg_score
  FROM Application
  WHERE is_scored = 1
),
m AS (
  SELECT job_id, MAX(avg_score) AS max_score
  FROM s
  GROUP BY job_id
)
SELECT j.title, c.full_name, s.avg_score
FROM s
JOIN m ON m.job_id = s.job_id AND m.max_score = s.avg_score
JOIN JobPosting j ON j.job_id = s.job_id
JOIN Candidate c  ON c.candidate_id = s.candidate_id
ORDER BY s.avg_score DESC;

-- Truy vấn 12. Tìm ứng viên đã nộp đơn vào từ hai công ty khác nhau trở lên
SELECT c.candidate_id, c.full_name,
       COUNT(DISTINCT j.company_id) AS company_count
FROM Application a
JOIN Candidate c  ON c.candidate_id = a.candidate_id
JOIN JobPosting j ON j.job_id = a.job_id
GROUP BY c.candidate_id, c.full_name
HAVING COUNT(DISTINCT j.company_id) >= 2
ORDER BY company_count DESC, c.candidate_id;

-- Truy vấn 13. Tính tỷ lệ duyệt của các tin đã chốt kết quả
SELECT j.title, COUNT(a.candidate_id) AS total,
       COUNT(ap.candidate_id) AS approved,
       ROUND(100 * COUNT(ap.candidate_id) / COUNT(a.candidate_id), 2)
         AS approval_rate
FROM JobPosting j
JOIN Application a ON a.job_id = j.job_id
LEFT JOIN Application ap ON ap.job_id = a.job_id
  AND ap.candidate_id = a.candidate_id AND ap.status = 'approved'
WHERE j.is_finalized = 1
GROUP BY j.job_id, j.title;

-- Truy vấn 14. Tìm ứng viên đã nộp đơn vào mọi tin của Công ty DataViet
SELECT c.full_name, COUNT(a.job_id) AS applied_jobs
FROM Candidate c
JOIN Application a ON a.candidate_id = c.candidate_id
JOIN JobPosting j  ON j.job_id = a.job_id
JOIN Company co    ON co.company_id = j.company_id
WHERE co.company_name = 'Công ty DataViet'
GROUP BY c.candidate_id, c.full_name
HAVING COUNT(a.job_id) = (
  SELECT COUNT(*)
  FROM JobPosting j2
  JOIN Company co2 ON co2.company_id = j2.company_id
  WHERE co2.company_name = 'Công ty DataViet'
);

-- Truy vấn 15. Tìm tin đang nhận đơn nhưng chưa có ứng viên nào nộp
SELECT j.job_id, j.title, c.company_name, j.deadline
FROM JobPosting j
JOIN Company c ON c.company_id = j.company_id
WHERE j.status = 'open'
  AND CURDATE() BETWEEN j.open_date AND j.deadline
  AND NOT EXISTS (SELECT 1 FROM Application a
                  WHERE a.job_id = j.job_id);

-- Truy vấn 16. Lập danh bạ chung của ứng viên và công ty kèm vai trò, email
SELECT 'Ứng viên' AS user_type, c.full_name AS name, a.email, c.phone
FROM Candidate c JOIN Account a ON a.account_id = c.account_id
UNION ALL
SELECT 'Công ty', co.company_name, a.email, co.phone
FROM Company co JOIN Account a ON a.account_id = co.account_id
ORDER BY user_type, name;

-- Truy vấn 17. Tìm các đơn có điểm trung bình cao hơn mức trung bình của chính tin đó
WITH s AS (
  SELECT job_id, candidate_id,
         ROUND((education_score + skills_score + experience_score) / 3, 2)
           AS avg_score
  FROM Application
  WHERE is_scored = 1
)
SELECT j.title, c.full_name, s.avg_score
FROM s
JOIN JobPosting j ON j.job_id = s.job_id
JOIN Candidate c  ON c.candidate_id = s.candidate_id
WHERE s.avg_score > (SELECT AVG(s2.avg_score) FROM s AS s2
                     WHERE s2.job_id = s.job_id)
ORDER BY j.title, s.avg_score DESC;

-- Truy vấn 18. Tìm ứng viên có điểm kỹ năng cao nhất trong từng tin
SELECT j.title, c.full_name, a.skills_score
FROM Application a
JOIN JobPosting j ON j.job_id = a.job_id
JOIN Candidate c  ON c.candidate_id = a.candidate_id
WHERE a.is_scored = 1
  AND a.skills_score >= ALL (
    SELECT a2.skills_score
    FROM Application a2
    WHERE a2.job_id = a.job_id AND a2.is_scored = 1
  )
ORDER BY j.job_id;

-- Truy vấn 19. Thống kê kết quả chấm điểm theo từng công ty, kể cả công ty chưa có đơn
WITH s AS (
  SELECT job_id, candidate_id,
         ROUND((education_score + skills_score + experience_score) / 3, 2)
           AS avg_score
  FROM Application
  WHERE is_scored = 1
)
SELECT co.company_name, COUNT(s.candidate_id) AS scored_count,
       ROUND(AVG(s.avg_score), 2) AS average_score,
       MAX(s.avg_score) AS highest_score
FROM Company co
LEFT JOIN JobPosting j ON j.company_id = co.company_id
LEFT JOIN s ON s.job_id = j.job_id
GROUP BY co.company_id, co.company_name
ORDER BY average_score DESC;

-- Truy vấn 20. Thống kê số đơn và số tin được nộp theo ngày
SELECT DATE(submitted_at) AS submit_date,
       COUNT(*) AS application_count,
       COUNT(DISTINCT job_id) AS job_count
FROM Application
GROUP BY DATE(submitted_at)
ORDER BY submit_date;
