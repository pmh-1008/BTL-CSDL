-- ===== 1. TẠO CSDL VÀ BẢNG =====
CREATE DATABASE IF NOT EXISTS talentfit_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE talentfit_db;

CREATE TABLE Account (
  account_id    INT AUTO_INCREMENT PRIMARY KEY,
  email         VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role          VARCHAR(10)  NOT NULL,
  created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_account_role CHECK (role IN ('candidate', 'recruiter'))
) ENGINE=InnoDB;

CREATE TABLE Candidate (
  candidate_id INT AUTO_INCREMENT PRIMARY KEY,
  account_id   INT NOT NULL UNIQUE,
  full_name    VARCHAR(150) NOT NULL,
  phone        VARCHAR(30),
  CONSTRAINT fk_candidate_account FOREIGN KEY (account_id)
    REFERENCES Account(account_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Company (
  company_id     INT AUTO_INCREMENT PRIMARY KEY,
  account_id     INT NOT NULL UNIQUE,
  company_name   VARCHAR(200) NOT NULL UNIQUE,
  description    TEXT,
  contact_person VARCHAR(150),
  phone          VARCHAR(30),
  CONSTRAINT fk_company_account FOREIGN KEY (account_id)
    REFERENCES Account(account_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Resume (
  resume_id    INT AUTO_INCREMENT PRIMARY KEY,
  candidate_id INT NOT NULL,
  resume_name  VARCHAR(100) NOT NULL,
  summary      TEXT,
  skills       TEXT NOT NULL,
  github       VARCHAR(255),
  linkedin     VARCHAR(255),
  is_locked    BOOL NOT NULL DEFAULT 0,
  updated_at   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
               ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT uq_resume_owner UNIQUE (resume_id, candidate_id),
  CONSTRAINT fk_resume_candidate FOREIGN KEY (candidate_id)
    REFERENCES Candidate(candidate_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Education (
  education_id    INT AUTO_INCREMENT PRIMARY KEY,
  resume_id       INT NOT NULL,
  degree          VARCHAR(120) NOT NULL,
  school          VARCHAR(200) NOT NULL,
  graduation_year SMALLINT NOT NULL,
  gpa             DECIMAL(4,2) NULL,
  CONSTRAINT ck_education_year CHECK (graduation_year BETWEEN 1950 AND 2100),
  CONSTRAINT ck_education_gpa CHECK (gpa IS NULL OR gpa BETWEEN 0 AND 10),
  CONSTRAINT fk_education_resume FOREIGN KEY (resume_id)
    REFERENCES Resume(resume_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Experience (
  experience_id INT AUTO_INCREMENT PRIMARY KEY,
  resume_id     INT NOT NULL,
  position      VARCHAR(120) NOT NULL,
  company_name  VARCHAR(200) NOT NULL,
  months        SMALLINT NOT NULL,
  description   TEXT,
  CONSTRAINT ck_experience_months CHECK (months >= 0),
  CONSTRAINT fk_experience_resume FOREIGN KEY (resume_id)
    REFERENCES Resume(resume_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Certificate (
  certificate_id   INT AUTO_INCREMENT PRIMARY KEY,
  resume_id        INT NOT NULL,
  certificate_name VARCHAR(200) NOT NULL,
  year             SMALLINT NOT NULL,
  CONSTRAINT ck_certificate_year CHECK (year BETWEEN 1950 AND 2100),
  CONSTRAINT fk_certificate_resume FOREIGN KEY (resume_id)
    REFERENCES Resume(resume_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE JobPosting (
  job_id               INT AUTO_INCREMENT PRIMARY KEY,
  company_id           INT NOT NULL,
  title                VARCHAR(200) NOT NULL,
  description          TEXT NOT NULL,
  requirements         TEXT NOT NULL,
  benefits             TEXT,
  location             VARCHAR(120),
  job_type             VARCHAR(40) NOT NULL DEFAULT 'Full-time',
  salary               VARCHAR(80),
  min_experience_years TINYINT NOT NULL DEFAULT 0,
  contact_email        VARCHAR(255),
  open_date            DATE NOT NULL,
  deadline             DATE NOT NULL,
  status               VARCHAR(10) NOT NULL DEFAULT 'open',
  is_finalized         BOOL NOT NULL DEFAULT 0,
  created_at           DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT ck_job_deadline CHECK (deadline >= open_date),
  CONSTRAINT ck_job_status CHECK (status IN ('open', 'closed')),
  CONSTRAINT ck_job_type CHECK (job_type IN ('Full-time', 'Part-time',
    'Internship', 'Contract', 'Remote')),
  CONSTRAINT ck_job_experience CHECK (min_experience_years BETWEEN 0 AND 40),
  CONSTRAINT fk_job_company FOREIGN KEY (company_id)
    REFERENCES Company(company_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Application (
  candidate_id       INT NOT NULL,
  job_id             INT NOT NULL,
  resume_id          INT NOT NULL UNIQUE,
  submitted_at       DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status             VARCHAR(10) NOT NULL DEFAULT 'pending',
  draft_decision     VARCHAR(10) NULL,
  decided_at         DATETIME NULL,
  education_score    DECIMAL(5,2) NULL,
  skills_score       DECIMAL(5,2) NULL,
  experience_score   DECIMAL(5,2) NULL,
  education_comment  TEXT NULL,
  skills_comment     TEXT NULL,
  experience_comment TEXT NULL,
  is_scored          BOOL NOT NULL DEFAULT 0,
  PRIMARY KEY (candidate_id, job_id),
  CONSTRAINT ck_app_status CHECK (status IN ('pending', 'approved', 'rejected')),
  CONSTRAINT ck_app_draft CHECK (draft_decision IS NULL
    OR draft_decision IN ('approved', 'rejected')),
  CONSTRAINT ck_app_edu_score CHECK (education_score IS NULL
    OR education_score BETWEEN 0 AND 100),
  CONSTRAINT ck_app_ski_score CHECK (skills_score IS NULL
    OR skills_score BETWEEN 0 AND 100),
  CONSTRAINT ck_app_exp_score CHECK (experience_score IS NULL
    OR experience_score BETWEEN 0 AND 100),
  CONSTRAINT ck_app_scored CHECK (is_scored = 0 OR (
    education_score IS NOT NULL AND skills_score IS NOT NULL
    AND experience_score IS NOT NULL AND education_comment IS NOT NULL
    AND skills_comment IS NOT NULL AND experience_comment IS NOT NULL)),
  CONSTRAINT fk_app_candidate FOREIGN KEY (candidate_id)
    REFERENCES Candidate(candidate_id) ON DELETE CASCADE,
  CONSTRAINT fk_app_job FOREIGN KEY (job_id)
    REFERENCES JobPosting(job_id) ON DELETE CASCADE,
  CONSTRAINT fk_app_resume FOREIGN KEY (resume_id, candidate_id)
    REFERENCES Resume(resume_id, candidate_id) ON DELETE CASCADE
) ENGINE=InnoDB;

CREATE TABLE Notification (
  notification_id INT AUTO_INCREMENT PRIMARY KEY,
  account_id      INT NOT NULL,
  title           VARCHAR(200) NOT NULL,
  content         TEXT NOT NULL,
  is_read         BOOL NOT NULL DEFAULT 0,
  created_at      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notification_account FOREIGN KEY (account_id)
    REFERENCES Account(account_id) ON DELETE CASCADE
) ENGINE=InnoDB;

-- ===== 2. DỮ LIỆU MẪU =====
USE talentfit_db;
-- Dữ liệu minh họa; ngày tháng tính theo CURDATE()

INSERT INTO Account (account_id, email, password_hash, role, created_at) VALUES
  (1, 'hr01@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'recruiter', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (2, 'hr02@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'recruiter', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (3, 'hr03@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'recruiter', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (4, 'hr04@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'recruiter', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (5, 'cand001@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (6, 'cand002@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (7, 'cand003@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (8, 'cand004@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (9, 'cand005@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (10, 'cand006@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (11, 'cand007@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (12, 'cand008@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (13, 'cand009@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (14, 'cand010@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (15, 'cand011@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY)),
  (16, 'cand012@example.test', '$2b$12$EXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLEEXAMPLE0000', 'candidate', DATE_SUB(CURDATE(), INTERVAL 90 DAY));

INSERT INTO Candidate (candidate_id, account_id, full_name, phone) VALUES
  (1, 5, 'Trần Thị Bảo', '0900000001'),
  (2, 6, 'Lê Văn Cường', '0900000002'),
  (3, 7, 'Nguyễn Minh Đức', '0900000003'),
  (4, 8, 'Phạm Thị Giang', '0900000004'),
  (5, 9, 'Hoàng Văn Hải', '0900000005'),
  (6, 10, 'Vũ Thị Hương', '0900000006'),
  (7, 11, 'Đỗ Quang Huy', '0900000007'),
  (8, 12, 'Bùi Thị Lan', '0900000008'),
  (9, 13, 'Ngô Văn Nam', '0900000009'),
  (10, 14, 'Đặng Thị Oanh', '0900000010'),
  (11, 15, 'Phan Văn Phúc', '0900000011'),
  (12, 16, 'Lý Thị Quỳnh', '0900000012');

INSERT INTO Company (company_id, account_id, company_name, description, contact_person, phone) VALUES
  (1, 1, 'Công ty ABC Software', 'Phát triển phần mềm doanh nghiệp', 'Nguyễn Văn An', '0241000001'),
  (2, 2, 'Công ty DataViet', 'Giải pháp dữ liệu và phân tích', 'Trần Thị Bình', '0241000002'),
  (3, 3, 'Công ty FinNext', 'Công nghệ tài chính', 'Lê Minh Châu', '0281000003'),
  (4, 4, 'Công ty EduCloud', 'Nền tảng giáo dục trực tuyến', 'Phạm Thu Dung', '0236100004');

INSERT INTO Resume (resume_id, candidate_id, resume_name, summary, skills, github, linkedin, is_locked) VALUES
  (1, 1, 'CV Backend', 'Hồ sơ Backend của Trần Thị Bảo', 'Python, FastAPI, MySQL, Docker', 'github.com/cand001', 'linkedin.com/in/cand001', 0),
  (2, 2, 'CV Java', 'Hồ sơ Java của Lê Văn Cường', 'Java, Spring Boot, SQL', 'github.com/cand002', 'linkedin.com/in/cand002', 0),
  (3, 3, 'CV Frontend', 'Hồ sơ Frontend của Nguyễn Minh Đức', 'JavaScript, React, CSS, HTML', 'github.com/cand003', 'linkedin.com/in/cand003', 0),
  (4, 4, 'CV Data', 'Hồ sơ Data của Phạm Thị Giang', 'SQL, Python, Power BI, Excel', 'github.com/cand004', 'linkedin.com/in/cand004', 0),
  (5, 5, 'CV Data Engineer', 'Hồ sơ Data Engineer của Hoàng Văn Hải', 'Python, Spark, Airflow, SQL', 'github.com/cand005', 'linkedin.com/in/cand005', 0),
  (6, 6, 'CV Tester', 'Hồ sơ Tester của Vũ Thị Hương', 'Manual testing, SQL, Postman', NULL, 'linkedin.com/in/cand006', 0),
  (7, 7, 'CV Python', 'Hồ sơ Python của Đỗ Quang Huy', 'Python, Django, Docker, MySQL', 'github.com/cand007', 'linkedin.com/in/cand007', 0),
  (8, 8, 'CV BA', 'Hồ sơ BA của Bùi Thị Lan', 'UML, SQL, Jira, giao tiếp', NULL, 'linkedin.com/in/cand008', 0),
  (9, 9, 'CV Fullstack', 'Hồ sơ Fullstack của Ngô Văn Nam', 'JavaScript, React, NodeJS, MySQL', 'github.com/cand009', 'linkedin.com/in/cand009', 0),
  (10, 10, 'CV Fresher', 'Hồ sơ Fresher của Đặng Thị Oanh', 'Java, SQL cơ bản', 'github.com/cand010', 'linkedin.com/in/cand010', 0),
  (11, 11, 'CV Mobile', 'Hồ sơ Mobile của Phan Văn Phúc', 'Kotlin, Flutter', 'github.com/cand011', 'linkedin.com/in/cand011', 0),
  (12, 12, 'CV Marketing', 'Hồ sơ Marketing của Lý Thị Quỳnh', 'SEO, Canva, viết nội dung', NULL, 'linkedin.com/in/cand012', 0),
  (13, 1, 'CV Data', 'Hồ sơ Data của Trần Thị Bảo', 'Python, SQL, Pandas', 'github.com/cand001', 'linkedin.com/in/cand001', 0),
  (14, 1, 'CV Backend', 'Hồ sơ Backend của Trần Thị Bảo', 'Python, FastAPI, MySQL, Docker', 'github.com/cand001', 'linkedin.com/in/cand001', 1),
  (15, 7, 'CV Python', 'Hồ sơ Python của Đỗ Quang Huy', 'Python, Django, Docker, MySQL', 'github.com/cand007', 'linkedin.com/in/cand007', 1),
  (16, 9, 'CV Fullstack', 'Hồ sơ Fullstack của Ngô Văn Nam', 'JavaScript, React, NodeJS, MySQL', 'github.com/cand009', 'linkedin.com/in/cand009', 1),
  (17, 2, 'CV Java', 'Hồ sơ Java của Lê Văn Cường', 'Java, Spring Boot, SQL', 'github.com/cand002', 'linkedin.com/in/cand002', 1),
  (18, 10, 'CV Fresher', 'Hồ sơ Fresher của Đặng Thị Oanh', 'Java, SQL cơ bản', 'github.com/cand010', 'linkedin.com/in/cand010', 1),
  (19, 3, 'CV Frontend', 'Hồ sơ Frontend của Nguyễn Minh Đức', 'JavaScript, React, CSS, HTML', 'github.com/cand003', 'linkedin.com/in/cand003', 1),
  (20, 9, 'CV Fullstack', 'Hồ sơ Fullstack của Ngô Văn Nam', 'JavaScript, React, NodeJS, MySQL', 'github.com/cand009', 'linkedin.com/in/cand009', 1),
  (21, 6, 'CV Tester', 'Hồ sơ Tester của Vũ Thị Hương', 'Manual testing, SQL, Postman', NULL, 'linkedin.com/in/cand006', 1),
  (22, 6, 'CV Tester', 'Hồ sơ Tester của Vũ Thị Hương', 'Manual testing, SQL, Postman', NULL, 'linkedin.com/in/cand006', 1),
  (23, 10, 'CV Fresher', 'Hồ sơ Fresher của Đặng Thị Oanh', 'Java, SQL cơ bản', 'github.com/cand010', 'linkedin.com/in/cand010', 1),
  (24, 4, 'CV Data', 'Hồ sơ Data của Phạm Thị Giang', 'SQL, Python, Power BI, Excel', 'github.com/cand004', 'linkedin.com/in/cand004', 1),
  (25, 1, 'CV Data', 'Hồ sơ Data của Trần Thị Bảo', 'Python, SQL, Pandas', 'github.com/cand001', 'linkedin.com/in/cand001', 1),
  (26, 8, 'CV BA', 'Hồ sơ BA của Bùi Thị Lan', 'UML, SQL, Jira, giao tiếp', NULL, 'linkedin.com/in/cand008', 1),
  (27, 5, 'CV Data Engineer', 'Hồ sơ Data Engineer của Hoàng Văn Hải', 'Python, Spark, Airflow, SQL', 'github.com/cand005', 'linkedin.com/in/cand005', 1),
  (28, 5, 'CV Data Engineer', 'Hồ sơ Data Engineer của Hoàng Văn Hải', 'Python, Spark, Airflow, SQL', 'github.com/cand005', 'linkedin.com/in/cand005', 1),
  (29, 7, 'CV Python', 'Hồ sơ Python của Đỗ Quang Huy', 'Python, Django, Docker, MySQL', 'github.com/cand007', 'linkedin.com/in/cand007', 1),
  (30, 2, 'CV Java', 'Hồ sơ Java của Lê Văn Cường', 'Java, Spring Boot, SQL', 'github.com/cand002', 'linkedin.com/in/cand002', 1),
  (31, 10, 'CV Fresher', 'Hồ sơ Fresher của Đặng Thị Oanh', 'Java, SQL cơ bản', 'github.com/cand010', 'linkedin.com/in/cand010', 1),
  (32, 8, 'CV BA', 'Hồ sơ BA của Bùi Thị Lan', 'UML, SQL, Jira, giao tiếp', NULL, 'linkedin.com/in/cand008', 1),
  (33, 4, 'CV Data', 'Hồ sơ Data của Phạm Thị Giang', 'SQL, Python, Power BI, Excel', 'github.com/cand004', 'linkedin.com/in/cand004', 1),
  (34, 7, 'CV Python', 'Hồ sơ Python của Đỗ Quang Huy', 'Python, Django, Docker, MySQL', 'github.com/cand007', 'linkedin.com/in/cand007', 1),
  (35, 1, 'CV Backend', 'Hồ sơ Backend của Trần Thị Bảo', 'Python, FastAPI, MySQL, Docker', 'github.com/cand001', 'linkedin.com/in/cand001', 1),
  (36, 5, 'CV Data Engineer', 'Hồ sơ Data Engineer của Hoàng Văn Hải', 'Python, Spark, Airflow, SQL', 'github.com/cand005', 'linkedin.com/in/cand005', 1),
  (37, 9, 'CV Fullstack', 'Hồ sơ Fullstack của Ngô Văn Nam', 'JavaScript, React, NodeJS, MySQL', 'github.com/cand009', 'linkedin.com/in/cand009', 1);

INSERT INTO Education (education_id, resume_id, degree, school, graduation_year, gpa) VALUES
  (1, 1, 'Kỹ sư Công nghệ thông tin', 'Học viện Công nghệ Bưu chính Viễn thông', 2024, 8.20),
  (2, 2, 'Cử nhân Khoa học máy tính', 'Đại học Bách khoa Hà Nội', 2022, 7.90),
  (3, 3, 'Cử nhân Công nghệ thông tin', 'Đại học Công nghệ', 2023, 7.80),
  (4, 4, 'Cử nhân Hệ thống thông tin', 'Đại học Kinh tế Quốc dân', 2023, 8.40),
  (5, 5, 'Kỹ sư Khoa học dữ liệu', 'Đại học Bách khoa Hà Nội', 2021, 8.60),
  (6, 6, 'Cử nhân Công nghệ thông tin', 'Đại học Công nghiệp Hà Nội', 2025, 7.20),
  (7, 7, 'Kỹ sư Phần mềm', 'Đại học FPT', 2022, 8.00),
  (8, 8, 'Cử nhân Quản trị kinh doanh', 'Đại học Ngoại thương', 2022, 8.10),
  (9, 9, 'Cử nhân Công nghệ thông tin', 'Đại học Đà Nẵng', 2023, 7.50),
  (10, 10, 'Cử nhân Công nghệ thông tin', 'Đại học Cần Thơ', 2026, 7.00),
  (11, 11, 'Kỹ sư Phần mềm', 'Đại học Cần Thơ', 2024, 7.60),
  (12, 12, 'Cử nhân Marketing', 'Đại học Thương mại', 2024, 7.70),
  (13, 13, 'Kỹ sư Công nghệ thông tin', 'Học viện Công nghệ Bưu chính Viễn thông', 2024, 8.20),
  (14, 14, 'Kỹ sư Công nghệ thông tin', 'Học viện Công nghệ Bưu chính Viễn thông', 2024, 8.20),
  (15, 15, 'Kỹ sư Phần mềm', 'Đại học FPT', 2022, 8.00),
  (16, 16, 'Cử nhân Công nghệ thông tin', 'Đại học Đà Nẵng', 2023, 7.50),
  (17, 17, 'Cử nhân Khoa học máy tính', 'Đại học Bách khoa Hà Nội', 2022, 7.90),
  (18, 18, 'Cử nhân Công nghệ thông tin', 'Đại học Cần Thơ', 2026, 7.00),
  (19, 19, 'Cử nhân Công nghệ thông tin', 'Đại học Công nghệ', 2023, 7.80),
  (20, 20, 'Cử nhân Công nghệ thông tin', 'Đại học Đà Nẵng', 2023, 7.50),
  (21, 21, 'Cử nhân Công nghệ thông tin', 'Đại học Công nghiệp Hà Nội', 2025, 7.20),
  (22, 22, 'Cử nhân Công nghệ thông tin', 'Đại học Công nghiệp Hà Nội', 2025, 7.20),
  (23, 23, 'Cử nhân Công nghệ thông tin', 'Đại học Cần Thơ', 2026, 7.00),
  (24, 24, 'Cử nhân Hệ thống thông tin', 'Đại học Kinh tế Quốc dân', 2023, 8.40),
  (25, 25, 'Kỹ sư Công nghệ thông tin', 'Học viện Công nghệ Bưu chính Viễn thông', 2024, 8.20),
  (26, 26, 'Cử nhân Quản trị kinh doanh', 'Đại học Ngoại thương', 2022, 8.10),
  (27, 27, 'Kỹ sư Khoa học dữ liệu', 'Đại học Bách khoa Hà Nội', 2021, 8.60),
  (28, 28, 'Kỹ sư Khoa học dữ liệu', 'Đại học Bách khoa Hà Nội', 2021, 8.60),
  (29, 29, 'Kỹ sư Phần mềm', 'Đại học FPT', 2022, 8.00),
  (30, 30, 'Cử nhân Khoa học máy tính', 'Đại học Bách khoa Hà Nội', 2022, 7.90),
  (31, 31, 'Cử nhân Công nghệ thông tin', 'Đại học Cần Thơ', 2026, 7.00),
  (32, 32, 'Cử nhân Quản trị kinh doanh', 'Đại học Ngoại thương', 2022, 8.10),
  (33, 33, 'Cử nhân Hệ thống thông tin', 'Đại học Kinh tế Quốc dân', 2023, 8.40),
  (34, 34, 'Kỹ sư Phần mềm', 'Đại học FPT', 2022, 8.00),
  (35, 35, 'Kỹ sư Công nghệ thông tin', 'Học viện Công nghệ Bưu chính Viễn thông', 2024, 8.20),
  (36, 36, 'Kỹ sư Khoa học dữ liệu', 'Đại học Bách khoa Hà Nội', 2021, 8.60),
  (37, 37, 'Cử nhân Công nghệ thông tin', 'Đại học Đà Nẵng', 2023, 7.50);

INSERT INTO Experience (experience_id, resume_id, position, company_name, months, description) VALUES
  (1, 1, 'Backend Intern', 'XYZ Tech', 6, 'Xây dựng API bằng FastAPI'),
  (2, 1, 'Backend Developer', 'DEF Soft', 12, 'Phát triển hệ thống nội bộ'),
  (3, 2, 'Java Developer', 'VN Pay Solutions', 30, 'Dịch vụ thanh toán'),
  (4, 3, 'Frontend Developer', 'WebPro', 20, 'Giao diện React'),
  (5, 4, 'Data Analyst', 'Retail VN', 14, 'Báo cáo doanh thu'),
  (6, 5, 'Data Engineer', 'BigData VN', 36, 'Đường ống dữ liệu'),
  (7, 7, 'Python Developer', 'Soft Hub', 24, 'Ứng dụng Django'),
  (8, 8, 'Business Analyst', 'Bank Solutions', 18, 'Phân tích nghiệp vụ'),
  (9, 9, 'Web Developer', 'Media Online', 15, 'Ứng dụng web'),
  (10, 11, 'Mobile Developer', 'AppViet', 10, 'Ứng dụng di động'),
  (11, 13, 'Backend Intern', 'XYZ Tech', 6, 'Xử lý dữ liệu'),
  (12, 14, 'Backend Intern', 'XYZ Tech', 6, 'Xây dựng API bằng FastAPI'),
  (13, 14, 'Backend Developer', 'DEF Soft', 12, 'Phát triển hệ thống nội bộ'),
  (15, 15, 'Python Developer', 'Soft Hub', 24, 'Ứng dụng Django'),
  (16, 16, 'Web Developer', 'Media Online', 15, 'Ứng dụng web'),
  (17, 17, 'Java Developer', 'VN Pay Solutions', 30, 'Dịch vụ thanh toán'),
  (18, 19, 'Frontend Developer', 'WebPro', 20, 'Giao diện React'),
  (19, 20, 'Web Developer', 'Media Online', 15, 'Ứng dụng web'),
  (20, 24, 'Data Analyst', 'Retail VN', 14, 'Báo cáo doanh thu'),
  (21, 25, 'Backend Intern', 'XYZ Tech', 6, 'Xử lý dữ liệu'),
  (22, 26, 'Business Analyst', 'Bank Solutions', 18, 'Phân tích nghiệp vụ'),
  (23, 27, 'Data Engineer', 'BigData VN', 36, 'Đường ống dữ liệu'),
  (24, 28, 'Data Engineer', 'BigData VN', 36, 'Đường ống dữ liệu'),
  (25, 29, 'Python Developer', 'Soft Hub', 24, 'Ứng dụng Django'),
  (26, 30, 'Java Developer', 'VN Pay Solutions', 30, 'Dịch vụ thanh toán'),
  (27, 32, 'Business Analyst', 'Bank Solutions', 18, 'Phân tích nghiệp vụ'),
  (28, 33, 'Data Analyst', 'Retail VN', 14, 'Báo cáo doanh thu'),
  (29, 34, 'Python Developer', 'Soft Hub', 24, 'Ứng dụng Django'),
  (30, 35, 'Backend Intern', 'XYZ Tech', 6, 'Xây dựng API bằng FastAPI'),
  (31, 35, 'Backend Developer', 'DEF Soft', 12, 'Phát triển hệ thống nội bộ'),
  (33, 36, 'Data Engineer', 'BigData VN', 36, 'Đường ống dữ liệu'),
  (34, 37, 'Web Developer', 'Media Online', 15, 'Ứng dụng web');

INSERT INTO Certificate (certificate_id, resume_id, certificate_name, year) VALUES
  (1, 1, 'PCAP Python', 2024),
  (2, 2, 'Oracle Java SE', 2023),
  (3, 4, 'Microsoft Power BI', 2024),
  (4, 5, 'AWS Data Engineer', 2025),
  (5, 5, 'Databricks Spark', 2024),
  (6, 6, 'ISTQB Foundation', 2025),
  (7, 8, 'CBAP Entry (ECBA)', 2023),
  (8, 9, 'TOEIC 750', 2023),
  (9, 14, 'PCAP Python', 2024),
  (10, 16, 'TOEIC 750', 2023),
  (11, 17, 'Oracle Java SE', 2023),
  (12, 20, 'TOEIC 750', 2023),
  (13, 21, 'ISTQB Foundation', 2025),
  (14, 22, 'ISTQB Foundation', 2025),
  (15, 24, 'Microsoft Power BI', 2024),
  (16, 26, 'CBAP Entry (ECBA)', 2023),
  (17, 27, 'AWS Data Engineer', 2025),
  (18, 27, 'Databricks Spark', 2024),
  (20, 28, 'AWS Data Engineer', 2025),
  (21, 28, 'Databricks Spark', 2024),
  (23, 30, 'Oracle Java SE', 2023),
  (24, 32, 'CBAP Entry (ECBA)', 2023),
  (25, 33, 'Microsoft Power BI', 2024),
  (26, 35, 'PCAP Python', 2024),
  (27, 36, 'AWS Data Engineer', 2025),
  (28, 36, 'Databricks Spark', 2024),
  (30, 37, 'TOEIC 750', 2023);

INSERT INTO JobPosting (job_id, company_id, title, description, requirements, benefits, location, job_type, salary, min_experience_years, contact_email, open_date, deadline, status, is_finalized, created_at) VALUES
  (1, 1, 'Backend Developer', 'Phát triển API cho hệ thống ERP', 'Python, FastAPI, MySQL; 1 năm kinh nghiệm', NULL, 'Hà Nội', 'Full-time', '20-30 triệu', 1, 'hr01@example.test', DATE_SUB(CURDATE(), INTERVAL 15 DAY), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 'open', 0, DATE_SUB(CURDATE(), INTERVAL 15 DAY)),
  (2, 1, 'Frontend Developer', 'Xây dựng giao diện web', 'JavaScript, React, CSS; 1 năm kinh nghiệm', NULL, 'Hà Nội', 'Full-time', '18-28 triệu', 1, 'hr01@example.test', DATE_SUB(CURDATE(), INTERVAL 12 DAY), DATE_ADD(CURDATE(), INTERVAL 25 DAY), 'open', 0, DATE_SUB(CURDATE(), INTERVAL 12 DAY)),
  (3, 1, 'QA Intern', 'Kiểm thử phần mềm', 'Kiến thức kiểm thử, SQL cơ bản', NULL, 'Hà Nội', 'Internship', '4-6 triệu', 0, 'hr01@example.test', DATE_SUB(CURDATE(), INTERVAL 10 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY), 'open', 0, DATE_SUB(CURDATE(), INTERVAL 10 DAY)),
  (4, 2, 'Data Analyst', 'Phân tích dữ liệu kinh doanh', 'SQL, Python, Power BI; 1 năm kinh nghiệm', NULL, 'Hà Nội', 'Full-time', '18-25 triệu', 1, 'hr02@example.test', DATE_SUB(CURDATE(), INTERVAL 14 DAY), DATE_ADD(CURDATE(), INTERVAL 20 DAY), 'open', 0, DATE_SUB(CURDATE(), INTERVAL 14 DAY)),
  (5, 2, 'Data Engineer', 'Xây dựng đường ống dữ liệu', 'Python, Spark, Airflow, SQL; 2 năm kinh nghiệm', NULL, 'TP. Hồ Chí Minh', 'Full-time', '30-45 triệu', 2, 'hr02@example.test', DATE_SUB(CURDATE(), INTERVAL 8 DAY), DATE_ADD(CURDATE(), INTERVAL 35 DAY), 'open', 0, DATE_SUB(CURDATE(), INTERVAL 8 DAY)),
  (6, 3, 'Java Developer', 'Phát triển dịch vụ thanh toán', 'Java, Spring Boot, SQL; 2 năm kinh nghiệm', NULL, 'TP. Hồ Chí Minh', 'Full-time', '25-40 triệu', 2, 'hr03@example.test', DATE_SUB(CURDATE(), INTERVAL 11 DAY), DATE_ADD(CURDATE(), INTERVAL 28 DAY), 'open', 0, DATE_SUB(CURDATE(), INTERVAL 11 DAY)),
  (7, 3, 'Business Analyst', 'Phân tích nghiệp vụ tài chính', 'UML, SQL, kỹ năng giao tiếp; 1 năm kinh nghiệm', NULL, 'TP. Hồ Chí Minh', 'Contract', '20-30 triệu', 1, 'hr03@example.test', DATE_SUB(CURDATE(), INTERVAL 9 DAY), DATE_ADD(CURDATE(), INTERVAL 21 DAY), 'open', 0, DATE_SUB(CURDATE(), INTERVAL 9 DAY)),
  (8, 4, 'Content Creator', 'Biên soạn nội dung khóa học', 'Viết nội dung, thiết kế cơ bản', NULL, 'Đà Nẵng', 'Part-time', '8-12 triệu', 0, 'hr04@example.test', DATE_SUB(CURDATE(), INTERVAL 5 DAY), DATE_ADD(CURDATE(), INTERVAL 15 DAY), 'open', 0, DATE_SUB(CURDATE(), INTERVAL 5 DAY)),
  (9, 2, 'Python Developer', 'Phát triển công cụ nội bộ', 'Python, Docker, SQL; 1 năm kinh nghiệm', NULL, 'Hà Nội', 'Remote', '20-30 triệu', 1, 'hr02@example.test', DATE_SUB(CURDATE(), INTERVAL 20 DAY), DATE_ADD(CURDATE(), INTERVAL 5 DAY), 'closed', 1, DATE_SUB(CURDATE(), INTERVAL 20 DAY)),
  (10, 4, 'PHP Developer', 'Bảo trì hệ thống học tập', 'PHP, Laravel, MySQL; 2 năm kinh nghiệm', NULL, 'Đà Nẵng', 'Full-time', '18-25 triệu', 2, 'hr04@example.test', DATE_SUB(CURDATE(), INTERVAL 60 DAY), DATE_SUB(CURDATE(), INTERVAL 20 DAY), 'closed', 0, DATE_SUB(CURDATE(), INTERVAL 60 DAY));

INSERT INTO Application (candidate_id, job_id, resume_id, submitted_at, status, draft_decision, decided_at, education_score, skills_score, experience_score, education_comment, skills_comment, experience_comment, is_scored) VALUES
  (1, 1, 14, DATE_SUB(CURDATE(), INTERVAL 9 DAY), 'pending', 'approved', NULL, 85.00, 95.00, 90.00, 'Kỹ sư Công nghệ thông tin: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (Python, FastAPI, MySQL).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (1, 4, 25, DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'pending', NULL, NULL, 84.00, 70.00, 40.00, 'Kỹ sư Công nghệ thông tin: phù hợp tốt.', 'Đáp ứng một phần yêu cầu (SQL, Python, Power BI).', 'Kinh nghiệm chưa đáp ứng.', 1),
  (1, 9, 35, DATE_SUB(CURDATE(), INTERVAL 13 DAY), 'approved', NULL, NOW(), 86.00, 92.00, 85.00, 'Kỹ sư Công nghệ thông tin: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (Python, Docker, SQL).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (2, 1, 17, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'pending', NULL, NULL, 82.00, 35.00, 55.00, 'Cử nhân Khoa học máy tính: phù hợp tốt.', 'Còn thiếu nhiều yêu cầu (Python, FastAPI, MySQL).', 'Kinh nghiệm chưa đáp ứng.', 1),
  (2, 6, 30, DATE_SUB(CURDATE(), INTERVAL 9 DAY), 'pending', NULL, NULL, 84.00, 96.00, 94.00, 'Cử nhân Khoa học máy tính: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (Java, Spring Boot, SQL).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (3, 2, 19, DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'pending', NULL, NULL, 82.00, 95.00, 92.00, 'Cử nhân Công nghệ thông tin: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (JavaScript, React, CSS).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (4, 4, 24, DATE_SUB(CURDATE(), INTERVAL 10 DAY), 'pending', NULL, NULL, 88.00, 96.00, 88.00, 'Cử nhân Hệ thống thông tin: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (SQL, Python, Power BI).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (4, 7, 33, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'pending', NULL, NULL, 82.00, 65.00, 60.00, 'Cử nhân Hệ thống thông tin: phù hợp tốt.', 'Đáp ứng một phần yêu cầu (UML, SQL, kỹ năng giao tiếp).', 'Kinh nghiệm đáp ứng một phần.', 1),
  (5, 4, 27, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'pending', NULL, NULL, 90.00, 82.00, 85.00, 'Kỹ sư Khoa học dữ liệu: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (SQL, Python, Power BI).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (5, 5, 28, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'pending', NULL, NULL, 92.00, 98.00, 95.00, 'Kỹ sư Khoa học dữ liệu: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (Python, Spark, Airflow, SQL).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (5, 9, 36, DATE_SUB(CURDATE(), INTERVAL 12 DAY), 'rejected', NULL, NOW(), 90.00, 75.00, 80.00, 'Kỹ sư Khoa học dữ liệu: phù hợp tốt.', 'Đáp ứng một phần yêu cầu (Python, Docker, SQL).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (6, 2, 21, DATE_SUB(CURDATE(), INTERVAL 2 DAY), 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0),
  (6, 3, 22, DATE_SUB(CURDATE(), INTERVAL 7 DAY), 'pending', NULL, NULL, 82.00, 92.00, 70.00, 'Cử nhân Công nghệ thông tin: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (Kiến thức kiểm thử, SQL cơ bản).', 'Kinh nghiệm đáp ứng một phần.', 1),
  (7, 1, 15, DATE_SUB(CURDATE(), INTERVAL 8 DAY), 'pending', NULL, NULL, 85.00, 80.00, 92.00, 'Kỹ sư Phần mềm: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (Python, FastAPI, MySQL).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (7, 5, 29, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 'pending', NULL, NULL, 85.00, 50.00, 70.00, 'Kỹ sư Phần mềm: phù hợp tốt.', 'Còn thiếu nhiều yêu cầu (Python, Spark, Airflow, SQL).', 'Kinh nghiệm đáp ứng một phần.', 1),
  (7, 9, 34, DATE_SUB(CURDATE(), INTERVAL 14 DAY), 'approved', NULL, NOW(), 86.00, 94.00, 93.00, 'Kỹ sư Phần mềm: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (Python, Docker, SQL).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (8, 4, 26, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 'pending', NULL, NULL, 70.00, 50.00, 55.00, 'Cử nhân Quản trị kinh doanh: phù hợp một phần.', 'Còn thiếu nhiều yêu cầu (SQL, Python, Power BI).', 'Kinh nghiệm chưa đáp ứng.', 1),
  (8, 7, 32, DATE_SUB(CURDATE(), INTERVAL 7 DAY), 'pending', NULL, NULL, 80.00, 94.00, 90.00, 'Cử nhân Quản trị kinh doanh: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (UML, SQL, kỹ năng giao tiếp).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (9, 1, 16, DATE_SUB(CURDATE(), INTERVAL 7 DAY), 'pending', NULL, NULL, 80.00, 45.00, 60.00, 'Cử nhân Công nghệ thông tin: phù hợp tốt.', 'Còn thiếu nhiều yêu cầu (Python, FastAPI, MySQL).', 'Kinh nghiệm đáp ứng một phần.', 1),
  (9, 2, 20, DATE_SUB(CURDATE(), INTERVAL 6 DAY), 'pending', NULL, NULL, 80.00, 90.00, 85.00, 'Cử nhân Công nghệ thông tin: phù hợp tốt.', 'Đáp ứng hầu hết yêu cầu (JavaScript, React, CSS).', 'Kinh nghiệm đáp ứng yêu cầu.', 1),
  (9, 9, 37, DATE_SUB(CURDATE(), INTERVAL 11 DAY), 'rejected', NULL, NOW(), 78.00, 40.00, 55.00, 'Cử nhân Công nghệ thông tin: phù hợp một phần.', 'Còn thiếu nhiều yêu cầu (Python, Docker, SQL).', 'Kinh nghiệm chưa đáp ứng.', 1),
  (10, 1, 18, DATE_SUB(CURDATE(), INTERVAL 3 DAY), 'pending', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0),
  (10, 3, 23, DATE_SUB(CURDATE(), INTERVAL 5 DAY), 'pending', NULL, NULL, 78.00, 60.00, 40.00, 'Cử nhân Công nghệ thông tin: phù hợp một phần.', 'Đáp ứng một phần yêu cầu (Kiến thức kiểm thử, SQL cơ bản).', 'Kinh nghiệm chưa đáp ứng.', 1),
  (10, 6, 31, DATE_SUB(CURDATE(), INTERVAL 4 DAY), 'pending', NULL, NULL, 75.00, 55.00, 10.00, 'Cử nhân Công nghệ thông tin: phù hợp một phần.', 'Còn thiếu nhiều yêu cầu (Java, Spring Boot, SQL).', 'Kinh nghiệm chưa đáp ứng.', 1);

INSERT INTO Notification (notification_id, account_id, title, content, is_read) VALUES
  (1, 5, 'Your application has been approved', 'Result for position Python Developer: approved', 0),
  (2, 9, 'Application result', 'Result for position Python Developer: not a match', 1),
  (3, 11, 'Your application has been approved', 'Result for position Python Developer: approved', 0),
  (4, 13, 'Application result', 'Result for position Python Developer: not a match', 0);

-- ===== 3. CÁC CÂU TRUY VẤN =====

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
