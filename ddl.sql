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
