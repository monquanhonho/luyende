-- ==========================================================
-- HỆ THỐNG WEB LUYỆN ĐỀ TRẮC NGHIỆM (TOÁN - ANH - LÝ - HÓA)
-- Phiên bản: 4.0 | Kho 8 Đề Sát Đề THPT Quốc Gia Các Năm (340 Câu)
--   * Môn Toán (2 đề): 50 câu - 90 phút - 0.20đ/câu (= 10.00đ)
--   * Tiếng Anh, Vật Lý, Hóa Học (mỗi môn 2 đề): 40 câu - 60 phút - 0.25đ/câu (= 10.00đ)
-- ==========================================================

CREATE DATABASE IF NOT EXISTS `webluyende` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `webluyende`;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `attempt_answers`;
DROP TABLE IF EXISTS `exam_sessions`;
DROP TABLE IF EXISTS `exam_attempts`;
DROP TABLE IF EXISTS `questions`;
DROP TABLE IF EXISTS `exams`;
DROP TABLE IF EXISTS `subjects`;
DROP TABLE IF EXISTS `users`;
SET FOREIGN_KEY_CHECKS = 1;

-- 1. Bảng Người dùng (Phân quyền: admin / student)
CREATE TABLE `users` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `password` VARCHAR(255) NOT NULL,
  `fullname` VARCHAR(100) NOT NULL,
  `email` VARCHAR(100) DEFAULT NULL,
  `class_name` VARCHAR(50) DEFAULT 'Học sinh',
  `role` ENUM('admin', 'student') NOT NULL DEFAULT 'student',
  `last_active_at` TIMESTAMP NULL DEFAULT NULL,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Bảng Môn học (Toán, Tiếng Anh, Vật Lý, Hóa Học)
CREATE TABLE `subjects` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(20) NOT NULL UNIQUE,
  `name` VARCHAR(100) NOT NULL,
  `description` VARCHAR(255) NOT NULL,
  `icon` VARCHAR(50) NOT NULL,
  `color_theme` VARCHAR(30) NOT NULL,
  `gradient` VARCHAR(150) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Bảng Đề thi (Chuẩn THPT QG)
CREATE TABLE `exams` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `subject_id` INT NOT NULL,
  `title` VARCHAR(200) NOT NULL,
  `description` TEXT,
  `duration_minutes` INT NOT NULL DEFAULT 60,
  `level` ENUM('Cơ bản', 'Thông hiểu', 'Vận dụng cao', 'Chuẩn THPT QG') NOT NULL DEFAULT 'Chuẩn THPT QG',
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`subject_id`) REFERENCES `subjects`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Bảng Câu hỏi (hỗ trợ đa dạng + thang điểm 0.20 / 0.25 + mức độ)
CREATE TABLE `questions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `exam_id` INT NOT NULL,
  `question_type` ENUM('mcq', 'true_false', 'short_answer') NOT NULL DEFAULT 'mcq',
  `question_text` TEXT NOT NULL,
  `option_a` TEXT NULL,
  `option_b` TEXT NULL,
  `option_c` TEXT NULL,
  `option_d` TEXT NULL,
  `correct_option` VARCHAR(50) NOT NULL,
  `explanation` TEXT,
  `points_value` DECIMAL(4,2) NOT NULL DEFAULT 0.25,
  `difficulty` ENUM('Nhận biết', 'Thông hiểu', 'Vận dụng', 'Vận dụng cao') NOT NULL DEFAULT 'Nhận biết',
  `sort_order` INT DEFAULT 1,
  FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Bảng Lịch sử làm bài của học sinh
CREATE TABLE `exam_attempts` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `exam_id` INT NOT NULL,
  `score` DECIMAL(4,2) NOT NULL DEFAULT 0.00,
  `correct_count` INT NOT NULL DEFAULT 0,
  `total_questions` INT NOT NULL DEFAULT 0,
  `time_spent_seconds` INT NOT NULL DEFAULT 0,
  `tab_switch_count` INT NOT NULL DEFAULT 0,
  `completed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Bảng Chi tiết đáp án & điểm từng câu trong mỗi lần thi
CREATE TABLE `attempt_answers` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `attempt_id` INT NOT NULL,
  `question_id` INT NOT NULL,
  `selected_option` VARCHAR(50) DEFAULT NULL,
  `is_correct` TINYINT(1) NOT NULL DEFAULT 0,
  `earned_points` DECIMAL(4,2) NOT NULL DEFAULT 0.00,
  FOREIGN KEY (`attempt_id`) REFERENCES `exam_attempts`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`question_id`) REFERENCES `questions`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Bảng Theo dõi phiên làm bài trực tiếp (Giám sát học sinh)
CREATE TABLE `exam_sessions` (
  `id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `exam_id` INT NOT NULL,
  `started_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `last_heartbeat` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `elapsed_seconds` INT NOT NULL DEFAULT 0,
  `answered_count` INT NOT NULL DEFAULT 0,
  `total_questions` INT NOT NULL DEFAULT 0,
  `tab_switch_count` INT NOT NULL DEFAULT 0,
  `status` ENUM('in_progress', 'submitted') NOT NULL DEFAULT 'in_progress',
  FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE,
  FOREIGN KEY (`exam_id`) REFERENCES `exams`(`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ==========================================================
-- TÀI KHOẢN MẪU (admin / 123456 | hocsinh / 123456)
-- ==========================================================
INSERT INTO `users` (`username`, `password`, `fullname`, `email`, `class_name`, `role`) VALUES
('admin', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Thầy Giáo Quản Trị (Admin)', 'admin@edusmart.vn', 'Ban Chuyên Môn', 'admin'),
('hocsinh', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Nguyễn Minh Khôi', 'minhkhoi@edusmart.vn', 'Lớp 12A1 - Chuyên Tự Nhiên', 'student'),
('linhchi', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Trần Ngọc Linh Chi', 'linhchi@edusmart.vn', 'Lớp 12D1 - Khối D', 'student');

-- ==========================================================
-- 4 BỘ MÔN CHÍNH
-- ==========================================================
INSERT INTO `subjects` (`id`, `code`, `name`, `description`, `icon`, `color_theme`, `gradient`) VALUES
(1, 'TOAN', 'Toán Học', '22 câu (12 TN • 4 Đ/S • 6 TLN) • 90 phút — Chuẩn đề THPT 2025 (GDPT 2018)', 'fa-square-root-variable', 'blue', 'from-blue-600 to-indigo-600'),
(2, 'ANH', 'Tiếng Anh', '40 câu • 50 phút • 0.25đ/câu — Chuẩn đề thi tốt nghiệp THPT 2026', 'fa-earth-americas', 'emerald', 'from-emerald-500 to-teal-600'),
(3, 'LY', 'Vật Lý', '28 câu (18 TN • 4 Đ/S • 6 TLN) • 50 phút — Chuẩn đề THPT 2025 (GDPT 2018)', 'fa-atom', 'amber', 'from-amber-500 to-orange-600'),
(4, 'HOA', 'Hóa Học', '28 câu (18 TN • 4 Đ/S • 6 TLN) • 50 phút — Chuẩn đề THPT 2025 (GDPT 2018)', 'fa-flask-vial', 'rose', 'from-rose-500 to-pink-600');

-- ==========================================================
-- 8 ĐỀ THI CHUẨN THPT QUỐC GIA (GDPT 2018)
-- ==========================================================
INSERT INTO `exams` (`id`, `subject_id`, `title`, `description`, `duration_minutes`, `level`, `is_active`) VALUES
(1, 1, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Toán - Đề Số 01', '22 câu – 90 phút chuẩn cấu trúc mới 2025: Phần I (12 câu TN ABCD - 3.0đ), Phần II (4 câu Đúng/Sai - 4.0đ), Phần III (6 câu Trả lời ngắn - 3.0đ).', 90, 'Chuẩn THPT QG', 1),
(2, 1, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Toán - Đề Số 02', '22 câu – 90 phút chuẩn cấu trúc mới 2025: Hàm số, Tích phân, Thống kê ghép nhóm, Xác suất có điều kiện - Bayes, Hình không gian & Oxyz.', 90, 'Chuẩn THPT QG', 1),
(3, 2, 'Đề Thi Thử THPT Quốc Gia 2026 Môn Tiếng Anh - Đề Số 01', '40 câu – 50 phút (0.25đ/câu). Bám sát cấu trúc mới: Đọc điền quảng cáo, tờ rơi, sắp xếp hội thoại/đoạn văn, điền khuyết ngữ cảnh và 2 bài đọc hiểu.', 50, 'Chuẩn THPT QG', 1),
(4, 2, 'Đề Thi Thử THPT Quốc Gia 2026 Môn Tiếng Anh - Đề Số 02', '40 câu – 50 phút (0.25đ/câu). Tổng hợp Phát âm, Trọng âm, Ngữ pháp trọng tâm, Đồng/Trái nghĩa, Tìm lỗi sai, Viết lại câu và Đọc hiểu.', 50, 'Chuẩn THPT QG', 1),
(5, 3, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Vật Lý - Đề Số 01', '28 câu – 50 phút chuẩn cấu trúc mới 2025: Phần I (18 câu TN ABCD - 4.5đ), Phần II (4 câu Đúng/Sai - 4.0đ), Phần III (6 câu Trả lời ngắn - 1.5đ).', 50, 'Chuẩn THPT QG', 1),
(6, 3, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Vật Lý - Đề Số 02', '28 câu – 50 phút chuẩn cấu trúc mới 2025: Vật lý nhiệt, Khí lí tưởng, Dao động & Sóng, Từ trường, Điện xoay chiều & Hạt nhân (GDPT 2018).', 50, 'Chuẩn THPT QG', 1),
(7, 4, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Hóa Học - Đề Số 01', '28 câu – 50 phút chuẩn cấu trúc mới 2025: Phần I (18 câu TN ABCD - 4.5đ), Phần II (4 câu Đúng/Sai - 4.0đ), Phần III (6 câu Trả lời ngắn - 1.5đ).', 50, 'Chuẩn THPT QG', 1),
(8, 4, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Hóa Học - Đề Số 02', '28 câu – 50 phút chuẩn cấu trúc mới 2025 (ĐKC 24.79 lít/mol): Este-Lipit, Cacbohidrat, Amin-Peptit, Pin điện hóa, Phức chất & Kim loại.', 50, 'Chuẩn THPT QG', 1);

-- ==========================================================
-- MÔN TOÁN - ĐỀ SỐ 01 (exam_id = 1): 22 CÂU - 90 PHÚT - TỔNG 10.00 ĐIỂM
-- Phần I: 12 câu mcq (0.25đ) | Phần II: 4 câu true_false (1.00đ) | Phần III: 6 câu short_answer (0.50đ)
-- ==========================================================
INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
-- Phần I: Trắc nghiệm nhiều phương án lựa chọn (1 - 12)
(1, 'mcq', 'Hàm số y = -x³ + 3x + 2 đồng biến trên khoảng nào dưới đây?', '(-1; 1)', '(-∞; -1)', '(1; +∞)', '(-∞; +∞)', 'A', 'y'' = -3x² + 3 > 0 ⇔ x² < 1 ⇔ -1 < x < 1.', 0.25, 'Nhận biết', 1),
(1, 'mcq', 'Tiệm cận đứng của đồ thị hàm số y = (2x - 1)/(x + 3) là đường thẳng có phương trình:', 'x = -3', 'y = 2', 'x = 3', 'y = -1/3', 'A', 'Mẫu số x + 3 = 0 ⇔ x = -3 (không là nghiệm tử số) nên x = -3 là tiệm cận đứng.', 0.25, 'Nhận biết', 2),
(1, 'mcq', 'Nguyên hàm của hàm số f(x) = 4x³ + sin(x) là:', 'x⁴ - cos(x) + C', 'x⁴ + cos(x) + C', '12x² - cos(x) + C', 'x⁴ - sin(x) + C', 'A', '∫(4x³ + sin x)dx = x⁴ - cos(x) + C.', 0.25, 'Nhận biết', 3),
(1, 'mcq', 'Tập nghiệm của bất phương trình log₂(x - 1) < 3 là:', '(1; 9)', '(-∞; 9)', '(9; +∞)', '(1; 7)', 'A', 'Điều kiện x > 1. BPT ⇔ x - 1 < 2³ = 8 ⇔ x < 9. Vậy tập nghiệm là (1; 9).', 0.25, 'Nhận biết', 4),
(1, 'mcq', 'Trong không gian Oxyz, cho hai điểm A(1; -2; 3) và B(3; 0; -1). Tọa độ vectơ AB là:', '(2; 2; -4)', '(4; -2; 2)', '(-2; -2; 4)', '(2; -1; 1)', 'A', 'AB = (3-1; 0-(-2); -1-3) = (2; 2; -4).', 0.25, 'Nhận biết', 5),
(1, 'mcq', 'Cho cấp số nhân (uₙ) có u₁ = 3 và công bội q = 2. Giá trị của u₄ bằng:', '24', '12', '48', '16', 'A', 'u₄ = u₁.q³ = 3 × 2³ = 24.', 0.25, 'Nhận biết', 6),
(1, 'mcq', 'Khảo sát thời gian tập thể dục (phút/ngày) của một nhóm học sinh: [0;20): 5, [20;40): 12, [40;60): 8. Nhóm chứa mốt của mẫu số liệu ghép nhóm là:', '[20; 40)', '[0; 20)', '[40; 60)', '[0; 60)', 'A', 'Nhóm có tần số lớn nhất (12 học sinh) là nhóm [20; 40).', 0.25, 'Nhận biết', 7),
(1, 'mcq', 'Trong không gian Oxyz, mặt phẳng (P): 3x - y + 2z - 6 = 0 đi qua điểm nào dưới đây?', 'M(2; 0; 0)', 'N(0; 6; 0)', 'P(0; 0; -3)', 'Q(1; 1; 1)', 'A', 'Thay M(2; 0; 0) vào (P): 3(2) - 0 + 0 - 6 = 0 (thỏa mãn).', 0.25, 'Nhận biết', 8),
(1, 'mcq', 'Cho hai biến cố độc lập A và B với P(A) = 0.4 và P(B) = 0.5. Xác suất P(A ∩ B) bằng:', '0.20', '0.90', '0.10', '0.45', 'A', 'Vì A, B độc lập nên P(A ∩ B) = P(A).P(B) = 0.4 × 0.5 = 0.20.', 0.25, 'Thông hiểu', 9),
(1, 'mcq', 'Giá trị lớn nhất của hàm số f(x) = x + 4/x trên đoạn [1; 3] bằng:', '5', '4', '13/3', '6', 'A', 'f''(x) = 1 - 4/x² = 0 ⇒ x = 2 ∈ [1; 3]. f(1) = 5, f(2) = 4, f(3) = 13/3 ⇒ GTLN bằng 5.', 0.25, 'Thông hiểu', 10),
(1, 'mcq', 'Diện tích hình phẳng giới hạn bởi đồ thị hàm số y = eˣ, trục hoành và hai đường thẳng x = 0, x = 2 là:', 'e² - 1', 'e²', 'e² + 1', '2e', 'A', 'S = ∫(0→2) eˣ dx = e² - e⁰ = e² - 1.', 0.25, 'Thông hiểu', 11),
(1, 'mcq', 'Cho hình chóp S.ABCD có đáy là hình vuông cạnh a, SA ⊥ (ABCD) và SA = a√3. Góc giữa đường thẳng SC và mặt phẳng (ABCD) gần nhất với giá trị nào?', '50.8°', '45°', '60°', '30°', 'A', 'AC = a√2. tan(SC, (ABCD)) = SA/AC = √3/√2 = √6/2 ≈ 1.2247 ⇒ góc ≈ 50.77°.', 0.25, 'Thông hiểu', 12),

-- Phần II: Trắc nghiệm Đúng / Sai 4 ý (13 - 16)
(1, 'true_false', 'Cho hàm số bậc ba y = f(x) = x³ - 3x² + 2. Xét tính đúng sai của các khẳng định sau:', 'a) Đạo hàm của hàm số là f''(x) = 3x² - 6x.', 'b) Hàm số đạt cực đại tại x = 2.', 'c) Giá trị cực tiểu của hàm số bằng -2.', 'd) Đường thẳng đi qua hai điểm cực trị của đồ thị hàm số là y = -2x + 2.', 'D,S,D,D', 'a) Đúng: f''(x) = 3x² - 6x.\nb) Sai: f''(x) = 0 ⇔ x = 0 (CĐ) hoặc x = 2 (CT).\nc) Đúng: y_CT = f(2) = 8 - 12 + 2 = -2.\nd) Đúng: Hai điểm cực trị là A(0; 2) và B(2; -2) đều nằm trên y = -2x + 2.', 1.00, 'Thông hiểu', 13),
(1, 'true_false', 'Một ô tô đang chạy với tốc độ 20 m/s thì người lái xe hãm phanh, từ thời điểm đó ô tô chuyển động chậm dần đều với vận tốc v(t) = 20 - 4t (m/s), trong đó t (giây) là khoảng thời gian tính từ lúc hãm phanh.', 'a) Gia tốc của ô tô trong quá trình hãm phanh là -4 m/s².', 'b) Thời gian từ lúc hãm phanh đến khi ô tô dừng hẳn là 5 giây.', 'c) Quãng đường ô tô đi được trong 3 giây đầu tiên kể từ lúc hãm phanh là 42 m.', 'd) Tổng quãng đường ô tô đi được từ lúc hãm phanh cho đến khi dừng hẳn là 60 m.', 'D,D,D,S', 'a) Đúng: a(t) = v''(t) = -4 m/s².\nb) Đúng: v(t) = 0 ⇔ 20 - 4t = 0 ⇔ t = 5 s.\nc) Đúng: S(3) = ∫(0→3)(20 - 4t)dt = [20t - 2t²](0→3) = 60 - 18 = 42 m.\nd) Sai: S(5) = ∫(0→5)(20 - 4t)dt = 100 - 50 = 50 m.', 1.00, 'Vận dụng', 14),
(1, 'true_false', 'Trong không gian Oxyz, cho điểm A(1; 2; -1), đường thẳng d: (x - 2)/1 = (y + 1)/2 = z/(-2) và mặt phẳng (P): 2x - y + 2z - 3 = 0.', 'a) Một vectơ chỉ phương của đường thẳng d là u = (1; 2; -2).', 'b) Một vectơ pháp tuyến của mặt phẳng (P) là n = (2; -1; 2).', 'c) Đường thẳng d vuông góc với mặt phẳng (P).', 'd) Khoảng cách từ điểm A đến mặt phẳng (P) bằng 5/3.', 'D,D,S,D', 'a) Đúng.\nb) Đúng.\nc) Sai: u.n = 1.2 + 2(-1) + (-2)(2) = -4 ≠ 0 (không vuông góc).\nd) Đúng: d(A, (P)) = |2(1) - 2 + 2(-1) - 3| / √(4+1+4) = |-5|/3 = 5/3.', 1.00, 'Vận dụng', 15),
(1, 'true_false', 'Một hộp chứa 6 quả cầu xanh và 4 quả cầu đỏ có kích thước và khối lượng giống nhau. Lấy ngẫu nhiên liên tiếp 2 quả cầu không hoàn lại từ hộp.', 'a) Số phần tử của không gian mẫu là 90.', 'b) Xác suất để quả cầu thứ nhất lấy ra màu xanh là 0.6.', 'c) Xác suất để quả cầu thứ hai lấy ra màu đỏ, biết rằng quả thứ nhất màu xanh, là 4/9.', 'd) Xác suất để cả 2 quả cầu lấy ra đều có màu đỏ bằng 1/6.', 'D,D,D,S', 'a) Đúng: 10 × 9 = 90.\nb) Đúng: 6/10 = 0.6.\nc) Đúng: Còn 9 quả trong đó 4 quả đỏ ⇒ P(Đ₂|X₁) = 4/9.\nd) Sai: P(Đ₁ ∩ Đ₂) = (4/10)×(3/9) = 12/90 = 2/15.', 1.00, 'Vận dụng cao', 16),

-- Phần III: Trắc nghiệm Trả lời ngắn (17 - 22)
(1, 'short_answer', 'Cho mẫu số liệu ghép nhóm về chiều cao của 40 cây giống: [10;20): 8, [20;30): 16, [30;40): 12, [40;50): 4. Tính số trung bình cộng (cm) của mẫu số liệu ghép nhóm trên.', NULL, NULL, NULL, NULL, '28', 'Giá trị đại diện các nhóm là 15, 25, 35, 45. Số TB = (15×8 + 25×16 + 35×12 + 45×4)/40 = 1120/40 = 28.', 0.50, 'Thông hiểu', 17),
(1, 'short_answer', 'Cho hình chóp S.ABCD có đáy ABCD là hình chữ nhật với AB = 3, AD = 4, cạnh bên SA ⊥ (ABCD) và SA = 5. Tính thể tích khối chóp S.ABCD.', NULL, NULL, NULL, NULL, '20', 'Diện tích đáy B = 3 × 4 = 12. Thể tích V = (1/3)Bh = (1/3) × 12 × 5 = 20.', 0.50, 'Thông hiểu', 18),
(1, 'short_answer', 'Một hộ gia đình sản xuất tối đa 100 sản phẩm mỗi tháng. Nếu bán x sản phẩm thì giá mỗi sản phẩm là p(x) = 50 - 0.2x (nghìn đồng) và tổng chi phí là C(x) = 10x + 200 (nghìn đồng). Hỏi hộ gia đình cần sản xuất bao nhiêu sản phẩm để lợi nhuận đạt lớn nhất?', NULL, NULL, NULL, NULL, '100', 'Lợi nhuận L(x) = -0.2x² + 40x - 200. Đạo hàm L''(x) = -0.4x + 40 = 0 ⇒ x = 100.', 0.50, 'Vận dụng', 19),
(1, 'short_answer', 'Tính diện tích S của hình phẳng giới hạn bởi hai đường parabol y = x² - 2x và y = -x² + 4x.', NULL, NULL, NULL, NULL, '9', 'Hoành độ giao điểm: x = 0 hoặc x = 3. S = ∫(0→3)(6x - 2x²)dx = [3x² - (2/3)x³](0→3) = 27 - 18 = 9.', 0.50, 'Vận dụng', 20),
(1, 'short_answer', 'Trong không gian Oxyz, một trạm thu phát sóng đặt tại I(1; 2; 3) có bán kính phủ sóng R = 5. Điểm M(4; 6; z) nằm trên mặt biên vùng phủ sóng (IM = 5) và có cao độ z > 0. Tính giá trị của z.', NULL, NULL, NULL, NULL, '3', 'IM² = (4-1)² + (6-2)² + (z-3)² = 25 ⇔ 9 + 16 + (z-3)² = 25 ⇔ z = 3.', 0.50, 'Vận dụng cao', 21),
(1, 'short_answer', 'Một doanh nghiệp có 2 nhà máy A và B cùng sản xuất linh kiện. Nhà máy A sản xuất 60% sản lượng với tỉ lệ phế phẩm 2%; nhà máy B sản xuất 40% sản lượng với tỉ lệ phế phẩm 5%. Chọn ngẫu nhiên một linh kiện thấy đó là phế phẩm. Tính xác suất để linh kiện đó do nhà máy B sản xuất (làm tròn đến hàng phần trăm).', NULL, NULL, NULL, NULL, '0.63', 'Theo công thức Bayes: P(B|PP) = (0.4 × 0.05) / (0.6 × 0.02 + 0.4 × 0.05) = 0.02 / 0.032 = 0.625 ≈ 0.63.', 0.50, 'Vận dụng cao', 22);

-- ==========================================================
-- MÔN TOÁN - ĐỀ SỐ 02 (exam_id = 2): 22 CÂU - 90 PHÚT - TỔNG 10.00 ĐIỂM
-- Phần I: 12 câu mcq (0.25đ) | Phần II: 4 câu true_false (1.00đ) | Phần III: 6 câu short_answer (0.50đ)
-- ==========================================================
INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
-- Phần I: Trắc nghiệm nhiều phương án lựa chọn (1 - 12)
(2, 'mcq', 'Khảo sát cân nặng (kg) của 30 học sinh: [40;45): 4, [45;50): 8, [50;55): 12, [55;60): 6. Nhóm chứa trung vị của mẫu số liệu ghép nhóm trên là:', '[50; 55)', '[45; 50)', '[40; 45)', '[55; 60)', 'A', 'n/2 = 15. Tần số tích lũy đến hết nhóm [45;50) là 12 < 15; đến hết nhóm [50;55) là 24 ≥ 15 ⇒ nhóm chứa trung vị là [50; 55).', 0.25, 'Nhận biết', 1),
(2, 'mcq', 'Họ nguyên hàm của hàm số f(x) = 1/x (với x > 0) là:', 'ln(x) + C', '-1/x² + C', '2√x + C', 'eˣ + C', 'A', 'Trên (0; +∞), ∫(1/x)dx = ln(x) + C.', 0.25, 'Nhận biết', 2),
(2, 'mcq', 'Tập nghiệm của phương trình log₃(x) = 2 là:', '{9}', '{6}', '{8}', '{3}', 'A', 'log₃(x) = 2 ⇔ x = 3² = 9.', 0.25, 'Nhận biết', 3),
(2, 'mcq', 'Cho cấp số cộng (uₙ) có u₁ = 2 và công sai d = 4. Giá trị của u₆ bằng:', '22', '24', '20', '18', 'A', 'u₆ = u₁ + 5d = 2 + 5×4 = 22.', 0.25, 'Nhận biết', 4),
(2, 'mcq', 'Trong không gian Oxyz, mặt cầu (S): x² + y² + z² - 2x + 4y - 6z - 2 = 0 có tâm là:', 'I(1; -2; 3)', 'I(-1; 2; -3)', 'I(2; -4; 6)', 'I(1; 2; 3)', 'A', 'Chia hệ số x, y, z cho -2 ta được tâm I(1; -2; 3).', 0.25, 'Nhận biết', 5),
(2, 'mcq', 'Cho hàm số y = (ax + b)/(cx + d) có tiệm cận đứng x = 1 và tiệm cận ngang y = -2. Giá trị của tỉ số a/c bằng:', '-2', '1', '2', '-1', 'A', 'Tiệm cận ngang y = a/c = -2.', 0.25, 'Nhận biết', 6),
(2, 'mcq', 'Nếu ∫(0→4) f(x)dx = 10 thì ∫(0→4) [f(x) + 2]dx bằng:', '18', '12', '14', '20', 'A', '∫(0→4)f(x)dx + ∫(0→4)2dx = 10 + 8 = 18.', 0.25, 'Nhận biết', 7),
(2, 'mcq', 'Cho hai biến cố A và B với P(A) > 0. Công thức nhân xác suất đúng là:', 'P(A ∩ B) = P(A) . P(B | A)', 'P(A ∩ B) = P(A) + P(B | A)', 'P(A ∩ B) = P(B) . P(B | A)', 'P(A ∩ B) = P(A) / P(B | A)', 'A', 'Theo quy tắc nhân xác suất: P(A ∩ B) = P(A).P(B | A).', 0.25, 'Nhận biết', 8),
(2, 'mcq', 'Giá trị nhỏ nhất của hàm số y = x⁴ - 2x² + 5 trên đoạn [-1; 2] bằng:', '4', '5', '13', '3', 'A', 'y'' = 4x³ - 4x = 0 ⇒ x = 0; ±1. y(±1) = 4, y(0) = 5, y(2) = 13 ⇒ GTNN bằng 4.', 0.25, 'Thông hiểu', 9),
(2, 'mcq', 'Cho log₂(3) = a. Giá trị của log₂(24) theo a bằng:', '3 + a', '3a', '2 + a', '4a', 'A', 'log₂(24) = log₂(8 × 3) = 3 + a.', 0.25, 'Thông hiểu', 10),
(2, 'mcq', 'Trong không gian Oxyz, đường thẳng d đi qua A(2; 0; -1) và B(4; -2; 3) có một vectơ chỉ phương là:', 'u = (1; -1; 2)', 'u = (2; 2; 4)', 'u = (6; -2; 2)', 'u = (1; 1; 2)', 'A', 'AB = (2; -2; 4) = 2(1; -1; 2) ⇒ chọn u = (1; -1; 2).', 0.25, 'Thông hiểu', 11),
(2, 'mcq', 'Cho hình chóp S.ABCD có đáy là hình thoi cạnh a, góc BAD = 60°, SA ⊥ (ABCD) và SA = a√3. Thể tích khối chóp S.ABCD bằng:', 'a³/2', 'a³√3/2', 'a³/4', 'a³', 'A', 'S_ABCD = a².sin60° = a²√3/2 ⇒ V = (1/3).(a²√3/2).(a√3) = a³/2.', 0.25, 'Thông hiểu', 12),

-- Phần II: Trắc nghiệm Đúng / Sai 4 ý (13 - 16)
(2, 'true_false', 'Cho hàm số phân thức y = f(x) = (x² - 2x + 2) / (x - 1). Xét tính đúng sai của các khẳng định sau:', 'a) Tập xác định của hàm số là D = ℝ \\ {1}.', 'b) Đồ thị hàm số có tiệm cận đứng là đường thẳng x = 1.', 'c) Tiệm cận xiên của đồ thị hàm số là đường thẳng y = x - 1.', 'd) Hàm số đạt cực đại tại x = 2.', 'D,D,D,S', 'a) Đúng: ĐK x - 1 ≠ 0.\nb) Đúng.\nc) Đúng: f(x) = x - 1 + 1/(x - 1) nên tiệm cận xiên y = x - 1.\nd) Sai: f''(x) = 1 - 1/(x - 1)² = 0 ⇔ x = 0 (CĐ) hoặc x = 2 (CT).', 1.00, 'Thông hiểu', 13),
(2, 'true_false', 'Một chất điểm chuyển động thẳng với phương trình vận tốc v(t) = t² - 4t + 3 (m/s), trong đó t ≥ 0 tính bằng giây.', 'a) Vận tốc ban đầu của chất điểm tại t = 0 là 3 m/s.', 'b) Gia tốc của chất điểm tại thời điểm t = 3 s là 2 m/s².', 'c) Trong khoảng thời gian từ t = 1 s đến t = 3 s, chất điểm chuyển động theo chiều dương.', 'd) Quãng đường chất điểm đi được trong 3 giây đầu tiên là 8/3 m.', 'D,D,S,D', 'a) Đúng: v(0) = 3 m/s.\nb) Đúng: a(t) = v''(t) = 2t - 4 ⇒ a(3) = 2 m/s².\nc) Sai: Với t ∈ (1; 3) thì v(t) = (t-1)(t-3) < 0 (chuyển động theo chiều âm).\nd) Đúng: S = ∫(0→1)(t²-4t+3)dt + ∫(1→3)|t²-4t+3|dt = 4/3 + 4/3 = 8/3 m.', 1.00, 'Vận dụng', 14),
(2, 'true_false', 'Trong không gian Oxyz, cho hai điểm A(1; 0; 2), B(3; 2; 0) và mặt phẳng (P): x + y - z + 3 = 0.', 'a) Trung điểm I của đoạn thẳng AB có tọa độ là (2; 1; 1).', 'b) Vectơ pháp tuyến của mặt phẳng (P) là n = (1; 1; -1).', 'c) Đường thẳng AB song song với mặt phẳng (P).', 'd) Mặt phẳng trung trực của đoạn thẳng AB có phương trình là x + y - z - 2 = 0.', 'D,D,S,D', 'a) Đúng.\nb) Đúng.\nc) Sai: AB = (2; 2; -2) = 2n ⇒ đường thẳng AB vuông góc với (P).\nd) Đúng: đi qua I(2; 1; 1) với VTPT n = (1; 1; -1) ⇒ 1(x-2)+1(y-1)-1(z-1)=0 ⇔ x+y-z-2=0.', 1.00, 'Vận dụng', 15),
(2, 'true_false', 'Một lớp học có 60% học sinh tham gia CLB Thể thao và 40% không tham gia. Tỉ lệ đạt giải cấp trường trong nhóm tham gia CLB là 25%, trong nhóm không tham gia là 10%. Chọn ngẫu nhiên một học sinh.', 'a) Xác suất chọn được học sinh tham gia CLB Thể thao là 0.6.', 'b) Xác suất học sinh đạt giải, biết rằng học sinh đó không tham gia CLB, là 0.1.', 'c) Xác suất học sinh được chọn đạt giải cấp trường là 0.19.', 'd) Biết rằng học sinh được chọn đạt giải cấp trường, xác suất học sinh đó tham gia CLB Thể thao bằng 15/19.', 'D,D,D,D', 'a) Đúng.\nb) Đúng.\nc) Đúng: P(G) = 0.6×0.25 + 0.4×0.10 = 0.19.\nd) Đúng: Theo Bayes, P(CLB | G) = (0.6×0.25) / 0.19 = 0.15 / 0.19 = 15/19.', 1.00, 'Vận dụng cao', 16),

-- Phần III: Trắc nghiệm Trả lời ngắn (17 - 22)
(2, 'short_answer', 'Biết F(x) là một nguyên hàm của hàm số f(x) = 3x² - 2x thỏa mãn F(1) = 3. Tính giá trị của F(2).', NULL, NULL, NULL, NULL, '7', 'F(x) = x³ - x² + C. F(1) = C = 3 ⇒ F(2) = 8 - 4 + 3 = 7.', 0.50, 'Thông hiểu', 17),
(2, 'short_answer', 'Cho mẫu số liệu ghép nhóm về quãng đường chạy bộ (km/tuần) của 40 người: [0;10): 10, [10;20): 10, [20;30): 10, [30;40): 10. Tính khoảng tứ phân vị Δ_Q của mẫu số liệu ghép nhóm trên.', NULL, NULL, NULL, NULL, '20', 'Q₁ = 10, Q₃ = 30 ⇒ Δ_Q = 30 - 10 = 20.', 0.50, 'Thông hiểu', 18),
(2, 'short_answer', 'Cho hình chóp S.ABC có SA ⊥ (ABC), đáy ABC là tam giác vuông cân tại B, AB = BC = 6, SA = 6. Tính khoảng cách từ điểm A đến mặt phẳng (SBC) (làm tròn đến hàng phần trăm).', NULL, NULL, NULL, NULL, '4.24', 'BC ⊥ (SAB). Kẻ AH ⊥ SB ⇒ AH ⊥ (SBC). AH = (6×6)/√(36+36) = 3√2 ≈ 4.24.', 0.50, 'Vận dụng', 19),
(2, 'short_answer', 'Một nhà sản xuất bán x chiếc xe đạp điện mỗi tháng với giá p(x) = 20 - 0.05x (triệu đồng) và tổng chi phí C(x) = 8x + 120 (triệu đồng). Hỏi lợi nhuận lớn nhất trong một tháng đạt bao nhiêu triệu đồng?', NULL, NULL, NULL, NULL, '600', 'L(x) = -0.05x² + 12x - 120 đạt cực đại tại x = 120 ⇒ L_max = 600 triệu đồng.', 0.50, 'Vận dụng', 20),
(2, 'short_answer', 'Trong không gian Oxyz, cho điểm M(2; 1; -1) và mặt phẳng (P): 2x - y + 2z + 5 = 0. Tính khoảng cách từ M đến mặt phẳng (P).', NULL, NULL, NULL, NULL, '2', 'd(M, (P)) = |2(2) - 1 + 2(-1) + 5| / √(4 + 1 + 4) = |6| / 3 = 2.', 0.50, 'Vận dụng', 21),
(2, 'short_answer', 'Tính thể tích khối tròn xoay tạo thành khi quay hình phẳng giới hạn bởi các đường y = √(2x), y = 0, x = 0, x = 3 quanh trục Ox (lấy π ≈ 3.14, làm tròn kết quả đến hàng phần trăm).', NULL, NULL, NULL, NULL, '28.26', 'V = π∫(0→3) 2x dx = π[x²](0→3) = 9π ≈ 9 × 3.14 = 28.26.', 0.50, 'Vận dụng cao', 22);


-- ==========================================================
-- MÔN TIẾNG ANH - ĐỀ SỐ 01 (exam_id = 3): 40 CÂU - 50 PHÚT - 0.25đ/CÂU
-- ==========================================================
INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
-- Nhận biết (1 - 16)
(3, 'mcq', '[Advertisement: SmartStudy App] "SmartStudy is an _______ learning platform designed for Grade 12 students."', 'innovative', 'innovation', 'innovate', 'innovatively', 'A', 'Tính từ "innovative" bổ nghĩa cho danh từ "learning platform".', 0.25, 'Nhận biết', 1),
(3, 'mcq', '[Advertisement: SmartStudy App] "Students can focus _______ their weakest topics before the national exam."', 'on', 'at', 'with', 'for', 'A', 'Cụm từ cố định: "focus on" = tập trung vào.', 0.25, 'Nhận biết', 2),
(3, 'mcq', '[Advertisement: SmartStudy App] "Download the app today to _______ full advantage of our free 30-day trial!"', 'take', 'make', 'do', 'give', 'A', 'Collocation: "take advantage of" = tận dụng.', 0.25, 'Nhận biết', 3),
(3, 'mcq', '[Advertisement: SmartStudy App] "Don''t hesitate _______ our support team if you need technical assistance."', 'to contact', 'contacting', 'contact', 'contacted', 'A', 'Cấu trúc: "hesitate + to V".', 0.25, 'Nhận biết', 4),
(3, 'mcq', '[Leaflet: Green Campus Week] "Remember to bring your reusable bottle _______ single-use plastic cups."', 'instead of', 'in case of', 'on account of', 'with a view to', 'A', '"instead of" = thay vì.', 0.25, 'Nhận biết', 5),
(3, 'mcq', '[Leaflet: Green Campus Week] "A large _______ of volunteers is needed to plant 200 trees around the school."', 'number', 'amount', 'deal', 'quantity', 'A', '"A large number of + N(đếm được số nhiều)".', 0.25, 'Nhận biết', 6),
(3, 'mcq', '[Leaflet: Green Campus Week] "Small daily actions can _______ a big difference to our local environment."', 'make', 'do', 'create', 'take', 'A', 'Collocation cố định: "make a difference".', 0.25, 'Nhận biết', 7),
(3, 'mcq', 'Arrange the dialogue:
a. Mai: I''m preparing for the university entrance exam, so I''m a bit stressed.
b. Nam: Hi Mai! You look tired today. What''s wrong?
c. Nam: Don''t worry too much. Make a clear study schedule and take short breaks!', 'b - a - c', 'a - b - c', 'b - c - a', 'c - a - b', 'A', 'Mở đầu hỏi thăm (b) → trả lời (a) → khuyên nhủ (c).', 0.25, 'Nhận biết', 8),
(3, 'mcq', 'Choose the word whose underlined part differs in pronunciation: [ea]sy, t[ea]cher, h[ea]lthy, sp[ea]k', 'healthy', 'easy', 'teacher', 'speak', 'A', '"healthy" đọc là /e/, các từ còn lại đọc là /iː/.', 0.25, 'Nhận biết', 9),
(3, 'mcq', 'Choose the word whose underlined part differs in pronunciation: book[s], lamp[s], bag[s], hat[s]', 'bags', 'books', 'lamps', 'hats', 'A', '"bags" kết thúc bằng âm hữu thanh /ɡ/ nên -s đọc là /z/, các từ còn lại đọc /s/.', 0.25, 'Nhận biết', 10),
(3, 'mcq', 'Choose the word that differs in primary stress: nation, beauty, student, agree', 'agree', 'nation', 'beauty', 'student', 'A', '"agree" nhấn âm 2, các từ còn lại nhấn âm 1.', 0.25, 'Nhận biết', 11),
(3, 'mcq', 'She _______ her grandparents in the countryside every summer.', 'visits', 'is visiting', 'visited', 'has visited', 'A', 'Thói quen lặp lại ("every summer") chia thì hiện tại đơn.', 0.25, 'Nhận biết', 12),
(3, 'mcq', 'The novel _______ by a famous Vietnamese author in 2020.', 'was written', 'wrote', 'is writing', 'has written', 'A', 'Câu bị động ở thì quá khứ đơn ("in 2020").', 0.25, 'Nhận biết', 13),
(3, 'mcq', 'Lan: "Congratulations on winning the first prize!" - Hoa: "_______"', 'Thank you so much!', 'You''re welcome.', 'I''m sorry to hear that.', 'Never mind.', 'A', 'Đáp lại lời chúc mừng dùng "Thank you so much!".', 0.25, 'Nhận biết', 14),
(3, 'mcq', 'My brother is very fond _______ playing chess with my grandfather.', 'of', 'at', 'on', 'with', 'A', 'Cấu trúc: "be fond of + V-ing" (thích làm gì).', 0.25, 'Nhận biết', 15),
(3, 'mcq', 'That is the university _______ my sister studied architecture.', 'where', 'which', 'who', 'whom', 'A', 'Trạng từ quan hệ "where" thay thế cho danh từ chỉ nơi chốn.', 0.25, 'Nhận biết', 16),

-- Thông hiểu (17 - 28)
(3, 'mcq', '[Advertisement: SmartStudy App] "It offers _______ to help you master every subject faster."', 'interactive video lessons', 'lessons interactive video', 'video interactive lessons', 'interactive lessons video', 'A', 'Trật tự cụm danh từ chuẩn: tính từ + danh từ ghép.', 0.25, 'Thông hiểu', 17),
(3, 'mcq', '[Advertisement: SmartStudy App] "All mock tests, _______ by experienced teachers, strictly follow the national format."', 'designed', 'designing', 'which designed', 'to design', 'A', 'Rút gọn mệnh đề quan hệ bị động dùng quá khứ phân từ "designed".', 0.25, 'Thông hiểu', 18),
(3, 'mcq', '[Leaflet: Green Campus Week] "Plastic waste ends up in landfills, threatening _______ wildlife."', 'other', 'another', 'the others', 'others', 'A', '"other + danh từ không đếm được/số nhiều".', 0.25, 'Thông hiểu', 19),
(3, 'mcq', '[Leaflet: Green Campus Week] "Students are encouraged to _______ old notebooks at the school recycling booth."', 'drop off', 'take over', 'put out', 'break down', 'A', '"drop off" = mang tới gửi/để lại.', 0.25, 'Thông hiểu', 20),
(3, 'mcq', '[Leaflet: Green Campus Week] "We will also organize workshops on waste sorting and energy _______."', 'conservation', 'conversation', 'construction', 'consumption', 'A', '"energy conservation" = bảo tồn/tiết kiệm năng lượng.', 0.25, 'Thông hiểu', 21),
(3, 'mcq', 'Arrange the dialogue:
a. Lan: What time does it start?
b. Minh: Are you free this Saturday morning? Our club is hosting a book fair.
c. Lan: Yes, I am. Sounds interesting!
d. Minh: It starts at 8 a.m. in the library yard.
e. Lan: Count me in!', 'b - c - a - d - e', 'b - a - c - d - e', 'c - b - a - e - d', 'b - c - d - a - e', 'A', 'Trình tự tự nhiên: mời (b) → đáp (c) → hỏi giờ (a) → trả lời giờ (d) → đồng ý (e).', 0.25, 'Thông hiểu', 22),
(3, 'mcq', 'Arrange the letter:
a. Let me know if you can come so I can book the tickets early.
b. I''m writing to invite you to a science exhibition next Sunday.
c. It features amazing robotics demonstrations from university students.
d. Looking forward to hearing from you soon.', 'b - c - a - d', 'c - b - a - d', 'b - a - c - d', 'a - b - c - d', 'A', 'Mục đích thư (b) → chi tiết sự kiện (c) → lời nhắn (a) → kết thư (d).', 0.25, 'Thông hiểu', 23),
(3, 'mcq', '[Context Cloze: AI in Education] "One major application is the AI tutor, _______."', 'which can adapt lessons to each student''s learning pace', 'that adapting lessons to each student''s pace', 'whom helps students learn at their own pace', 'whose lessons adapted automatically', 'A', 'Mệnh đề quan hệ không xác định sau dấu phẩy dùng "which".', 0.25, 'Thông hiểu', 24),
(3, 'mcq', '[Context Cloze: AI in Education] "_______, an AI system can immediately detect whether a student misunderstood a formula."', 'By analyzing thousands of practice responses in seconds', 'Analyze thousands of practice responses in seconds', 'Having analyzed by thousands of responses', 'Although analyzing thousands of practice responses', 'A', 'Cụm chỉ phương tiện "By + V-ing".', 0.25, 'Thông hiểu', 25),
(3, 'mcq', '[Passage 1: Ocean Protection] "Oceans cover over 70% of Earth''s surface and produce at least 50% of the planet''s oxygen. Yet, rising sea temperatures and overfishing threaten marine ecosystems." How much oxygen do oceans produce?', 'At least half of Earth''s oxygen', 'Exactly 70% of Earth''s oxygen', 'Less than 20% of Earth''s oxygen', 'Nearly 100% of all oxygen', 'A', 'Bài nêu rõ: "produce at least 50% of the planet''s oxygen".', 0.25, 'Thông hiểu', 26),
(3, 'mcq', '[Passage 1] The word "threaten" in Passage 1 is CLOSEST in meaning to:', 'endanger', 'protect', 'expand', 'celebrate', 'A', '"threaten" = "endanger" (đe dọa, gây nguy hiểm).', 0.25, 'Thông hiểu', 27),
(3, 'mcq', '[Passage 1] "Community-led coral restoration and strict fishing quotas have helped fish populations recover." The word "recover" is OPPOSITE in meaning to:', 'decline', 'improve', 'heal', 'survive', 'A', '"recover" (phục hồi) trái nghĩa với "decline" (suy giảm).', 0.25, 'Thông hiểu', 28),

-- Vận dụng (29 - 36)
(3, 'mcq', 'Arrange the paragraph:
a. Furthermore, teaching a concept to a friend helps spot gaps in your understanding.
b. Active recall is widely considered more effective than simply re-reading notes.
c. By retrieving information without looking at the page, you strengthen memory pathways.
d. Therefore, students should combine practice quizzes with peer discussions.', 'b - c - a - d', 'c - b - a - d', 'b - a - c - d', 'a - b - c - d', 'A', 'Câu chủ đề (b) → cơ chế (c) → bổ sung (a) → kết luận (d).', 0.25, 'Vận dụng', 29),
(3, 'mcq', 'Arrange the paragraph:
a. As a result, residents in greener neighborhoods report lower stress levels.
b. Rapid urbanization has reduced the number of parks in many modern cities.
c. Urban parks cool down temperatures and provide safe places for outdoor exercise.
d. Recognizing these benefits, planners now prioritize rooftop gardens.', 'b - c - a - d', 'c - b - d - a', 'b - a - c - d', 'd - b - c - a', 'A', 'Thực trạng (b) → lợi ích (c) → kết quả (a) → giải pháp (d).', 0.25, 'Vận dụng', 30),
(3, 'mcq', '[Context Cloze: AI in Education] "Educators emphasize that empathy and moral guidance _______."', 'remain skills that only human mentors can genuinely offer', 'remains skills only offered by human mentors', 'is remaining a skill for human mentors', 'remaining as unique teacher abilities', 'A', 'Chủ ngữ số nhiều "empathy and moral guidance" đi với "remain".', 0.25, 'Vận dụng', 31),
(3, 'mcq', '[Context Cloze: AI in Education] "In addition, _______ if students rely too heavily on AI to write essays."', 'critical thinking abilities might gradually decline', 'critical thinking abilities had declined', 'the decline of thinking was unavoidable', 'critically thinking ability will declined', 'A', 'Câu điều kiện loại 1 diễn tả hệ quả có thể xảy ra: "might gradually decline".', 0.25, 'Vận dụng', 32),
(3, 'mcq', '[Passage 1] What is the main idea of Passage 1 (Ocean Protection)?', 'Promoting the sustainable blue economy to protect vital ocean ecosystems', 'Describing how deep-sea submarines work', 'Banning all coastal tourism permanently', 'Comparing forest oxygen with desert air', 'A', 'Toàn bài nói về bảo vệ đại dương qua mô hình kinh tế biển bền vững.', 0.25, 'Vận dụng', 33),
(3, 'mcq', '[Passage 2: Remote Work] "High-speed internet and cloud tools have reshaped workplaces. However, without clear boundaries, employees may experience burnout. Forward-thinking firms set ''no-email'' evening hours." What drawback is mentioned?', 'Difficulty separating work hours from personal time', 'Lack of internet access in city centers', 'Higher daily commuting expenses', 'Too many in-person meetings every morning', 'A', 'Bài nêu việc thiếu ranh giới giữa công việc và cuộc sống gây kiệt sức.', 0.25, 'Vận dụng', 34),
(3, 'mcq', '[Passage 2] How do progressive companies address remote-work challenges?', 'By restricting evening emails and organizing in-person retreats', 'By forcing staff to work 12 hours daily', 'By banning cloud collaboration tools', 'By closing all physical offices permanently', 'A', 'Thông tin: "setting ''no-email'' evening hours and scheduling regular in-person team retreats".', 0.25, 'Vận dụng', 35),
(3, 'mcq', '[Passage 2] The word "burnout" refers to:', 'physical or mental exhaustion caused by overwork', 'a sudden promotion at a technology company', 'high-speed fiber optic internet installation', 'an annual outdoor team-building celebration', 'A', '"burnout" = sự kiệt sức vì làm việc quá tải.', 0.25, 'Vận dụng', 36),

-- Vận dụng cao (37 - 40)
(3, 'mcq', '[Passage 2] "(I) Workers split their week between home and shared offices. (II) Suburban cafes have boomed. (III) However, junior staff miss spontaneous mentoring." Where does "This shift has significantly reduced downtown traffic." best fit?', 'Between (I) and (II)', 'Before (I)', 'After (III)', 'After (II)', 'A', 'Câu nói về kết quả giảm ùn tắc trung tâm nối liền sau (I) và trước (II).', 0.25, 'Vận dụng cao', 37),
(3, 'mcq', '[Passage 2] Which sentence best paraphrases: "Without clear boundaries between work and personal life, employees may experience burnout."?', 'Failing to separate professional duties from private time can lead to worker exhaustion.', 'Commuting to crowded offices is the only cause of worker burnout.', 'Personal life prevents employees from learning cloud tools.', 'Clear boundaries guarantee workers never need vacations.', 'A', 'Diễn đạt lại chính xác nghĩa gốc câu trong bài đọc.', 0.25, 'Vận dụng cao', 38),
(3, 'mcq', 'Not until the final bell rang _______ leaving the examination room.', 'did the candidates start', 'the candidates started', 'started the candidates', 'had the candidates start', 'A', 'Đảo ngữ "Not until + mệnh đề, trợ động từ + S + V_inf".', 0.25, 'Vận dụng cao', 39),
(3, 'mcq', 'It is essential that every applicant _______ the online form before the deadline.', 'submit', 'submits', 'submitted', 'is submitting', 'A', 'Thức giả định: "It is essential that + S + V(nguyên mẫu không to)".', 0.25, 'Vận dụng cao', 40);

-- ==========================================================
-- MÔN TIẾNG ANH - ĐỀ SỐ 02 (exam_id = 4): 40 CÂU - 50 PHÚT - 0.25đ/CÂU
-- ==========================================================
INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
-- Nhận biết (1 - 16)
(4, 'mcq', 'Pronunciation (underlined vowel): l[a]ke, g[a]me, m[a]de, f[a]ct', 'fact', 'lake', 'game', 'made', 'A', '"fact" phát âm /æ/, các từ còn lại phát âm /eɪ/.', 0.25, 'Nhận biết', 1),
(4, 'mcq', 'Pronunciation (-ed ending): want[ed], need[ed], visit[ed], lik[ed]', 'liked', 'wanted', 'needed', 'visited', 'A', '"liked" có âm cuối /k/ nên -ed đọc là /t/, các từ còn lại đọc /ɪd/.', 0.25, 'Nhận biết', 2),
(4, 'mcq', 'Primary stress: hospital, library, computer, family', 'computer', 'hospital', 'library', 'family', 'A', '"computer" nhấn âm 2, các từ còn lại nhấn âm 1.', 0.25, 'Nhận biết', 3),
(4, 'mcq', 'Primary stress: arrive, open, enjoy, begin', 'open', 'arrive', 'enjoy', 'begin', 'A', '"open" nhấn âm 1, các động từ 2 âm tiết còn lại nhấn âm 2.', 0.25, 'Nhận biết', 4),
(4, 'mcq', 'Look! The children _______ football happily in the schoolyard.', 'are playing', 'play', 'played', 'have played', 'A', 'Có "Look!" chỉ hành động đang diễn ra tại thời điểm nói ⇒ hiện tại tiếp diễn.', 0.25, 'Nhận biết', 5),
(4, 'mcq', 'He has lived in Hanoi _______ more than ten years.', 'for', 'since', 'ago', 'during', 'A', '"for + khoảng thời gian" (more than ten years).', 0.25, 'Nhận biết', 6),
(4, 'mcq', 'Your sister can speak Japanese fluently, _______?', 'can''t she', 'can she', 'doesn''t she', 'isn''t she', 'A', 'Câu hỏi đuôi với động từ khuyết thiếu "can" khẳng định ⇒ "can''t she".', 0.25, 'Nhận biết', 7),
(4, 'mcq', 'This bridge _______ in 2015 to connect the two districts.', 'was built', 'built', 'is built', 'has built', 'A', 'Câu bị động quá khứ đơn ("in 2015").', 0.25, 'Nhận biết', 8),
(4, 'mcq', 'She asked me _______ I liked watching science fiction movies.', 'if', 'that', 'what', 'which', 'A', 'Câu tường thuật dạng Yes/No question dùng "if" hoặc "whether".', 0.25, 'Nhận biết', 9),
(4, 'mcq', 'Tom decided _______ a part-time job to gain practical experience.', 'to take', 'taking', 'take', 'taken', 'A', 'Cấu trúc: "decide + to V".', 0.25, 'Nhận biết', 10),
(4, 'mcq', 'Nam: "How about going for a bike ride this afternoon?" - Ba: "_______"', 'That''s a great idea!', 'No, I don''t.', 'Yes, I do.', 'Never mind.', 'A', 'Đáp lại lời gợi ý "How about...?" bằng "That''s a great idea!".', 0.25, 'Nhận biết', 11),
(4, 'mcq', 'I need to buy _______ new dictionary for my English class.', 'a', 'an', 'the', 'no article', 'A', '"new dictionary" đếm được số ít, nhắc lần đầu và bắt đầu bằng phụ âm ⇒ dùng "a".', 0.25, 'Nhận biết', 12),
(4, 'mcq', 'Mount Everest is the _______ mountain in the world.', 'highest', 'higher', 'high', 'most high', 'A', 'So sánh nhất với tính từ ngắn "high" ⇒ "the highest".', 0.25, 'Nhận biết', 13),
(4, 'mcq', 'We couldn''t go camping _______ the terrible storm.', 'because of', 'because', 'although', 'despite', 'A', '"because of + cụm danh từ" chỉ nguyên nhân.', 0.25, 'Nhận biết', 14),
(4, 'mcq', 'You should _______ up the meaning of new words in a dictionary.', 'look', 'take', 'get', 'make', 'A', 'Phrasal verb: "look up" = tra cứu (từ điển, thông tin).', 0.25, 'Nhận biết', 15),
(4, 'mcq', 'She plays the piano very _______ and won many awards.', 'well', 'good', 'better', 'best', 'A', 'Trạng từ "well" bổ nghĩa cho động từ thường "plays".', 0.25, 'Nhận biết', 16),

-- Thông hiểu (17 - 28)
(4, 'mcq', 'CLOSEST in meaning: Parents should ENCOURAGE their children to read books every day.', 'motivate', 'prevent', 'criticize', 'ignore', 'A', '"encourage" (khuyến khích) đồng nghĩa với "motivate" (tạo động lực).', 0.25, 'Thông hiểu', 17),
(4, 'mcq', 'CLOSEST in meaning: The museum displays ANCIENT artifacts from the Bronze Age.', 'very old', 'modern', 'common', 'expensive', 'A', '"ancient" (cổ đại) = "very old".', 0.25, 'Thông hiểu', 18),
(4, 'mcq', 'OPPOSITE in meaning: It is GENEROUS of him to donate half of his prize money.', 'selfish', 'kind', 'helpful', 'wealthy', 'A', '"generous" (hào phóng) trái nghĩa với "selfish" (ích kỷ).', 0.25, 'Thông hiểu', 19),
(4, 'mcq', 'OPPOSITE in meaning: The instructions were so VAGUE that nobody knew what to do.', 'clear', 'unclear', 'short', 'confusing', 'A', '"vague" (mơ hồ) trái nghĩa với "clear" (rõ ràng).', 0.25, 'Thông hiểu', 20),
(4, 'mcq', 'Find the mistake: The number of students [attending] the workshop [have] increased [dramatically] [this year].', 'have', 'attending', 'dramatically', 'this year', 'A', 'Chủ ngữ "The number of + N(số nhiều)" luôn đi với động từ số ít ⇒ "have" sửa thành "has".', 0.25, 'Thông hiểu', 21),
(4, 'mcq', 'Find the mistake: My sister [is] [interested] in [collect] postcards from [different] countries.', 'collect', 'is', 'interested', 'different', 'A', 'Sau giới từ "in" dùng V-ing ⇒ "collect" sửa thành "collecting".', 0.25, 'Thông hiểu', 22),
(4, 'mcq', 'If she _______ earlier, she wouldn''t have missed the train.', 'had left', 'left', 'leaves', 'would leave', 'A', 'Câu điều kiện loại 3: If + S + had + V3/ed, S + would have + V3/ed.', 0.25, 'Thông hiểu', 23),
(4, 'mcq', 'The more books you read, _______ knowledge you will gain.', 'the more', 'more', 'the most', 'most', 'A', 'So sánh kép với danh từ: "The more + N + S + V, the more + N + S + V".', 0.25, 'Thông hiểu', 24),
(4, 'mcq', '_______ in 1998, the library serves thousands of students every month.', 'Built', 'Building', 'To build', 'Having built', 'A', 'Rút gọn mệnh đề trạng ngữ bị động dùng quá khứ phân từ "Built".', 0.25, 'Thông hiểu', 25),
(4, 'mcq', 'By the time we arrived at the cinema, the movie _______ for fifteen minutes.', 'had started', 'started', 'has started', 'starts', 'A', 'Hành động xảy ra trước một mốc quá khứ dùng thì quá khứ hoàn thành "had started".', 0.25, 'Thông hiểu', 26),
(4, 'mcq', 'When I was a child, my grandfather _______ tell me folk tales before bedtime.', 'used to', 'was used to', 'is used to', 'got used to', 'A', '"used to + V_inf" diễn tả thói quen trong quá khứ nay không còn.', 0.25, 'Thông hiểu', 27),
(4, 'mcq', 'Many volunteers helped clean _______ the beach after the music festival.', 'up', 'out', 'off', 'away', 'A', 'Phrasal verb: "clean up" = dọn dẹp sạch sẽ.', 0.25, 'Thông hiểu', 28),

-- Vận dụng (29 - 36)
(4, 'mcq', 'Rewrite: "Don''t forget to lock the front door," Mom said to me.', 'Mom reminded me to lock the front door.', 'Mom forbade me to lock the front door.', 'Mom apologized for locking the front door.', 'Mom denied locking the front door.', 'A', '"Don''t forget to V" tường thuật bằng "S + reminded + O + to V".', 0.25, 'Vận dụng', 29),
(4, 'mcq', 'Rewrite: She started learning French five years ago.', 'She has been learning French for five years.', 'She hasn''t learned French for five years.', 'She stopped learning French five years ago.', 'It was five years when she learned French.', 'A', 'Chuyển từ quá khứ đơn ("started ... ago") sang hiện tại hoàn thành ("has been learning ... for").', 0.25, 'Vận dụng', 30),
(4, 'mcq', 'Rewrite: Perhaps he missed the morning bus.', 'He might have missed the morning bus.', 'He mustn''t have missed the morning bus.', 'He shouldn''t have missed the morning bus.', 'He can''t have missed the morning bus.', 'A', 'Dự đoán có khả năng xảy ra trong quá khứ ("Perhaps") dùng "might have + V3/ed".', 0.25, 'Vận dụng', 31),
(4, 'mcq', 'Reading: "Urban farming—growing vegetables on rooftops and balconies—reduces food transport emissions and cools city buildings. Though space is limited, vertical racks allow families to harvest fresh greens year-round." What is an advantage of urban farming?', 'It lowers emissions from transporting food and cools buildings.', 'It requires thousands of hectares of rural farmland.', 'It prevents families from eating fresh vegetables.', 'It increases city air conditioning energy bills.', 'A', 'Bài nêu rõ: "reduces food transport emissions and cools city buildings".', 0.25, 'Vận dụng', 32),
(4, 'mcq', 'Based on the Urban Farming text, how do city residents overcome limited space?', 'By using vertical racks on rooftops and balconies', 'By moving all factories into rural forests', 'By stopping vegetable consumption in winter', 'By building underground parking garages', 'A', 'Thông tin: "vertical racks allow families to harvest fresh greens year-round".', 0.25, 'Vận dụng', 33),
(4, 'mcq', 'Combine: He speaks English very fluently. However, he has never lived abroad.', 'Although he has never lived abroad, he speaks English very fluently.', 'Because he has never lived abroad, he speaks English fluently.', 'Despite he has never lived abroad, he speaks fluently.', 'Unless he lived abroad, he would speak fluently.', 'A', 'Hai mệnh đề tương phản nối bằng liên từ "Although".', 0.25, 'Vận dụng', 34),
(4, 'mcq', 'The manager decided to _______ the meeting until next Monday due to bad weather.', 'put off', 'take after', 'get over', 'bring up', 'A', '"put off" = trì hoãn.', 0.25, 'Vận dụng', 35),
(4, 'mcq', 'Making a detailed study plan is the best way to _______ your exam anxiety.', 'alleviate', 'aggravate', 'multiply', 'trigger', 'A', '"alleviate anxiety" = làm dịu/giảm bớt sự lo âu.', 0.25, 'Vận dụng', 36),

-- Vận dụng cao (37 - 40)
(4, 'mcq', 'Had it not been for the lifeguard''s quick reaction, the child _______ drowned.', 'would have', 'will have', 'had', 'would', 'A', 'Đảo ngữ câu điều kiện loại 3: "Had it not been for + N, S + would have + V3/ed".', 0.25, 'Vận dụng cao', 37),
(4, 'mcq', 'Every student is expected to _______ their weight when working on the group science project.', 'pull', 'push', 'lift', 'carry', 'A', 'Thành ngữ (Idiom): "pull one''s weight" = làm tròn phần việc/trách nhiệm của mình trong nhóm.', 0.25, 'Vận dụng cao', 38),
(4, 'mcq', 'Hardly _______ at the airport when the boarding announcement was made.', 'had we arrived', 'we had arrived', 'did we arrive', 'have we arrived', 'A', 'Đảo ngữ với "Hardly + had + S + V3/ed + when + S + V2/ed".', 0.25, 'Vận dụng cao', 39),
(4, 'mcq', 'The new policy aims to bridge the _______ between urban and rural digital education.', 'gap', 'wall', 'road', 'line', 'A', 'Collocation chuẩn: "bridge the gap" = thu hẹp khoảng cách.', 0.25, 'Vận dụng cao', 40);



-- ==========================================================
-- MÔN VẬT LÝ - ĐỀ SỐ 01 (exam_id = 5): 28 CÂU - 50 PHÚT - TỔNG 10.00 ĐIỂM
-- Phần I: 18 câu mcq (0.25đ = 4.50đ) | Phần II: 4 câu true_false (1.00đ = 4.00đ) | Phần III: 6 câu short_answer (0.25đ = 1.50đ)
-- ==========================================================
INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
-- Phần I: Chọn đáp án (1 - 18)
(5, 'mcq', 'Quá trình chuyển từ thể lỏng sang thể rắn của một chất được gọi là:', 'Sự đông đặc', 'Sự nóng chảy', 'Sự bay hơi', 'Sự ngưng tụ', 'A', 'Chuyển từ thể lỏng sang thể rắn là sự đông đặc.', 0.25, 'Nhận biết', 1),
(5, 'mcq', 'Theo định luật I của nhiệt động lực học ΔU = A + Q, nếu hệ nhận nhiệt lượng Q > 0 và thực hiện công A < 0 thì độ biến thiên nội năng của hệ là:', 'ΔU = Q - |A|', 'ΔU = Q + |A|', 'ΔU = |A| - Q', 'ΔU = 0', 'A', 'Hệ thực hiện công nên A < 0, do đó ΔU = Q + A = Q - |A|.', 0.25, 'Nhận biết', 2),
(5, 'mcq', 'Đơn vị đo nhiệt độ nhiệt động lực học trong hệ SI là:', 'Kelvin (K)', 'Độ Celsius (°C)', 'Độ Fahrenheit (°F)', 'Joule (J)', 'A', 'Đơn vị nhiệt độ tuyệt đối trong hệ SI là Kelvin (K).', 0.25, 'Nhận biết', 3),
(5, 'mcq', 'Trong quá trình đẳng nhiệt của một lượng khí lí tưởng xác định (định luật Boyle), áp suất p và thể tích V liên hệ với nhau theo hệ thức:', 'pV = hằng số', 'p/V = hằng số', 'pV² = hằng số', 'V/p = hằng số', 'A', 'Định luật Boyle: ở nhiệt độ không đổi, pV = hằng số.', 0.25, 'Nhận biết', 4),
(5, 'mcq', 'Động năng tịnh tiến trung bình của phân tử khí lí tưởng tỉ lệ thuận với đại lượng nào sau đây?', 'Nhiệt độ tuyệt đối T', 'Thể tích bình chứa V', 'Khối lượng riêng của khí', 'Diện tích thành bình', 'A', 'W_đ = (3/2)kT, tỉ lệ thuận trực tiếp với nhiệt độ tuyệt đối T.', 0.25, 'Nhận biết', 5),
(5, 'mcq', 'Một vật dao động điều hòa với phương trình x = 4cos(5πt + π/6) (cm). Tần số góc của dao động là:', '5π rad/s', '4 rad/s', 'π/6 rad/s', '10π rad/s', 'A', 'So sánh với x = Acos(ωt + φ) ta có ω = 5π rad/s.', 0.25, 'Nhận biết', 6),
(5, 'mcq', 'Sóng nào sau đây là sóng ngang và truyền được trong chân không?', 'Sóng điện từ', 'Sóng âm trong không khí', 'Sóng dọc trên lò xo', 'Sóng siêu âm trong nước', 'A', 'Sóng điện từ là sóng ngang và truyền được qua chân không với tốc độ c = 3.10⁸ m/s.', 0.25, 'Nhận biết', 7),
(5, 'mcq', 'Từ thông Φ gửi qua một khung dây phẳng diện tích S đặt trong từ trường đều B được tính bởi công thức (α là góc hợp bởi vectơ pháp tuyến n và B):', 'Φ = B.S.cos(α)', 'Φ = B.S.sin(α)', 'Φ = B.S.tan(α)', 'Φ = B / (S.cos(α))', 'A', 'Công thức từ thông: Φ = B.S.cos(α).', 0.25, 'Nhận biết', 8),
(5, 'mcq', 'Lực từ tác dụng lên một đoạn dây dẫn thẳng dài l mang dòng điện I đặt vuông góc với đường sức từ của từ trường đều B có độ lớn là:', 'F = B.I.l', 'F = B.I / l', 'F = B.l / I', 'F = 0', 'A', 'F = B.I.l.sin(90°) = B.I.l.', 0.25, 'Nhận biết', 9),
(5, 'mcq', 'Suất điện động cảm ứng xuất hiện trong một mạch kín có độ lớn tỉ lệ thuận với:', 'Tốc độ biến thiên từ thông qua mạch', 'Từ thông cực đại qua mạch', 'Điện trở của mạch kín', 'Diện tích vòng dây', 'A', 'Định luật Faraday: |e_c| = |ΔΦ / Δt|.', 0.25, 'Nhận biết', 10),
(5, 'mcq', 'Dòng điện xoay chiều chạy qua một đoạn mạch có biểu thức i = 4cos(100πt) (A). Cường độ dòng điện hiệu dụng là:', '2√2 A', '4 A', '4√2 A', '2 A', 'A', 'I = I₀ / √2 = 4 / √2 = 2√2 A.', 0.25, 'Thông hiểu', 11),
(5, 'mcq', 'Hạt nhân nguyên tử ¹⁴₆C có số nơtron bằng:', '8', '6', '14', '20', 'A', 'Số nơtron N = A - Z = 14 - 6 = 8.', 0.25, 'Nhận biết', 12),
(5, 'mcq', 'Tia phóng xạ nào sau đây có khả năng đâm xuyên mạnh nhất và không bị lệch trong điện trường, từ trường?', 'Tia gamma (γ)', 'Tia anpha (α)', 'Tia beta cộng (β⁺)', 'Tia beta trừ (β⁻)', 'A', 'Tia γ là sóng điện từ không mang điện, bước sóng cực ngắn nên đâm xuyên mạnh nhất.', 0.25, 'Nhận biết', 13),
(5, 'mcq', 'Trong quá trình đẳng áp của một lượng khí lí tưởng, khi nhiệt độ tuyệt đối tăng lên 2 lần thì thể tích của khối khí sẽ:', 'Tăng lên 2 lần', 'Giảm đi 2 lần', 'Tăng lên 4 lần', 'Không thay đổi', 'A', 'Định luật Charles: V / T = hằng số ⇒ T tăng 2 lần thì V tăng 2 lần.', 0.25, 'Thông hiểu', 14),
(5, 'mcq', 'Đun nóng 2 kg nước (nhiệt dung riêng c = 4200 J/kg.K) từ 20°C lên 70°C. Nhiệt lượng nước đã thu vào là:', '420 kJ', '42 kJ', '588 kJ', '168 kJ', 'A', 'Q = m.c.Δt = 2 × 4200 × (70 - 20) = 420 000 J = 420 kJ.', 0.25, 'Thông hiểu', 15),
(5, 'mcq', 'Một đoạn dây dẫn dài 0.5 m mang dòng điện 4 A đặt vuông góc với cảm ứng từ B = 0.2 T. Độ lớn lực từ tác dụng lên đoạn dây là:', '0.4 N', '4.0 N', '0.1 N', '2.5 N', 'A', 'F = B.I.l.sin(90°) = 0.2 × 4 × 0.5 = 0.4 N.', 0.25, 'Thông hiểu', 16),
(5, 'mcq', 'Trong thí nghiệm giao thoa ánh sáng Y-âng với a = 1 mm, D = 1.5 m, λ = 0.5 μm. Khoảng vân i trên màn là:', '0.75 mm', '1.50 mm', '0.50 mm', '3.00 mm', 'A', 'i = λD / a = (0.5 × 1.5) / 1 = 0.75 mm.', 0.25, 'Thông hiểu', 17),
(5, 'mcq', 'Năng lượng liên kết của hạt nhân ⁴₂He là 28.4 MeV. Năng lượng liên kết riêng của hạt nhân này bằng:', '7.1 MeV/nuclôn', '28.4 MeV/nuclôn', '14.2 MeV/nuclôn', '56.8 MeV/nuclôn', 'A', 'E_lkr = W_lk / A = 28.4 / 4 = 7.1 MeV/nuclôn.', 0.25, 'Thông hiểu', 18),

-- Phần II: Đúng / Sai 4 ý (19 - 22)
(5, 'true_false', 'Một học sinh làm nóng chảy hoàn toàn 0.5 kg nước đá ở 0°C thành nước lỏng ở 20°C. Biết nhiệt nóng chảy riêng của nước đá là λ = 3.34×10⁵ J/kg và nhiệt dung riêng của nước là c = 4200 J/(kg.K).', 'a) Trong suốt quá trình nước đá đang nóng chảy ở 0°C, nhiệt độ của hệ không thay đổi.', 'b) Nhiệt lượng cần để làm nóng chảy hoàn toàn 0.5 kg nước đá ở 0°C là 167 kJ.', 'c) Nhiệt lượng cần cung cấp để đun nước từ 0°C lên 20°C là 42 kJ.', 'd) Tổng nhiệt lượng cần cung cấp cho toàn bộ quá trình trên là 250 kJ.', 'D,D,D,S', 'a) Đúng.\nb) Đúng: Q₁ = mλ = 0.5 × 334 000 = 167 kJ.\nc) Đúng: Q₂ = mcΔt = 0.5 × 4200 × 20 = 42 kJ.\nd) Sai: Tổng Q = 167 + 42 = 209 kJ.', 1.00, 'Thông hiểu', 19),
(5, 'true_false', 'Một lượng khí lí tưởng xác định chứa trong xi-lanh kín có pít-tông di chuyển được. Ban đầu khí có áp suất p₁ = 1.0×10⁵ Pa, thể tích V₁ = 4 lít và nhiệt độ T₁ = 300 K. Người ta nén đẳng nhiệt khí xuống còn V₂ = 2 lít.', 'a) Quá trình biến đổi trạng thái trên là quá trình đẳng nhiệt nên T₂ = 300 K.', 'b) Sau khi nén, áp suất của khối khí trong xi-lanh là 2.0×10⁵ Pa.', 'c) Trong quá trình nén đẳng nhiệt, nội năng của khí lí tưởng tăng lên gấp đôi.', 'd) Mật độ phân tử khí trong xi-lanh tăng lên gấp đôi sau khi nén.', 'D,D,S,D', 'a) Đúng.\nb) Đúng: p₂ = p₁V₁/V₂ = 2.0×10⁵ Pa.\nc) Sai: Nội năng khí lí tưởng chỉ phụ thuộc T; T không đổi nên ΔU = 0.\nd) Đúng: Thể tích giảm một nửa nên mật độ phân tử n = N/V tăng 2 lần.', 1.00, 'Vận dụng', 20),
(5, 'true_false', 'Một khung dây dẫn phẳng hình vuông cạnh a = 10 cm gồm N = 100 vòng dây đặt cố định trong từ trường đều có cảm ứng từ B vuông góc với mặt phẳng khung. Trong thời gian Δt = 0.2 s, cảm ứng từ giảm đều từ 0.5 T về 0.1 T.', 'a) Diện tích mỗi vòng dây của khung là S = 0.01 m².', 'b) Độ biến thiên từ thông qua toàn bộ khung dây có độ lớn |ΔΦ| = 0.4 Wb.', 'c) Độ lớn suất điện động cảm ứng xuất hiện trong khung dây là 2.0 V.', 'd) Nếu giữ nguyên tốc độ biến thiên của B nhưng tăng số vòng dây lên 200 vòng thì suất điện động cảm ứng giảm đi một nửa.', 'D,D,D,S', 'a) Đúng: S = 0.1² = 0.01 m².\nb) Đúng: |ΔΦ| = 100 × 0.01 × |0.1 - 0.5| = 0.4 Wb.\nc) Đúng: |e_c| = 0.4 / 0.2 = 2.0 V.\nd) Sai: e_c tỉ lệ thuận với N nên tăng N lên 2 lần thì e_c tăng lên 2 lần.', 1.00, 'Vận dụng', 21),
(5, 'true_false', 'Đồng vị phóng xạ ¹³¹₅₃I có chu kì bán rã T = 8 ngày, phát ra tia β⁻ và biến thành hạt nhân Xenon (¹³¹₅₄Xe). Ban đầu có một mẫu chứa 16 mg ¹³¹₅₃I nguyên chất.', 'a) Số khối của hạt nhân con Xenon tạo thành là 131.', 'b) Hằng số phóng xạ của ¹³¹₅₃I là λ = ln(2) / 8 (ngày⁻¹).', 'c) Sau 24 ngày kể từ thời điểm ban đầu, khối lượng ¹³¹₅₃I còn lại là 2 mg.', 'd) Sau 16 ngày, khối lượng ¹³¹₅₃I đã bị phân rã là 4 mg.', 'D,D,D,S', 'a) Đúng.\nb) Đúng.\nc) Đúng: 24 ngày = 3T ⇒ m = 16 / 2³ = 2 mg.\nd) Sai: Sau 16 ngày = 2T, lượng còn lại là 4 mg nên lượng đã phân rã là 16 - 4 = 12 mg.', 1.00, 'Vận dụng cao', 22),

-- Phần III: Trả lời ngắn (23 - 28)
(5, 'short_answer', 'Một khối khí nhận nhiệt lượng Q = 800 J và nhận công A = 300 J từ bên ngoài. Tính độ biến thiên nội năng ΔU (theo đơn vị J) của khối khí đó.', NULL, NULL, NULL, NULL, '1100', 'ΔU = A + Q = 300 + 800 = 1100 J.', 0.25, 'Nhận biết', 23),
(5, 'short_answer', 'Một bình kín chứa 2 mol khí lí tưởng ở nhiệt độ 27°C (300 K) và thể tích 8.31 lít. Lấy R = 8.31 J/(mol.K). Tính áp suất của khí trong bình theo đơn vị kPa.', NULL, NULL, NULL, NULL, '600', 'p = nRT / V = (2 × 8.31 × 300) / (8.31 × 10⁻³) = 600 000 Pa = 600 kPa.', 0.25, 'Thông hiểu', 24),
(5, 'short_answer', 'Một sóng cơ truyền dọc theo trục Ox với tần số f = 25 Hz và tốc độ truyền sóng v = 10 m/s. Tính bước sóng λ theo đơn vị cm.', NULL, NULL, NULL, NULL, '40', 'λ = v / f = 10 / 25 = 0.4 m = 40 cm.', 0.25, 'Thông hiểu', 25),
(5, 'short_answer', 'Một máy biến áp lí tưởng nối với điện áp hiệu dụng U₁ = 220 V ở cuộn sơ cấp có tỉ số vòng dây N₂/N₁ = 5. Tính điện áp hiệu dụng ở cuộn thứ cấp theo đơn vị V.', NULL, NULL, NULL, NULL, '1100', 'U₂ = U₁ × (N₂/N₁) = 220 × 5 = 1100 V.', 0.25, 'Vận dụng', 26),
(5, 'short_answer', 'Một hạt nhân ²³⁵₉₂U phân hạch tỏa ra năng lượng 200 MeV. Lấy 1 eV = 1.6×10⁻¹⁹ J. Tính năng lượng tỏa ra khi 10²⁰ hạt nhân U-235 phân hạch hoàn toàn theo đơn vị MJ.', NULL, NULL, NULL, NULL, '3200', 'E = 10²⁰ × 200×10⁶ × 1.6×10⁻¹⁹ = 3.2×10⁹ J = 3200 MJ.', 0.25, 'Vận dụng', 27),
(5, 'short_answer', 'Trong thí nghiệm giao thoa Y-âng, a = 1 mm, D = 2 m, nguồn phát đồng thời hai bức xạ λ₁ = 0.48 μm và λ₂ = 0.64 μm. Tính khoảng cách ngắn nhất (theo đơn vị mm) giữa hai vân sáng cùng màu với vân sáng trung tâm.', NULL, NULL, NULL, NULL, '3.84', 'k₁/k₂ = 0.64/0.48 = 4/3 ⇒ x = 4.i₁ = 4 × (0.48×2/1) = 3.84 mm.', 0.25, 'Vận dụng cao', 28);

-- ==========================================================
-- MÔN VẬT LÝ - ĐỀ SỐ 02 (exam_id = 6): 28 CÂU - 50 PHÚT - TỔNG 10.00 ĐIỂM
-- Phần I: 18 câu mcq (0.25đ = 4.50đ) | Phần II: 4 câu true_false (1.00đ = 4.00đ) | Phần III: 6 câu short_answer (0.25đ = 1.50đ)
-- ==========================================================
INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
-- Phần I: Chọn đáp án (1 - 18)
(6, 'mcq', 'Nội năng của một vật phụ thuộc vào đại lượng nào sau đây?', 'Nhiệt độ và thể tích của vật', 'Vận tốc chuyển động của cả vật', 'Độ cao của vật so với mặt đất', 'Màu sắc bề mặt vật', 'A', 'Nội năng gồm động năng phân tử (nhiệt độ) và thế năng tương tác phân tử (thể tích).', 0.25, 'Nhận biết', 1),
(6, 'mcq', 'Mối liên hệ giữa nhiệt độ theo thang Kelvin (T) và nhiệt độ theo thang Celsius (t) là:', 'T (K) = t (°C) + 273', 'T (K) = t (°C) - 273', 'T (K) = 273 - t (°C)', 'T (K) = 1.8 t (°C) + 32', 'A', 'Quy đổi thang nhiệt độ: T (K) = t (°C) + 273.', 0.25, 'Nhận biết', 2),
(6, 'mcq', 'Hiện tượng cộng hưởng cơ xảy ra khi tần số của ngoại lực cưỡng bức:', 'Bằng tần số riêng của hệ dao động', 'Nhỏ hơn một nửa tần số riêng', 'Bằng 0', 'Lớn gấp đôi tần số riêng', 'A', 'Cộng hưởng cơ xảy ra khi f_cưỡng bức = f_riêng.', 0.25, 'Nhận biết', 3),
(6, 'mcq', 'Khoảng cách giữa hai nút sóng liên tiếp trên một sợi dây đang có sóng dừng bằng:', 'λ / 2', 'λ', 'λ / 4', '2λ', 'A', 'Hai nút liên tiếp trên dây có sóng dừng cách nhau λ/2.', 0.25, 'Nhận biết', 4),
(6, 'mcq', 'Trong mạch điện xoay chiều chỉ có điện trở thuần R, cường độ dòng điện tức thời i và điện áp u:', 'Cùng pha với nhau', 'Vuông pha với nhau', 'Ngược pha với nhau', 'Lệch pha π/3', 'A', 'Mạch chỉ có R thì φ = 0 ⇒ u và i cùng pha.', 0.25, 'Nhận biết', 5),
(6, 'mcq', 'Công thức tính công suất tiêu thụ trung bình của đoạn mạch điện xoay chiều là:', 'P = U.I.cosφ', 'P = U.I.sinφ', 'P = U₀.I₀.cosφ', 'P = U / I', 'A', 'Công suất tiêu thụ P = U.I.cosφ.', 0.25, 'Nhận biết', 6),
(6, 'mcq', 'Trong thang sóng điện từ, bức xạ nào có bước sóng nhỏ hơn bước sóng ánh sáng tím và dùng để chụp X-quang y tế?', 'Tia X', 'Tia hồng ngoại', 'Sóng vô tuyến', 'Ánh sáng đỏ', 'A', 'Tia X có bước sóng rất ngắn (10⁻¹¹ m đến 10⁻⁸ m), khả năng đâm xuyên mạnh.', 0.25, 'Nhận biết', 7),
(6, 'mcq', 'Trong thí nghiệm Y-âng về giao thoa ánh sáng đơn sắc, vân tối xuất hiện tại các vị trí có hiệu đường đi d₂ - d₁ bằng:', '(k + 0.5)λ (k ∈ ℤ)', 'kλ (k ∈ ℤ)', '2kλ', 'kλ / 4', 'A', 'Điều kiện vân tối: d₂ - d₁ = (k + 0.5)λ.', 0.25, 'Nhận biết', 8),
(6, 'mcq', 'Hạt nhân nào sau đây có độ bền vững lớn nhất (năng lượng liên kết riêng lớn nhất khoảng 8.8 MeV/nuclôn)?', '⁵⁶₂₆Fe (Sắt)', '⁴₂He (Heli)', '²³⁵₉₂U (Urani)', '²₁H (Đơteri)', 'A', 'Các hạt nhân trung bình (tiêu biểu là ⁵⁶₂₆Fe) có năng lượng liên kết riêng lớn nhất.', 0.25, 'Nhận biết', 9),
(6, 'mcq', 'Theo hệ thức Anh-xtanh, một vật có khối lượng m thì có năng lượng nghỉ E₀ bằng:', 'E₀ = m.c²', 'E₀ = m.c', 'E₀ = (1/2)m.c²', 'E₀ = m / c²', 'A', 'Hệ thức Anh-xtanh: E = m.c².', 0.25, 'Nhận biết', 10),
(6, 'mcq', 'Một lượng khí lí tưởng thực hiện quá trình đẳng áp. Ban đầu khí có thể tích 6 lít ở nhiệt độ 300 K. Khi tăng nhiệt độ lên 450 K thì thể tích của khối khí là:', '9 lít', '4 lít', '12 lít', '7.5 lít', 'A', 'V₁/T₁ = V₂/T₂ ⇒ V₂ = 6 × (450 / 300) = 9 lít.', 0.25, 'Thông hiểu', 11),
(6, 'mcq', 'Một đoạn dây dẫn thẳng dài 0.5 m mang dòng điện 6 A đặt vuông góc với từ trường đều B = 0.25 T. Lực từ tác dụng lên đoạn dây có độ lớn là:', '0.75 N', '1.50 N', '0.30 N', '3.00 N', 'A', 'F = B.I.l.sin(90°) = 0.25 × 6 × 0.5 = 0.75 N.', 0.25, 'Thông hiểu', 12),
(6, 'mcq', 'Một vật dao động điều hòa với phương trình x = 10cos(4πt + π/3) (cm). Tại t = 0, vật đang ở vị trí:', 'x = 5 cm và đi theo chiều âm', 'x = 5 cm và đi theo chiều dương', 'x = -5 cm và đi theo chiều âm', 'x = 5√3 cm và đi theo chiều dương', 'A', 'Tại t = 0: x = 10cos(π/3) = 5 cm; pha φ = π/3 > 0 ⇒ v < 0 (chiều âm).', 0.25, 'Thông hiểu', 13),
(6, 'mcq', 'Một sóng cơ truyền với tần số 50 Hz, tốc độ truyền sóng 10 m/s. Hai điểm gần nhau nhất trên phương truyền sóng dao động ngược pha cách nhau:', '10 cm', '20 cm', '5 cm', '40 cm', 'A', 'λ = v/f = 0.2 m = 20 cm ⇒ hai điểm ngược pha gần nhất cách nhau λ/2 = 10 cm.', 0.25, 'Thông hiểu', 14),
(6, 'mcq', 'Đặt điện áp u = 220√2cos(100πt) (V) vào mạch điện thì dòng điện là i = 2√2cos(100πt - π/3) (A). Công suất tiêu thụ của mạch là:', '220 W', '440 W', '880 W', '110 W', 'A', 'P = U.I.cosφ = 220 × 2 × cos(π/3) = 220 W.', 0.25, 'Thông hiểu', 15),
(6, 'mcq', 'Sóng điện từ tần số f = 15 MHz truyền trong chân không với tốc độ c = 3×10⁸ m/s có bước sóng là:', '20 m', '45 m', '2 m', '200 m', 'A', 'λ = c / f = (3×10⁸) / (15×10⁶) = 20 m.', 0.25, 'Thông hiểu', 16),
(6, 'mcq', 'Trong thí nghiệm Y-âng, a = 0.5 mm, D = 1.5 m, λ = 0.6 μm. Khoảng cách từ vân sáng bậc 2 đến vân sáng bậc 5 cùng một phía vân trung tâm là:', '5.4 mm', '9.0 mm', '1.8 mm', '3.6 mm', 'A', 'i = (0.6×1.5)/0.5 = 1.8 mm ⇒ khoảng cách = 3i = 5.4 mm.', 0.25, 'Thông hiểu', 17),
(6, 'mcq', 'Cho phản ứng phân hạch: ¹₀n + ²³⁵₉₂U → ⁹⁵₃₉Y + ¹³⁸₅₃I + x.¹₀n. Giá trị của x là:', '3', '2', '1', '4', 'A', 'Bảo toàn số khối A: 1 + 235 = 95 + 138 + x ⇒ x = 3.', 0.25, 'Thông hiểu', 18),

-- Phần II: Đúng / Sai 4 ý (19 - 22)
(6, 'true_false', 'Một bình kín thể tích không đổi V = 16.62 lít chứa 2 mol khí lí tưởng ở nhiệt độ 27°C (300 K). Lấy hằng số khí lí tưởng R = 8.31 J/(mol.K).', 'a) Nhiệt độ tuyệt đối ban đầu của khối khí là T₁ = 300 K.', 'b) Áp suất ban đầu của khí trong bình là 3.0×10⁵ Pa.', 'c) Nếu đun nóng đẳng tích khối khí lên đến nhiệt độ 327°C thì áp suất khí trong bình tăng lên gấp đôi.', 'd) Ở nhiệt độ 327°C, động năng tịnh tiến trung bình của mỗi phân tử khí giảm đi một nửa so với lúc đầu.', 'D,D,D,S', 'a) Đúng.\nb) Đúng: p₁ = (2 × 8.31 × 300) / (16.62 × 10⁻³) = 300 000 Pa = 3.0×10⁵ Pa.\nc) Đúng: T₂ = 327 + 273 = 600 K = 2.T₁ ⇒ p₂ = 2.p₁.\nd) Sai: Động năng trung bình tỉ lệ thuận với T nên tăng gấp đôi.', 1.00, 'Vận dụng', 19),
(6, 'true_false', 'Một sợi dây đàn hồi AB dài 1.2 m có hai đầu A, B cố định đang có sóng dừng ổn định với 4 bụng sóng. Biết tốc độ truyền sóng trên dây là 30 m/s.', 'a) Trên dây có tất cả 5 nút sóng (kể cả hai đầu A, B).', 'b) Bước sóng của sóng truyền trên dây là 0.6 m.', 'c) Tần số dao động của dây là 50 Hz.', 'd) Khoảng thời gian giữa hai lần liên tiếp sợi dây duỗi thẳng là 0.02 s.', 'D,D,D,S', 'a) Đúng: 4 bụng ⇒ 4 + 1 = 5 nút.\nb) Đúng: 1.2 = 4(λ/2) ⇒ λ = 0.6 m.\nc) Đúng: f = v/λ = 30 / 0.6 = 50 Hz.\nd) Sai: Hai lần dây duỗi thẳng liên tiếp cách nhau T/2 = 1/(2×50) = 0.01 s.', 1.00, 'Vận dụng', 20),
(6, 'true_false', 'Một đoạn dây dẫn thẳng dài l = 0.5 m mang dòng điện không đổi I = 8 A đặt trong từ trường đều có cảm ứng từ B = 0.4 T sao cho dây hợp với vectơ cảm ứng từ một góc θ = 30°.', 'a) Lực từ tác dụng lên đoạn dây có phương vuông góc với cả dòng điện và đường sức từ.', 'b) Độ lớn lực từ tác dụng lên đoạn dây là 0.8 N.', 'c) Nếu xoay đoạn dây để nó nằm song song với các đường sức từ thì lực từ đạt giá trị cực đại.', 'd) Nếu giữ nguyên góc θ = 30° nhưng tăng cường độ dòng điện lên 16 A thì lực từ tăng lên 1.6 N.', 'D,D,S,D', 'a) Đúng.\nb) Đúng: F = 0.4 × 8 × 0.5 × sin(30°) = 0.8 N.\nc) Sai: Khi song song (θ = 0°) thì sin(0°) = 0 ⇒ F = 0.\nd) Đúng: F tỉ lệ thuận với I.', 1.00, 'Vận dụng', 21),
(6, 'true_false', 'Chất phóng xạ ¹⁴₆C có chu kì bán rã T = 5730 năm. Một mẫu gỗ cổ đại có độ phóng xạ đo được chỉ bằng 25% độ phóng xạ của một mẫu gỗ tươi mới chặt có cùng khối lượng.', 'a) Hạt nhân ¹⁴₆C có 6 prôtôn và 8 nơtron.', 'b) Tuổi của mẫu gỗ cổ đại nói trên là 11460 năm.', 'c) Sau thêm 5730 năm nữa kể từ hiện tại, độ phóng xạ của mẫu gỗ cổ sẽ giảm xuống còn 12.5% so với mẫu gỗ tươi.', 'd) Chu kì bán rã của ¹⁴₆C phụ thuộc vào nhiệt độ và áp suất của môi trường xung quanh.', 'D,D,D,S', 'a) Đúng.\nb) Đúng: H/H₀ = 0.25 = 2⁻² ⇒ t = 2T = 11460 năm.\nc) Đúng: thêm 1T nữa ⇒ H/H₀ = 2⁻³ = 12.5%.\nd) Sai: Chu kì bán rã là hằng số đặc trưng của hạt nhân, không phụ thuộc điều kiện bên ngoài.', 1.00, 'Vận dụng cao', 22),

-- Phần III: Trả lời ngắn (23 - 28)
(6, 'short_answer', 'Nhiệt nóng chảy riêng của nước đá là λ = 3.34×10⁵ J/kg. Tính nhiệt lượng (theo đơn vị kJ) cần cung cấp để làm nóng chảy hoàn toàn 200 g nước đá ở 0°C.', NULL, NULL, NULL, NULL, '66.8', 'Q = m.λ = 0.2 × 334 000 = 66 800 J = 66.8 kJ.', 0.25, 'Nhận biết', 23),
(6, 'short_answer', 'Một khung dây phẳng gồm 200 vòng dây có diện tích mỗi vòng S = 25 cm² đặt vuông góc với từ trường đều. Trong 0.1 s, cảm ứng từ tăng đều từ 0.2 T lên 0.6 T. Tính độ lớn suất điện động cảm ứng trong khung theo đơn vị V.', NULL, NULL, NULL, NULL, '2', '|e_c| = 200 × 25×10⁻⁴ × (0.6 - 0.2) / 0.1 = 2.0 V.', 0.25, 'Thông hiểu', 24),
(6, 'short_answer', 'Một vật dao động điều hòa có phương trình x = 6cos(2πt) (cm). Tính tốc độ cực đại của vật theo đơn vị cm/s (lấy π ≈ 3.14, làm tròn đến hàng phần trăm).', NULL, NULL, NULL, NULL, '37.68', 'v_max = ωA = 2π × 6 = 12π ≈ 12 × 3.14 = 37.68 cm/s.', 0.25, 'Thông hiểu', 25),
(6, 'short_answer', 'Một máy biến áp lí tưởng truyền điện đi xa với điện áp hiệu dụng U₁ = 10 kV thì hiệu suất truyền tải đạt 91%. Để hiệu suất tăng lên 99% (công suất phát và điện trở dây không đổi), cần tăng điện áp nơi phát lên bao nhiêu kV?', NULL, NULL, NULL, NULL, '30', 'Hao phí giảm 9 lần (9% → 1%) nên U tăng √9 = 3 lần ⇒ U₂ = 30 kV.', 0.25, 'Vận dụng', 26),
(6, 'short_answer', 'Một chất điểm dao động điều hòa với chu kì T = 1.2 s. Thời gian ngắn nhất vật đi từ vị trí có li độ x = A/2 đến vị trí cân bằng x = 0 là bao nhiêu giây?', NULL, NULL, NULL, NULL, '0.1', 'Khoảng thời gian đi từ A/2 đến 0 là T/12 = 1.2 / 12 = 0.1 s.', 0.25, 'Vận dụng', 27),
(6, 'short_answer', 'Trong thí nghiệm Y-âng, hai khe cách nhau a = 1 mm, màn D = 2 m, chiếu ánh sáng trắng có bước sóng từ 0.38 μm đến 0.76 μm. Tại vị trí M trên màn cách vân trung tâm 3.6 mm có bao nhiêu bức xạ đơn sắc cho vân sáng?', NULL, NULL, NULL, NULL, '2', 'λ = a.x_M / (k.D) = 1.8 / k (μm). Với 0.38 ≤ 1.8/k ≤ 0.76 ⇔ 2.37 ≤ k ≤ 4.74 ⇒ k ∈ {3; 4} (2 bức xạ).', 0.25, 'Vận dụng cao', 28);


-- ==========================================================
-- MÔN HÓA HỌC - ĐỀ SỐ 01 (exam_id = 7): 28 CÂU - 50 PHÚT - TỔNG 10.00 ĐIỂM
-- Phần I: 18 câu mcq (0.25đ = 4.50đ) | Phần II: 4 câu true_false (1.00đ = 4.00đ) | Phần III: 6 câu short_answer (0.25đ = 1.50đ)
-- ==========================================================
INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
-- Phần I: Chọn đáp án (1 - 18)
(7, 'mcq', 'Công thức cấu tạo thu gọn của metyl fomat là:', 'HCOOCH₃', 'CH₃COOCH₃', 'HCOOC₂H₅', 'CH₃COOH', 'A', 'Metyl fomat tạo bởi axit fomic (HCOOH) và ancol metylic (CH₃OH) ⇒ HCOOCH₃.', 0.25, 'Nhận biết', 1),
(7, 'mcq', 'Chất nào sau đây là thành phần chính tạo nên độ ngọt trong mật ong?', 'Fructozơ', 'Saccarozơ', 'Tinh bột', 'Xenlulozơ', 'A', 'Fructozơ chiếm khoảng 40% trong mật ong (đường mật ong).', 0.25, 'Nhận biết', 2),
(7, 'mcq', 'Thủy phân hoàn toàn chất béo (triglixerit) trong môi trường kiềm luôn thu được muối của axit béo và:', 'Glixerol (C₃H₅(OH)₃)', 'Etylen glicol', 'Ancol etylic', 'Phenol', 'A', 'Chất béo là trieste của glixerol và axit béo.', 0.25, 'Nhận biết', 3),
(7, 'mcq', 'Tên gọi thay thế theo danh pháp IUPAC của CH₃-NH-CH₃ là:', 'N-metylmetanamin', 'Etanamin', 'Metanamin', 'Phenylamin', 'A', 'CH₃-NH-CH₃ là amin bậc II: N-metylmetanamin (đimetylamin).', 0.25, 'Nhận biết', 4),
(7, 'mcq', 'Trong phân tử amino axit Alanin (CH₃-CH(NH₂)-COOH), số nguyên tử cacbon là:', '3', '2', '4', '5', 'A', 'Alanin có CTPT C₃H₇NO₂ (3 nguyên tử C).', 0.25, 'Nhận biết', 5),
(7, 'mcq', 'Polime nào sau đây được dùng làm chất dẻo phổ biến từ phản ứng trùng hợp vinyl clorua?', 'Poli(vinyl clorua) (PVC)', 'Tinh bột', 'Xenlulozơ', 'Tơ tằm', 'A', 'Trùng hợp CH₂=CHCl thu được PVC.', 0.25, 'Nhận biết', 6),
(7, 'mcq', 'Trong pin điện hóa Zn-Cu chuẩn, ở cực âm (anôt) xảy ra quá trình:', 'Sự oxi hóa kim loại Zn: Zn → Zn²⁺ + 2e', 'Sự khử ion Zn²⁺: Zn²⁺ + 2e → Zn', 'Sự oxi hóa kim loại Cu: Cu → Cu²⁺ + 2e', 'Sự khử ion Cu²⁺: Cu²⁺ + 2e → Cu', 'A', 'Zn có tính khử mạnh hơn Cu nên đóng vai trò anôt (cực âm), xảy ra sự oxi hóa Zn.', 0.25, 'Nhận biết', 7),
(7, 'mcq', 'Kim loại nào sau đây có tính dẫn điện tốt nhất trong tất cả các kim loại?', 'Bạc (Ag)', 'Đồng (Cu)', 'Vàng (Au)', 'Nhôm (Al)', 'A', 'Thứ tự dẫn điện: Ag > Cu > Au > Al > Fe.', 0.25, 'Nhận biết', 8),
(7, 'mcq', 'Kim loại nào sau đây có nhiệt độ nóng chảy cao nhất, thường dùng làm dây tóc bóng đèn?', 'Vonfam (W)', 'Sắt (Fe)', 'Thủy ngân (Hg)', 'Nhôm (Al)', 'A', 'Vonfam (W) nóng chảy ở 3410°C, cao nhất trong các kim loại.', 0.25, 'Nhận biết', 9),
(7, 'mcq', 'Hợp chất nào sau đây của canxi được dùng để đúc tượng, bó bột khi gãy xương (thạch cao nung)?', 'CaSO₄.H₂O', 'CaCO₃', 'Ca(OH)₂', 'CaCl₂', 'A', 'Thạch cao nung có công thức CaSO₄.H₂O (hoặc CaSO₄.0,5H₂O).', 0.25, 'Nhận biết', 10),
(7, 'mcq', 'Số oxi hóa của nguyên tố sắt (Fe) trong hợp chất Fe₂(SO₄)₃ là:', '+3', '+2', '0', '+6', 'A', 'Gốc SO₄²⁻ hóa trị II nên Fe có số oxi hóa +3.', 0.25, 'Nhận biết', 11),
(7, 'mcq', 'Trong dung dịch phức chất [Cu(NH₃)₄(H₂O)₂]²⁺, nguyên tử/ion trung tâm là:', 'Cu²⁺', 'NH₃', 'H₂O', 'OH⁻', 'A', 'Ion kim loại chuyển tiếp Cu²⁺ là nguyên tử trung tâm tạo phức với phối tử NH₃ và H₂O.', 0.25, 'Thông hiểu', 12),
(7, 'mcq', 'Cho các dung dịch riêng biệt: glucozơ, saccarozơ, lòng trắng trứng (albumin). Thuốc thử duy nhất để phân biệt cả 3 dung dịch trên là:', 'Cu(OH)₂/OH⁻ đun nhẹ', 'Dung dịch HCl', 'Dung dịch NaCl', 'Quỳ tím', 'A', 'Ở nhiệt độ thường: albumin cho màu tím (biure), glucozơ & saccarozơ cho dung dịch xanh lam. Đun nóng: glucozơ tạo kết tủa đỏ gạch Cu₂O, saccarozơ không phản ứng.', 0.25, 'Thông hiểu', 13),
(7, 'mcq', 'Thủy phân hoàn toàn 7.4 gam metyl axetat (CH₃COOCH₃, M = 74) bằng dung dịch NaOH dư thu được khối lượng ancol metylic (M = 32) là:', '3.2 gam', '4.6 gam', '6.4 gam', '1.6 gam', 'A', 'n_este = 0.1 mol ⇒ n_CH₃OH = 0.1 mol ⇒ m = 0.1 × 32 = 3.2 gam.', 0.25, 'Thông hiểu', 14),
(7, 'mcq', 'Cho thế điện cực chuẩn E°(Zn²⁺/Zn) = -0.76 V và E°(Cu²⁺/Cu) = +0.34 V. Sức điện động chuẩn của pin Galvani Zn-Cu bằng:', '1.10 V', '0.42 V', '-1.10 V', '0.76 V', 'A', 'E°_pin = E°_catôt - E°_anôt = 0.34 - (-0.76) = 1.10 V.', 0.25, 'Thông hiểu', 15),
(7, 'mcq', 'Ngâm một lá kẽm (Zn) trong dung dịch H₂SO₄ loãng thấy khí thoát ra chậm. Nhỏ thêm vài giọt dung dịch CuSO₄ vào thấy khí thoát ra nhanh hơn hẳn là do:', 'Xuất hiện cặp pin điện hóa Zn-Cu gây ra ăn mòn điện hóa', 'CuSO₄ làm tăng nồng độ axit H₂SO₄', 'Cu đẩy Zn ra khỏi dung dịch axit', 'H₂SO₄ bị phân hủy nhanh hơn', 'A', 'Zn đẩy Cu bám lên Zn tạo thành vô số pin điện hóa Zn-Cu, tốc độ ăn mòn tăng mạnh.', 0.25, 'Thông hiểu', 16),
(7, 'mcq', 'Để làm mềm nước có tính cứng toàn phần, hóa chất hiệu quả nhất là:', 'Dung dịch Na₂CO₃ (hoặc Na₃PO₄)', 'Đun sôi nước', 'Dung dịch HCl', 'Dung dịch NaCl', 'A', 'Ion CO₃²⁻ kết tủa hoàn toàn cả Ca²⁺ và Mg²⁺ trong nước cứng toàn phần.', 0.25, 'Thông hiểu', 17),
(7, 'mcq', 'Cho 5.6 gam Fe (M = 56) tác dụng với lượng dư dung dịch AgNO₃. Sau phản ứng hoàn toàn, khối lượng Ag (M = 108) thu được tối đa là:', '32.4 gam', '21.6 gam', '10.8 gam', '16.2 gam', 'A', 'n_Fe = 0.1 mol. Do AgNO₃ dư nên Fe lên Fe³⁺ ⇒ n_Ag = 3.n_Fe = 0.3 mol ⇒ m = 0.3 × 108 = 32.4 gam.', 0.25, 'Thông hiểu', 18),

-- Phần II: Đúng / Sai 4 ý (19 - 22)
(7, 'true_false', 'Tiến hành thí nghiệm phản ứng xà phòng hóa chất béo: Cho vào bát sứ khoảng 2 gam mỡ lợn và 4 ml dung dịch NaOH 40%, đun sôi nhẹ và khuấy liên tục trong 10 phút, thêm từng giọt nước cất để giữ thể tích không đổi. Sau đó rót thêm 10 ml dung dịch NaCl bão hòa vào, khuấy nhẹ rồi để nguội.', 'a) Phản ứng xảy ra khi đun nóng mỡ lợn với dung dịch NaOH là phản ứng thuận nghịch.', 'b) Việc thêm nước cất trong quá trình đun nhằm tránh hỗn hợp bị cạn khô để phản ứng xảy ra hoàn toàn.', 'c) Sau khi thêm dung dịch NaCl bão hòa và để nguội, lớp chất rắn màu trắng nổi lên trên là muối natri của axit béo.', 'd) Dung dịch NaCl bão hòa làm giảm độ tan của xà phòng và tăng tỉ trọng lớp dung dịch phía dưới để tách xà phòng dễ dàng.', 'S,D,D,D', 'a) Sai: Xà phòng hóa trong kiềm là phản ứng một chiều.\nb) Đúng.\nc) Đúng.\nd) Đúng.', 1.00, 'Thông hiểu', 19),
(7, 'true_false', 'Xét dung dịch của các amino axit: Glyxin (H₂N-CH₂-COOH), Axit glutamic (HOOC-CH₂-CH₂-CH(NH₂)-COOH) và Lysin (H₂N-[CH₂]₄-CH(NH₂)-COOH).', 'a) Ở nhiệt độ thường, các amino axit này đều là chất rắn kết tinh, tan tốt trong nước.', 'b) Dung dịch Axit glutamic làm quỳ tím chuyển sang màu đỏ (hồng).', 'c) Dung dịch Lysin không làm đổi màu giấy quỳ tím.', 'd) Cả ba chất trên đều có tính lưỡng tính, tác dụng được với cả dung dịch HCl và dung dịch NaOH.', 'D,D,S,D', 'a) Đúng.\nb) Đúng: có 2 nhóm -COOH và 1 nhóm -NH₂.\nc) Sai: Lysin có 2 nhóm -NH₂ và 1 nhóm -COOH nên làm quỳ tím hóa xanh.\nd) Đúng.', 1.00, 'Thông hiểu', 20),
(7, 'true_false', 'Thực hiện điện phân 200 ml dung dịch CuSO₄ 1M với điện cực trơ bằng dòng điện có cường độ I = 5 A trong thời gian t = 3860 giây (biết hằng số Faraday F = 96500 C/mol).', 'a) Số mol electron trao đổi tại mỗi điện cực là 0.2 mol.', 'b) Tại catôt xảy ra quá trình khử ion Cu²⁺: Cu²⁺ + 2e → Cu.', 'c) Sau 3860 giây, khối lượng kim loại Cu (M = 64) bám trên catôt là 12.8 gam.', 'd) Tại anôt thu được 0.05 mol khí O₂.', 'D,D,S,D', 'a) Đúng: n_e = (5 × 3860) / 96500 = 0.2 mol.\nb) Đúng.\nc) Sai: n_Cu = 0.2 / 2 = 0.1 mol ⇒ m_Cu = 6.4 gam.\nd) Đúng: n_O₂ = n_e / 4 = 0.05 mol.', 1.00, 'Vận dụng', 21),
(7, 'true_false', 'Trong công nghiệp luyện gang, người ta khử 1 tấn quặng hematit chứa 80% khối lượng Fe₂O₃ (tạp chất trơ không chứa sắt) bằng khí CO theo phản ứng: Fe₂O₃ + 3CO → 2Fe + 3CO₂.', 'a) Phản ứng khử oxit sắt bằng khí CO thuộc phương pháp nhiệt luyện.', 'b) Trong phản ứng trên, khí CO đóng vai trò là chất oxi hóa.', 'c) Khối lượng Fe₂O₃ nguyên chất có trong 1 tấn (1000 kg) quặng là 800 kg.', 'd) Với hiệu suất toàn bộ quá trình đạt 90%, khối lượng sắt (Fe = 56, O = 16) thu được là 504 kg.', 'D,S,D,D', 'a) Đúng.\nb) Sai: CO là chất khử.\nc) Đúng: 1000 × 80% = 800 kg.\nd) Đúng: n_Fe₂O₃ = 5 kmol ⇒ m_Fe = 2 × 5 × 56 × 90% = 504 kg.', 1.00, 'Vận dụng cao', 22),

-- Phần III: Trả lời ngắn (23 - 28)
(7, 'short_answer', 'Số nguyên tử hiđro (H) có trong một phân tử axit oleic (C₁₇H₃₃COOH) là bao nhiêu?', NULL, NULL, NULL, NULL, '34', 'C₁₇H₃₃COOH = C₁₈H₃₄O₂ ⇒ có 34 nguyên tử H.', 0.25, 'Nhận biết', 23),
(7, 'short_answer', 'Cho dãy các chất: etyl axetat, glucozơ, saccarozơ, tinh bột, triolein. Có bao nhiêu chất trong dãy tham gia phản ứng thủy phân trong môi trường axit?', NULL, NULL, NULL, NULL, '4', 'Gồm etyl axetat, saccarozơ, tinh bột, triolein (4 chất).', 0.25, 'Thông hiểu', 24),
(7, 'short_answer', 'Thủy phân hoàn toàn 12 gam metyl fomat (HCOOCH₃, M = 60) trong dung dịch NaOH dư. Tính khối lượng muối natri fomat (HCOONa, M = 68) thu được theo đơn vị gam.', NULL, NULL, NULL, NULL, '13.6', 'n_este = 12/60 = 0.2 mol ⇒ m_muối = 0.2 × 68 = 13.6 gam.', 0.25, 'Thông hiểu', 25),
(7, 'short_answer', 'Lên men 45 gam glucozơ (M = 180) thành ancol etylic (M = 46) với hiệu suất 80%. Tính khối lượng ancol etylic thu được theo đơn vị gam.', NULL, NULL, NULL, NULL, '18.4', 'n_glu = 0.25 mol ⇒ n_ancol = 2 × 0.25 × 0.8 = 0.4 mol ⇒ m = 0.4 × 46 = 18.4 gam.', 0.25, 'Vận dụng', 26),
(7, 'short_answer', 'Cho 10.8 gam kim loại Al (M = 27) tác dụng hoàn toàn với dung dịch HNO₃ loãng dư thu được V lít khí N₂O (sản phẩm khử duy nhất, ở ĐKC 24.79 lít/mol). Tính giá trị của V (làm tròn đến hàng phần trăm).', NULL, NULL, NULL, NULL, '3.72', 'n_Al = 0.4 mol ⇒ 8.n_N₂O = 3.n_Al ⇒ n_N₂O = 0.15 mol ⇒ V = 0.15 × 24.79 = 3.7185 ≈ 3.72 lít.', 0.25, 'Vận dụng', 27),
(7, 'short_answer', 'Hòa tan hoàn toàn 16 gam một oxit sắt FeₓOᵧ bằng dung dịch H₂SO₄ đặc, nóng dư thu được 1.2395 lít khí SO₂ (ở ĐKC 24.79 lít/mol) và dung dịch chứa 40 gam muối Fe₂(SO₄)₃ (M = 400). Tính khối lượng sắt (Fe = 56) có trong 16 gam oxit sắt ban đầu theo đơn vị gam.', NULL, NULL, NULL, NULL, '11.2', 'n_Fe₂(SO₄)₃ = 40/400 = 0.1 mol ⇒ n_Fe = 0.2 mol ⇒ m_Fe = 0.2 × 56 = 11.2 gam.', 0.25, 'Vận dụng cao', 28);

-- ==========================================================
-- MÔN HÓA HỌC - ĐỀ SỐ 02 (exam_id = 8): 28 CÂU - 50 PHÚT - TỔNG 10.00 ĐIỂM
-- Phần I: 18 câu mcq (0.25đ = 4.50đ) | Phần II: 4 câu true_false (1.00đ = 4.00đ) | Phần III: 6 câu short_answer (0.25đ = 1.50đ)
-- ==========================================================
INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
-- Phần I: Chọn đáp án (1 - 18)
(8, 'mcq', 'Chất nào sau đây có công thức phân tử C₂H₄O₂ và phản ứng được với dung dịch NaOH?', 'Metyl fomat (HCOOCH₃)', 'Glucozơ', 'Etyl axetat', 'Ancol etylic', 'A', 'HCOOCH₃ có CTPT C₂H₄O₂ và là este nên tác dụng với NaOH.', 0.25, 'Nhận biết', 1),
(8, 'mcq', 'Sản phẩm của phản ứng este hóa giữa axit axetic và ancol etylic là:', 'Etyl axetat và nước', 'Metyl axetat và nước', 'Natri axetat và etanol', 'Etyl fomat và nước', 'A', 'CH₃COOH + C₂H₅OH ⇄ CH₃COOC₂H₅ + H₂O.', 0.25, 'Nhận biết', 2),
(8, 'mcq', 'Chất nào sau đây KHÔNG tan trong nước lạnh nhưng trương phồng tạo hồ tinh bột khi đun nóng?', 'Tinh bột', 'Saccarozơ', 'Glucozơ', 'Fructozơ', 'A', 'Tinh bột tạo dung dịch keo hồ tinh bột trong nước nóng.', 0.25, 'Nhận biết', 3),
(8, 'mcq', 'Amin nào sau đây là amin thơm?', 'Anilin (C₆H₅NH₂)', 'Metylamin', 'Đimetylamin', 'Etylamin', 'A', 'Anilin (C₆H₅NH₂) có nhóm -NH₂ gắn trực tiếp vào vòng benzen.', 0.25, 'Nhận biết', 4),
(8, 'mcq', 'Số liên kết peptit trong phân tử tetrapeptit mạch hở Ala-Gly-Val-Gly là:', '3', '4', '2', '5', 'A', 'Tetrapeptit gồm 4 gốc α-amino axit nên có 4 - 1 = 3 liên kết peptit.', 0.25, 'Nhận biết', 5),
(8, 'mcq', 'Monome dùng để tổng hợp tơ nitron (tơ olon) là:', 'Acrilonitrin (CH₂=CH-CN)', 'Vinyl clorua', 'Etilen', 'Stiren', 'A', 'Trùng hợp acrilonitrin thu được poli(acrilonitrin) để kéo tơ nitron.', 0.25, 'Nhận biết', 6),
(8, 'mcq', 'Ở nhiệt độ thường, kim loại nào sau đây có tính dẻo cao nhất?', 'Vàng (Au)', 'Bạc (Ag)', 'Đồng (Cu)', 'Nhôm (Al)', 'A', 'Vàng (Au) là kim loại dẻo nhất.', 0.25, 'Nhận biết', 7),
(8, 'mcq', 'Kim loại nào sau đây tan hoàn toàn trong dung dịch NaOH dư ở nhiệt độ thường?', 'Nhôm (Al)', 'Sắt (Fe)', 'Đồng (Cu)', 'Magie (Mg)', 'A', '2Al + 2NaOH + 2H₂O → 2NaAlO₂ + 3H₂↑.', 0.25, 'Nhận biết', 8),
(8, 'mcq', 'Nước vôi trong là dung dịch của chất nào sau đây?', 'Ca(OH)₂', 'NaOH', 'KOH', 'BaCl₂', 'A', 'Nước vôi trong là dung dịch canxi hiđroxit Ca(OH)₂.', 0.25, 'Nhận biết', 9),
(8, 'mcq', 'Công thức hóa học của oxit sắt từ là:', 'Fe₃O₄', 'FeO', 'Fe₂O₃', 'FeCO₃', 'A', 'Oxit sắt từ là Fe₃O₄.', 0.25, 'Nhận biết', 10),
(8, 'mcq', 'Phương pháp điều chế các kim loại kiềm và kiềm thổ (Na, Ca, Mg) trong công nghiệp là:', 'Điện phân nóng chảy', 'Thủy luyện', 'Nhiệt luyện bằng CO', 'Điện phân dung dịch', 'A', 'Kim loại hoạt động mạnh (Li → Al) điều chế bằng điện phân nóng chảy.', 0.25, 'Nhận biết', 11),
(8, 'mcq', 'Chất nào sau đây thuộc loại tơ bán tổng hợp (tơ nhân tạo)?', 'Tơ visco', 'Tơ tằm', 'Tơ nilon-6,6', 'Tơ capron', 'A', 'Tơ visco chế biến hóa học từ xenlulozơ thiên nhiên.', 0.25, 'Nhận biết', 12),
(8, 'mcq', 'Thủy phân este X (C₄H₈O₂) trong dung dịch NaOH thu được muối natri axetat và ancol Y. Công thức của Y là:', 'C₂H₅OH', 'CH₃OH', 'C₃H₇OH', 'C₄H₉OH', 'A', 'Muối là CH₃COONa (2C) ⇒ ancol Y là C₂H₅OH.', 0.25, 'Thông hiểu', 13),
(8, 'mcq', 'Sắp xếp các chất theo chiều tăng dần tính bazơ: (1) NH₃, (2) C₆H₅NH₂, (3) CH₃NH₂.', '(2) < (1) < (3)', '(1) < (2) < (3)', '(3) < (1) < (2)', '(2) < (3) < (1)', 'A', 'Anilin (2) < NH₃ (1) < Metylamin (3).', 0.25, 'Thông hiểu', 14),
(8, 'mcq', 'Nhúng thanh Fe vào 200 ml dung dịch CuSO₄ 0.5M đến khi phản ứng hoàn toàn. Độ tăng khối lượng của thanh Fe là (Fe = 56, Cu = 64):', '0.8 gam', '6.4 gam', '5.6 gam', '1.6 gam', 'A', 'n_Cu²⁺ = 0.1 mol ⇒ Δm = 0.1 × (64 - 56) = 0.8 gam.', 0.25, 'Thông hiểu', 15),
(8, 'mcq', 'Cho 3.9 gam kali (K = 39) tác dụng hết với nước dư, thu được 500 ml dung dịch KOH. Nồng độ mol của dung dịch KOH là:', '0.2 M', '0.1 M', '0.4 M', '0.5 M', 'A', 'n_KOH = n_K = 0.1 mol ⇒ C_M = 0.1 / 0.5 = 0.2 M.', 0.25, 'Thông hiểu', 16),
(8, 'mcq', 'Cho bột Fe dư tác dụng với dung dịch HNO₃ loãng. Sau khi phản ứng hoàn toàn, muối sắt thu được trong dung dịch là:', 'Fe(NO₃)₂', 'Fe(NO₃)₃', 'Fe₂(SO₄)₃', 'FeCl₂', 'A', 'Fe dư khử Fe³⁺ về Fe²⁺.', 0.25, 'Thông hiểu', 17),
(8, 'mcq', 'Cho 4.958 lít khí CO₂ (ở ĐKC 24.79 lít/mol) tác dụng với dung dịch KOH dư. Khối lượng muối K₂CO₃ (M = 138) thu được là:', '27.6 gam', '13.8 gam', '20.0 gam', '19.8 gam', 'A', 'n_CO₂ = 4.958/24.79 = 0.2 mol ⇒ m_K₂CO₃ = 0.2 × 138 = 27.6 gam.', 0.25, 'Thông hiểu', 18),

-- Phần II: Đúng / Sai 4 ý (19 - 22)
(8, 'true_false', 'Cho thế điện cực chuẩn của một số cặp oxi hóa - khử: E°(Mg²⁺/Mg) = -2.37 V, E°(Fe²⁺/Fe) = -0.44 V, E°(Cu²⁺/Cu) = +0.34 V, E°(Ag⁺/Ag) = +0.80 V.', 'a) Kim loại Mg có tính khử mạnh nhất trong 4 kim loại Mg, Fe, Cu, Ag.', 'b) Ion Ag⁺ có tính oxi hóa mạnh hơn ion Cu²⁺.', 'c) Kim loại Cu khử được ion Fe²⁺ trong dung dịch muối FeSO₄.', 'd) Sức điện động chuẩn của pin điện hóa Fe-Ag là 1.24 V.', 'D,D,S,D', 'a) Đúng: E° nhỏ nhất (-2.37 V) ⇒ tính khử mạnh nhất.\nb) Đúng: E°(Ag⁺/Ag) > E°(Cu²⁺/Cu).\nc) Sai: E°(Cu²⁺/Cu) > E°(Fe²⁺/Fe) nên Cu không khử được Fe²⁺.\nd) Đúng: E°_pin = 0.80 - (-0.44) = 1.24 V.', 1.00, 'Thông hiểu', 19),
(8, 'true_false', 'Trong dung dịch nước, các ion kim loại chuyển tiếp như Cu²⁺, Co²⁺, Fe³⁺ có khả năng tạo phức chất với các phối tử như H₂O, NH₃, Cl⁻. Khi nhỏ từ từ dung dịch NH₃ đến dư vào dung dịch CuSO₄ loãng (màu xanh nhạt), lúc đầu thấy xuất hiện kết tủa xanh nhạt, sau đó kết tủa tan dần tạo thành dung dịch màu xanh lam đậm chứa phức chất [Cu(NH₃)₄(H₂O)₂]²⁺.', 'a) Nguyên tử trung tâm trong phức chất [Cu(NH₃)₄(H₂O)₂]²⁺ là ion Cu²⁺.', 'b) Kết tủa xanh nhạt xuất hiện lúc đầu có công thức là Cu(OH)₂.', 'c) Phức chất [Cu(NH₃)₄(H₂O)₂]²⁺ có số phối trí bằng 4.', 'd) Phức chất trên mang điện tích +2.', 'D,D,S,D', 'a) Đúng.\nb) Đúng.\nc) Sai: Có 4 phối tử NH₃ và 2 phối tử H₂O nên số phối trí là 4 + 2 = 6.\nd) Đúng.', 1.00, 'Vận dụng', 20),
(8, 'true_false', 'Este E mạch hở có công thức phân tử C₄H₆O₂. Đun nóng E trong dung dịch NaOH thu được muối natri axetat (CH₃COONa) và chất hữu cơ F có khả năng tham gia phản ứng tráng bạc.', 'a) Este E có chứa 1 liên kết đôi C=C trong phân tử.', 'b) Công thức cấu tạo của este E là CH₃COOCH=CH₂ (vinyl axetat).', 'c) Chất hữu cơ F thu được sau phản ứng là ancol etylic (C₂H₅OH).', 'd) Khi đun nóng E với H₂O có xúc tác axit, thu được sản phẩm có mùi xốc của anđehit axetic.', 'D,D,S,D', 'a) Đúng: k = (2×4+2-6)/2 = 2 (1 nhóm COO và 1 nối đôi C=C).\nb) Đúng.\nc) Sai: CH₃COOCH=CH₂ + NaOH → CH₃COONa + CH₃CHO (anđehit axetic).\nd) Đúng.', 1.00, 'Vận dụng', 21),
(8, 'true_false', 'Cho 21.6 gam hỗn hợp X gồm Fe, FeO, Fe₂O₃ và Fe₃O₄ tác dụng hết với dung dịch H₂SO₄ đặc, nóng dư thu được 3.7185 lít khí SO₂ (sản phẩm khử duy nhất, ở ĐKC 24.79 lít/mol) và dung dịch Y chỉ chứa muối Fe₂(SO₄)₃.', 'a) Số mol khí SO₂ thu được là 0.15 mol.', 'b) Khi quy đổi hỗn hợp X thành Fe (a mol) và O (b mol), ta có phương trình bảo toàn khối lượng: 56a + 16b = 21.6.', 'c) Phương trình bảo toàn electron cho quá trình trên là 3a - 2b = 0.15.', 'd) Khối lượng kim loại sắt có trong 21.6 gam hỗn hợp X ban đầu là 16.8 gam.', 'D,D,S,D', 'a) Đúng: n_SO₂ = 3.7185 / 24.79 = 0.15 mol.\nb) Đúng.\nc) Sai: 3a = 2b + 2.n_SO₂ ⇔ 3a - 2b = 0.30.\nd) Đúng: Giải hệ 56a + 16b = 21.6 và 3a - 2b = 0.30 ⇒ a = 0.3 mol ⇒ m_Fe = 16.8 gam.', 1.00, 'Vận dụng cao', 22),

-- Phần III: Trả lời ngắn (23 - 28)
(8, 'short_answer', 'Cho 4.5 gam etylamin (C₂H₅NH₂, M = 45) tác dụng hoàn toàn với lượng dư axit HCl. Tính khối lượng muối thu được theo đơn vị gam.', NULL, NULL, NULL, NULL, '8.15', 'n_amin = 4.5/45 = 0.1 mol ⇒ m_muối = 4.5 + 0.1 × 36.5 = 8.15 gam.', 0.25, 'Nhận biết', 23),
(8, 'short_answer', 'Thủy phân hoàn toàn 32.4 gam tinh bột thành glucozơ (H = 75%), sau đó lên men toàn bộ glucozơ thành ancol etylic (H = 80%). Tính khối lượng ancol etylic thu được theo đơn vị gam.', NULL, NULL, NULL, NULL, '11.04', 'n_tinh bột = 0.2 mol ⇒ n_ancol = 2 × 0.2 × 0.75 × 0.80 = 0.24 mol ⇒ m = 0.24 × 46 = 11.04 gam.', 0.25, 'Thông hiểu', 24),
(8, 'short_answer', 'Cho 2.479 lít khí CO₂ (ở ĐKC 24.79 lít/mol) hấp thụ hết vào 150 ml dung dịch NaOH 1M. Tính tổng khối lượng muối thu được trong dung dịch sau phản ứng theo đơn vị gam.', NULL, NULL, NULL, NULL, '9.5', 'n_CO₂ = 0.1 mol, n_NaOH = 0.15 mol ⇒ n_Na₂CO₃ = 0.05 mol; n_NaHCO₃ = 0.05 mol ⇒ m = 0.05×106 + 0.05×84 = 9.5 gam.', 0.25, 'Thông hiểu', 25),
(8, 'short_answer', 'Hòa tan hết 9.6 gam Cu trong dung dịch HNO₃ đặc nóng dư thu được V lít khí NO₂ (sản phẩm khử duy nhất, ở ĐKC 24.79 lít/mol). Tính giá trị của V (làm tròn đến hàng phần trăm).', NULL, NULL, NULL, NULL, '7.44', 'n_Cu = 0.15 mol ⇒ n_NO₂ = 2×0.15 = 0.3 mol ⇒ V = 0.3 × 24.79 = 7.437 ≈ 7.44 lít.', 0.25, 'Vận dụng', 26),
(8, 'short_answer', 'Thủy phân hoàn toàn hỗn hợp gồm 0.1 mol vinyl axetat và 0.1 mol phenyl fomat bằng lượng vừa đủ dung dịch NaOH đun nóng. Tổng số mol NaOH đã phản ứng là bao nhiêu?', NULL, NULL, NULL, NULL, '0.3', 'Vinyl axetat tỉ lệ 1:1 (0.1 mol); Phenyl fomat là este của phenol tỉ lệ 1:2 (0.2 mol) ⇒ 0.3 mol.', 0.25, 'Vận dụng', 27),
(8, 'short_answer', 'Hỗn hợp E gồm este đơn chức X và este hai chức Y đều mạch hở. Thủy phân hoàn toàn 0.15 mol E cần vừa đủ 0.20 mol NaOH thu được hỗn hợp muối và một ancol duy nhất. Tính số mol của este hai chức Y trong 0.15 mol E.', NULL, NULL, NULL, NULL, '0.05', 'n_X + n_Y = 0.15 và n_X + 2.n_Y = 0.20 ⇒ n_Y = 0.05 mol.', 0.25, 'Vận dụng cao', 28);

-- DỮ LIỆU MẪU LỊCH SỬ LÀM BÀI (KHỚP 22 CÂU TOÁN / 40 CÂU ANH / 28 CÂU LÝ-HÓA)
INSERT INTO `exam_attempts` (`id`, `user_id`, `exam_id`, `score`, `correct_count`, `total_questions`, `time_spent_seconds`, `tab_switch_count`, `completed_at`) VALUES
(1, 2, 1, 8.75, 19, 22, 4620, 0, DATE_SUB(NOW(), INTERVAL 2 DAY)),
(2, 2, 3, 8.75, 35, 40, 2940, 1, DATE_SUB(NOW(), INTERVAL 1 DAY)),
(3, 3, 5, 8.50, 24, 28, 2580, 0, DATE_SUB(NOW(), INTERVAL 5 HOUR)),
(4, 2, 7, 9.00, 25, 28, 2410, 2, DATE_SUB(NOW(), INTERVAL 2 HOUR));

-- ==========================================================
-- THÊM 12 ĐỀ THI MỚI (MỖI MÔN THÊM 3 ĐỀ -> TỔNG 5 ĐỀ / MÔN)
-- ==========================================================
INSERT INTO `exams` (`id`, `subject_id`, `title`, `description`, `duration_minutes`, `level`, `is_active`) VALUES
(9, 1, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Toán - Đề Số 03', '22 câu – 90 phút chuẩn cấu trúc mới 2025: Giải tích, Hình học không gian, Oxyz, Thống kê & Xác suất có điều kiện.', 90, 'Chuẩn THPT QG', 1),
(10, 1, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Toán - Đề Số 04', '22 câu – 90 phút chuẩn cấu trúc mới 2025: Ứng dụng đạo hàm, Tích phân, Hình Oxyz & Bài toán thực tế.', 90, 'Chuẩn THPT QG', 1),
(11, 1, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Toán - Đề Số 05', '22 câu – 90 phút chuẩn cấu trúc mới 2025: Tổng ôn chuyên sâu chuẩn ma trận Bộ GD&ĐT (GDPT 2018).', 90, 'Chuẩn THPT QG', 1),
(12, 2, 'Đề Thi Thử THPT Quốc Gia 2026 Môn Tiếng Anh - Đề Số 03', '40 câu – 50 phút (0.25đ/câu). Phát âm, Trọng âm, Ngữ pháp, Từ vựng, Sắp xếp hội thoại & Đọc hiểu.', 50, 'Chuẩn THPT QG', 1),
(13, 2, 'Đề Thi Thử THPT Quốc Gia 2026 Môn Tiếng Anh - Đề Số 04', '40 câu – 50 phút (0.25đ/câu). Luyện chuyên sâu Đọc điền, Tìm lỗi sai, Viết lại câu & Đọc hiểu.', 50, 'Chuẩn THPT QG', 1),
(14, 2, 'Đề Thi Thử THPT Quốc Gia 2026 Môn Tiếng Anh - Đề Số 05', '40 câu – 50 phút (0.25đ/câu). Đề tổng hợp chuẩn cấu trúc thi tốt nghiệp THPT 2026.', 50, 'Chuẩn THPT QG', 1),
(15, 3, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Vật Lý - Đề Số 03', '28 câu – 50 phút chuẩn cấu trúc mới 2025: Vật lý nhiệt, Khí lí tưởng, Từ trường & Hạt nhân.', 50, 'Chuẩn THPT QG', 1),
(16, 3, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Vật Lý - Đề Số 04', '28 câu – 50 phút chuẩn cấu trúc mới 2025: Dao động, Sóng, Cảm ứng điện từ & Phóng xạ.', 50, 'Chuẩn THPT QG', 1),
(17, 3, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Vật Lý - Đề Số 05', '28 câu – 50 phút chuẩn cấu trúc mới 2025: Tổng hợp chuẩn ma trận Bộ GD&ĐT (GDPT 2018).', 50, 'Chuẩn THPT QG', 1),
(18, 4, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Hóa Học - Đề Số 03', '28 câu – 50 phút chuẩn cấu trúc mới 2025 (ĐKC 24.79 lít/mol): Este, Cacbohidrat, Amin & Pin điện.', 50, 'Chuẩn THPT QG', 1),
(19, 4, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Hóa Học - Đề Số 04', '28 câu – 50 phút chuẩn cấu trúc mới 2025 (ĐKC 24.79 lít/mol): Peptit, Polime, Phức chất & Kim loại.', 50, 'Chuẩn THPT QG', 1),
(20, 4, 'Đề Thi Thử THPT Quốc Gia 2025 Môn Hóa Học - Đề Số 05', '28 câu – 50 phút chuẩn cấu trúc mới 2025 (ĐKC 24.79 lít/mol): Tổng hợp vô cơ - hữu cơ GDPT 2018.', 50, 'Chuẩn THPT QG', 1);

INSERT INTO `questions` (`exam_id`, `question_type`, `question_text`, `option_a`, `option_b`, `option_c`, `option_d`, `correct_option`, `explanation`, `points_value`, `difficulty`, `sort_order`) VALUES
(9, 'mcq', 'Cho hàm số y = x³ - 3x² + 2. Hàm số nghịch biến trên khoảng nào dưới đây?', '(-∞; 0)', '(2; +∞)', '(-2; 0)', '(0; 2)', 'D', 'y'' = 3x² - 6x < 0 ⇔ 0 < x < 2.', 0.25, 'Nhận biết', 1),
(9, 'mcq', 'Đường tiệm cận ngang của đồ thị hàm số y = (3x - 5)/(x + 2) là:', 'x = -2', 'y = -5/2', 'y = 3', 'y = 2', 'C', 'lim_{x→±∞} (3x - 5)/(x + 2) = 3 nên TCN là y = 3.', 0.25, 'Nhận biết', 2),
(9, 'mcq', 'Họ nguyên hàm của hàm số f(x) = eˣ + 2x là:', 'eˣ + 2 + C', 'eˣ + 2x² + C', 'xeˣ⁻¹ + x² + C', 'eˣ + x² + C', 'D', '∫(eˣ + 2x)dx = eˣ + x² + C.', 0.25, 'Nhận biết', 3),
(9, 'mcq', 'Nghiệm của phương trình 3^(2x - 1) = 27 là:', 'x = 1', 'x = 3', 'x = 4', 'x = 2', 'D', '3^(2x-1) = 3³ ⇔ 2x - 1 = 3 ⇔ x = 2.', 0.25, 'Nhận biết', 4),
(9, 'mcq', 'Trong không gian Oxyz, mặt phẳng (P): 2x - y + 3z - 5 = 0 có một vectơ pháp tuyến là:', 'n = (-1; 3; -5)', 'n = (2; -1; -5)', 'n = (2; 1; 3)', 'n = (2; -1; 3)', 'D', 'Hệ số của x, y, z là (2; -1; 3).', 0.25, 'Nhận biết', 5),
(9, 'mcq', 'Cho cấp số cộng (uₙ) với u₁ = 5 và công sai d = 3. Giá trị của u₆ bằng:', '17', '23', '20', '18', 'C', 'u₆ = u₁ + 5d = 5 + 15 = 20.', 0.25, 'Nhận biết', 6),
(9, 'mcq', 'Thể tích khối lăng trụ có diện tích đáy B = 12 và chiều cao h = 5 bằng:', '20', '60', '30', '17', 'B', 'V = B.h = 12 × 5 = 60.', 0.25, 'Nhận biết', 7),
(9, 'mcq', 'Cho tích phân ∫₀² f(x)dx = 4 và ∫₀² g(x)dx = -1. Giá trị của ∫₀² [2f(x) - g(x)]dx bằng:', '9', '6', '10', '7', 'A', '2×4 - (-1) = 9.', 0.25, 'Thông hiểu', 8),
(9, 'mcq', 'Trong không gian Oxyz, bán kính của mặt cầu (S): (x - 1)² + (y + 2)² + (z - 3)² = 16 là:', '2', '8', '4', '16', 'C', 'R = √16 = 4.', 0.25, 'Nhận biết', 9),
(9, 'mcq', 'Cho mẫu số liệu ghép nhóm có bảng tần số: [0;10): 4, [10;20): 6, [20;30): 8, [30;40): 2. Khoảng biến thiên của mẫu số liệu ghép nhóm này là:', '30', '40', '10', '20', 'B', 'R = 40 - 0 = 40.', 0.25, 'Thông hiểu', 10),
(9, 'mcq', 'Giá trị nhỏ nhất của hàm số y = x + 4/x trên đoạn [1; 3] là:', '13/3', '2', '4', '5', 'C', 'y'' = 1 - 4/x² = 0 ⇒ x = 2 ∈ [1;3]. f(1)=5, f(2)=4, f(3)=13/3. Min = 4.', 0.25, 'Thông hiểu', 11),
(9, 'mcq', 'Cho hai biến cố A, B độc lập với P(A) = 0.4 và P(B) = 0.5. Xác suất P(A ∩ B) bằng:', '0.25', '0.1', '0.9', '0.2', 'D', 'Do A, B độc lập nên P(A ∩ B) = P(A).P(B) = 0.4 × 0.5 = 0.2.', 0.25, 'Thông hiểu', 12),
(9, 'true_false', 'Cho hàm số f(x) = x³ - 3x + 1.', 'a) Đạo hàm của hàm số là f''(x) = 3x² - 3.', 'b) Hàm số đạt cực đại tại x = 1.', 'c) Giá trị cực tiểu của hàm số bằng -1.', 'd) Phương trình f(x) = 0 có đúng 3 nghiệm thực phân biệt.', 'D,S,D,D', 'a) Đúng.
b) Sai: f''(x)=0 tại x=±1; cực đại tại x=-1, cực tiểu tại x=1.
c) Đúng: f(1) = 1 - 3 + 1 = -1.
d) Đúng: f(-1)=3 > 0 và f(1)=-1 < 0 nên có 3 nghiệm phân biệt.', 1.00, 'Thông hiểu', 13),
(9, 'true_false', 'Một ô tô đang chạy với vận tốc 20 m/s thì người lái đạp phanh; từ thời điểm đó, ô tô chuyển động chậm dần đều với vận tốc v(t) = 20 - 4t (m/s), trong đó t là thời gian tính bằng giây kể từ lúc đạp phanh.', 'a) Thời gian từ lúc đạp phanh đến khi ô tô dừng hẳn là 5 giây.', 'b) Gia tốc của ô tô trong giai đoạn phanh là -4 m/s².', 'c) Quãng đường ô tô đi được trong 3 giây đầu tiên kể từ lúc đạp phanh là 42 m.', 'd) Tổng quãng đường ô tô đi được từ lúc đạp phanh đến khi dừng hẳn là 50 m.', 'D,D,D,D', 'a) Đúng: v(t)=0 ⇔ t=5.
b) Đúng: a(t)=v''(t)=-4.
c) Đúng: ∫₀³(20-4t)dt = [20t-2t²]₀³ = 60 - 18 = 42 m.
d) Đúng: ∫₀⁵(20-4t)dt = 100 - 50 = 50 m.', 1.00, 'Vận dụng', 14),
(9, 'true_false', 'Trong không gian Oxyz, cho hai điểm A(1; 2; -1), B(3; 0; 1) và mặt phẳng (P): x + y - z + 2 = 0.', 'a) Trung điểm I của đoạn thẳng AB có tọa độ là (2; 1; 0).', 'b) Độ dài đoạn thẳng AB bằng 2√3.', 'c) Đường thẳng AB đi qua điểm M(5; -2; 3).', 'd) Khoảng cách từ điểm A đến mặt phẳng (P) bằng √3.', 'D,D,D,S', 'a) Đúng: I(2;1;0).
b) Đúng: |AB| = √(2²+(-2)²+2²) = 2√3.
c) Đúng: AM = 2.AB.
d) Sai: d(A,(P)) = |1+2+1+2|/√3 = 6/√3 = 2√3.', 1.00, 'Vận dụng', 15),
(9, 'true_false', 'Tại một trường THPT, tỉ lệ học sinh nam là 45% và nữ là 55%. Tỉ lệ học sinh nam thích môn Toán là 60%, tỉ lệ học sinh nữ thích môn Toán là 40%.', 'a) Xác suất chọn ngẫu nhiên một học sinh của trường là nam bằng 0.45.', 'b) Xác suất chọn được học sinh thích môn Toán biết rằng học sinh đó là nữ bằng 0.4.', 'c) Xác suất chọn ngẫu nhiên một học sinh vừa là nam vừa thích môn Toán bằng 0.27.', 'd) Tỉ lệ học sinh toàn trường thích môn Toán là 50%.', 'D,D,D,S', 'a) Đúng.
b) Đúng.
c) Đúng: 0.45 × 0.60 = 0.27.
d) Sai: P(Thích Toán) = 0.45×0.60 + 0.55×0.40 = 0.27 + 0.22 = 0.49 (49%).', 1.00, 'Vận dụng', 16),
(9, 'short_answer', 'Tính giá trị của tích phân I = ∫₀³ (2x + 1) dx.', NULL, NULL, NULL, NULL, '12', 'I = [x² + x]₀³ = 9 + 3 = 12.', 0.50, 'Thông hiểu', 17),
(9, 'short_answer', 'Cho hình chóp S.ABCD có đáy ABCD là hình vuông cạnh bằng 3, cạnh bên SA vuông góc với mặt phẳng đáy và SA = 4. Tính thể tích khối chóp S.ABCD.', NULL, NULL, NULL, NULL, '12', 'V = (1/3) × S_ABCD × SA = (1/3) × 3² × 4 = 12.', 0.50, 'Thông hiểu', 18),
(9, 'short_answer', 'Trong không gian Oxyz, đường thẳng d đi qua điểm M(1; 2; 3) và vuông góc với mặt phẳng (P): 2x - 2y + z - 1 = 0 cắt mặt phẳng (Oxy) tại điểm N(a; b; 0). Tính giá trị của a + b.', NULL, NULL, NULL, NULL, '3', 'd có vtcp n=(2;-2;1): x=1+2t, y=2-2t, z=3+t. Giao (Oxy) khi z=0 ⇒ t=-3 ⇒ a=-5, b=8 ⇒ a+b=3.', 0.50, 'Vận dụng', 19),
(9, 'short_answer', 'Tính diện tích hình phẳng giới hạn bởi đồ thị hàm số y = 3x - x² và trục hoành (y = 0).', NULL, NULL, NULL, NULL, '4.5', 'Hoành độ giao điểm: 3x - x² = 0 ⇔ x = 0 hoặc x = 3. S = ∫₀³ (3x - x²)dx = [1.5x² - x³/3]₀³ = 13.5 - 9 = 4.5.', 0.50, 'Vận dụng', 20),
(9, 'short_answer', 'Một hộp có 5 viên bi đỏ và 3 viên bi xanh. Lấy ngẫu nhiên đồng thời 2 viên bi. Tính xác suất để cả 2 viên bi lấy được đều có màu đỏ (làm tròn kết quả đến hàng phần trăm).', NULL, NULL, NULL, NULL, '0.36', 'P = C(5,2)/C(8,2) = 10/28 = 5/14 ≈ 0.36.', 0.50, 'Vận dụng', 21),
(9, 'short_answer', 'Một người gửi tiết kiệm 100 triệu đồng vào ngân hàng với lãi suất 6%/năm theo hình thức lãi kép kì hạn 1 năm. Hỏi sau ít nhất bao nhiêu năm thì số tiền cả gốc lẫn lãi người đó nhận được vượt quá 150 triệu đồng?', NULL, NULL, NULL, NULL, '7', '100 × (1.06)^n > 150 ⇔ (1.06)^n > 1.5 ⇒ n ≥ 7 (năm thứ 6 được 141.85 triệu, năm thứ 7 được 150.36 triệu).', 0.50, 'Vận dụng cao', 22),
(10, 'mcq', 'Cho hàm số y = x⁴ - 2x² + 3. Số điểm cực trị của hàm số là:', '0', '2', '3', '1', 'C', 'y'' = 4x³ - 4x = 0 có 3 nghiệm phân biệt x = 0, x = ±1.', 0.25, 'Nhận biết', 1),
(10, 'mcq', 'Tiệm cận ngang của đồ thị hàm số y = (2x + 1)/(1 - x) là đường thẳng:', 'x = 1', 'y = -2', 'y = 2', 'y = 1', 'B', 'lim_{x→±∞} (2x+1)/(1-x) = -2.', 0.25, 'Nhận biết', 2),
(10, 'mcq', 'Nguyên hàm của hàm số f(x) = cos(2x) là:', '(1/2)sin(2x) + C', '-(1/2)sin(2x) + C', '2sin(2x) + C', 'sin(2x) + C', 'A', '∫cos(2x)dx = (1/2)sin(2x) + C.', 0.25, 'Nhận biết', 3),
(10, 'mcq', 'Tập nghiệm của bất phương trình (1/2)^x > 8 là:', '(-∞; 3)', '(-3; +∞)', '(3; +∞)', '(-∞; -3)', 'D', '(1/2)^x > (1/2)^(-3) ⇔ x < -3.', 0.25, 'Nhận biết', 4),
(10, 'mcq', 'Trong không gian Oxyz, cho vectơ a = (1; -2; 2). Độ dài của vectơ a bằng:', '3', '9', '√5', '5', 'A', '|a| = √(1² + (-2)² + 2²) = √9 = 3.', 0.25, 'Nhận biết', 5),
(10, 'mcq', 'Cho cấp số nhân (uₙ) có u₁ = 2 và u₂ = -6. Công bội q của cấp số nhân là:', '3', '-8', '-4', '-3', 'D', 'q = u₂ / u₁ = -6 / 2 = -3.', 0.25, 'Nhận biết', 6),
(10, 'mcq', 'Thể tích khối cầu có bán kính R = 3 bằng:', '36π', '27π', '12π', '108π', 'A', 'V = (4/3)πR³ = (4/3)π.27 = 36π.', 0.25, 'Nhận biết', 7),
(10, 'mcq', 'Trong không gian Oxyz, đường thẳng d: (x-1)/2 = (y+1)/(-3) = z/4 có một vectơ chỉ phương là:', 'u = (-1; 1; 0)', 'u = (1; -1; 0)', 'u = (2; 3; 4)', 'u = (2; -3; 4)', 'D', 'Mẫu số là tọa độ vectơ chỉ phương (2; -3; 4).', 0.25, 'Nhận biết', 8),
(10, 'mcq', 'Cho ∫₁⁴ f(x)dx = 7 và ∫₁⁴ g(x)dx = 3. Giá trị ∫₁⁴ [f(x) + 2g(x)]dx bằng:', '13', '10', '17', '11', 'A', '7 + 2×3 = 13.', 0.25, 'Thông hiểu', 9),
(10, 'mcq', 'Số cách chọn 3 học sinh từ một nhóm gồm 10 học sinh là:', '30', '120', '720', '1000', 'B', 'C(10, 3) = 120.', 0.25, 'Nhận biết', 10),
(10, 'mcq', 'Giá trị lớn nhất của hàm số y = -x³ + 3x + 1 trên đoạn [0; 2] là:', '5', '1', '3', '-1', 'C', 'y'' = -3x² + 3 = 0 ⇒ x = 1 ∈ [0;2]. f(0)=1, f(1)=3, f(2)=-1. Max = 3.', 0.25, 'Thông hiểu', 11),
(10, 'mcq', 'Trong một bảng thống kê ghép nhóm gồm 40 học sinh, nhóm chứa tứ phân vị thứ nhất Q₁ là nhóm [5; 6) có tần số 10, tần số tích lũy trước đó là 6. Giá trị của Q₁ là:', '5.2', '5.6', '5.5', '5.4', 'D', 'Q₁ = 5 + ((40/4 - 6)/10)×1 = 5 + 0.4 = 5.4.', 0.25, 'Thông hiểu', 12),
(10, 'true_false', 'Cho hàm số y = (x + 1)/(x - 1).', 'a) Tập xác định của hàm số là ℝ \\ {1}.', 'b) Đạo hàm của hàm số là y'' = -2/(x - 1)².', 'c) Hàm số đồng biến trên từng khoảng xác định.', 'd) Giao điểm hai đường tiệm cận của đồ thị hàm số là I(1; 1).', 'D,D,S,D', 'a) Đúng.
b) Đúng: (1×(-1) - 1×1)/(x-1)² = -2/(x-1)².
c) Sai: y'' < 0 nên hàm số nghịch biến trên từng khoảng xác định.
d) Đúng: TCĐ x = 1, TCN y = 1 ⇒ I(1; 1).', 1.00, 'Thông hiểu', 13),
(10, 'true_false', 'Cho hình chóp S.ABCD có đáy ABCD là hình chữ nhật với AB = 2, AD = 4, cạnh bên SA vuông góc với đáy và SA = 2.', 'a) Đường thẳng BC vuông góc với mặt phẳng (SAB).', 'b) Thể tích khối chóp S.ABCD bằng 16/3.', 'c) Góc giữa đường thẳng SB và mặt phẳng đáy (ABCD) bằng 45°.', 'd) Khoảng cách từ điểm A đến mặt phẳng (SBC) bằng 2.', 'D,D,D,S', 'a) Đúng: BC ⊥ AB và BC ⊥ SA.
b) Đúng: V = (1/3)×(2×4)×2 = 16/3.
c) Đúng: tan(SBA) = SA/AB = 2/2 = 1 ⇒ 45°.
d) Sai: d(A,(SBC)) = SA.AB / √(SA²+AB²) = 4/√8 = √2.', 1.00, 'Vận dụng', 14),
(10, 'true_false', 'Trong không gian Oxyz, cho ba điểm A(1; 0; 0), B(0; 2; 0), C(0; 0; 3).', 'a) Phương trình mặt phẳng (ABC) là x/1 + y/2 + z/3 = 1.', 'b) Điểm M(2; -2; 0) thuộc mặt phẳng (ABC).', 'c) Thể tích tứ diện OABC bằng 1.', 'd) Vectơ n = (6; 3; 2) là một vectơ pháp tuyến của mặt phẳng (ABC).', 'D,D,D,D', 'a) Đúng (phương trình đoạn chắn).
b) Đúng: 2/1 + (-2)/2 + 0/3 = 2 - 1 = 1.
c) Đúng: V = (1/6).1.2.3 = 1.
d) Đúng: 6x + 3y + 2z - 6 = 0 có vtpt (6;3;2).', 1.00, 'Vận dụng', 15),
(10, 'true_false', 'Có hai hộp bi: Hộp I có 4 bi trắng và 6 bi đen; Hộp II có 7 bi trắng và 3 bi đen. Tung một đồng xu cân đối, nếu ra mặt ngửa thì lấy ngẫu nhiên 1 bi từ Hộp I, nếu ra mặt sấp thì lấy ngẫu nhiên 1 bi từ Hộp II.', 'a) Xác suất chọn được Hộp I bằng 0.5.', 'b) Xác suất lấy được bi trắng biết đã chọn Hộp II bằng 0.7.', 'c) Xác suất để lấy được viên bi trắng là 0.55.', 'd) Biết rằng viên bi lấy ra là màu trắng, xác suất để viên bi đó thuộc Hộp I là 4/11.', 'D,D,D,D', 'a) Đúng.
b) Đúng.
c) Đúng: P(T) = 0.5×0.4 + 0.5×0.7 = 0.20 + 0.35 = 0.55.
d) Đúng: P(I|T) = 0.20 / 0.55 = 4/11 (Công thức Bayes).', 1.00, 'Vận dụng cao', 16),
(10, 'short_answer', 'Tính giá trị tích phân I = ∫₀^(π/2) (2sin x + cos x) dx.', NULL, NULL, NULL, NULL, '3', 'I = [-2cos x + sin x]₀^(π/2) = (0 + 1) - (-2 + 0) = 3.', 0.50, 'Thông hiểu', 17),
(10, 'short_answer', 'Tìm nghiệm của phương trình log₂(x) + log₂(x - 2) = 3.', NULL, NULL, NULL, NULL, '4', 'ĐK: x > 2. PT ⇔ log₂[x(x-2)] = 3 ⇔ x² - 2x - 8 = 0 ⇒ x = 4.', 0.50, 'Thông hiểu', 18),
(10, 'short_answer', 'Cho hình nón có bán kính đáy r = 3 và chiều cao h = 4. Diện tích xung quanh của hình nón có dạng aπ. Tìm giá trị của a.', NULL, NULL, NULL, NULL, '15', 'Độ dài đường sinh l = √(r² + h²) = √(9 + 16) = 5. S_xq = πrl = 15π ⇒ a = 15.', 0.50, 'Thông hiểu', 19),
(10, 'short_answer', 'Trong không gian Oxyz, tính khoảng cách từ gốc tọa độ O(0; 0; 0) đến mặt phẳng (P): 2x - y + 2z - 9 = 0.', NULL, NULL, NULL, NULL, '3', 'd(O,(P)) = |-9| / √(2² + (-1)² + 2²) = 9 / 3 = 3.', 0.50, 'Nhận biết', 20),
(10, 'short_answer', 'Một chất điểm chuyển động thẳng với phương trình s(t) = t³ - 3t² + 9t + 2 (s tính bằng mét, t tính bằng giây, t ≥ 0). Tính vận tốc nhỏ nhất (theo đơn vị m/s) của chất điểm.', NULL, NULL, NULL, NULL, '6', 'v(t) = s''(t) = 3t² - 6t + 9 = 3(t - 1)² + 6 ≥ 6. Vận tốc nhỏ nhất là 6 m/s tại t = 1s.', 0.50, 'Vận dụng', 21),
(10, 'short_answer', 'Từ một tấm tôn hình vuông cạnh 12 cm, người ta cắt bỏ ở bốn góc bốn hình vuông bằng nhau có cạnh x (cm) rồi gập lại thành một cái hộp không nắp dạng hình hộp chữ nhật. Thể tích lớn nhất của cái hộp đó là bao nhiêu cm³?', NULL, NULL, NULL, NULL, '128', 'V(x) = x(12 - 2x)² với 0 < x < 6. V''(x) = (12 - 2x)(12 - 6x) = 0 ⇔ x = 2. V_max = 2 × 8² = 128 cm³.', 0.50, 'Vận dụng cao', 22),
(11, 'mcq', 'Hàm số y = (2x - 1)/(x + 1) đồng biến trên khoảng nào sau đây?', '(-∞; +∞)', 'ℝ \\ {-1}', '(-∞; -1)', '(-2; 0)', 'C', 'y'' = 3/(x+1)² > 0 với mọi x ≠ -1, nên hàm số đồng biến trên (-∞; -1) và (-1; +∞) (chú ý không kết luận trên ℝ \\ {-1}).', 0.25, 'Thông hiểu', 1),
(11, 'mcq', 'Tiệm cận đứng của đồ thị hàm số y = (x + 2)/(2x - 4) là đường thẳng:', 'x = -2', 'x = 2', 'y = 1/2', 'x = 4', 'B', '2x - 4 = 0 ⇔ x = 2.', 0.25, 'Nhận biết', 2),
(11, 'mcq', 'Họ nguyên hàm của hàm số f(x) = 1/x + 3x² (với x > 0) là:', 'ln(x) + x³ + C', 'ln|x| + 3x³ + C', '-1/x² + x³ + C', 'ln(x) + 6x + C', 'A', '∫(1/x + 3x²)dx = ln(x) + x³ + C (vì x > 0).', 0.25, 'Nhận biết', 3),
(11, 'mcq', 'Nghiệm của phương trình log₃(2x - 1) = 2 là:', 'x = 4', 'x = 5', 'x = 4.5', 'x = 3.5', 'B', '2x - 1 = 3² = 9 ⇔ x = 5.', 0.25, 'Nhận biết', 4),
(11, 'mcq', 'Trong không gian Oxyz, tích vô hướng của hai vectơ u = (1; 2; -1) và v = (3; -1; 2) bằng:', '-3', '1', '-1', '3', 'C', 'u.v = 1×3 + 2×(-1) + (-1)×2 = 3 - 2 - 2 = -1.', 0.25, 'Nhận biết', 5),
(11, 'mcq', 'Cho cấp số cộng (uₙ) có u₁ = -2 và u₅ = 10. Công sai d của cấp số cộng là:', '12', '4', '3', '2', 'C', 'u₅ = u₁ + 4d ⇔ 10 = -2 + 4d ⇔ d = 3.', 0.25, 'Nhận biết', 6),
(11, 'mcq', 'Thể tích của khối chóp có diện tích đáy B = 15 và chiều cao h = 6 bằng:', '90', '30', '45', '60', 'B', 'V = (1/3)Bh = (1/3)×15×6 = 30.', 0.25, 'Nhận biết', 7),
(11, 'mcq', 'Trong không gian Oxyz, phương trình mặt phẳng đi qua điểm M(1; -1; 2) và có vectơ pháp tuyến n = (2; 1; -3) là:', '2x + y - 3z + 5 = 0', '2x + y - 3z + 7 = 0', '2x - y - 3z + 5 = 0', '2x + y - 3z - 5 = 0', 'A', '2(x-1) + 1(y+1) - 3(z-2) = 0 ⇔ 2x + y - 3z + 5 = 0.', 0.25, 'Thông hiểu', 8),
(11, 'mcq', 'Nếu ∫₀⁴ f(x)dx = 10 và ∫₀² f(x)dx = 4 thì ∫₂⁴ f(x)dx bằng:', '6', '40', '14', '-6', 'A', '∫₂⁴ f(x)dx = ∫₀⁴ f(x)dx - ∫₀² f(x)dx = 10 - 4 = 6.', 0.25, 'Nhận biết', 9),
(11, 'mcq', 'Một lớp học có 20 nam và 15 nữ. Số cách chọn 1 học sinh làm lớp trưởng là:', '15', '20', '35', '300', 'C', 'Quy tắc cộng: 20 + 15 = 35 cách.', 0.25, 'Nhận biết', 10),
(11, 'mcq', 'Số nghiệm nguyên của bất phương trình log₀.₅(x - 1) ≥ -2 là:', 'vô số', '4', '3', '5', 'B', 'ĐK: x > 1. BPT ⇔ x - 1 ≤ (0.5)^(-2) = 4 ⇔ 1 < x ≤ 5 ⇒ x ∈ {2, 3, 4, 5} (4 nghiệm).', 0.25, 'Thông hiểu', 11),
(11, 'mcq', 'Trong mặt phẳng Oxy (hoặc không gian Oxyz), mặt cầu (S): x² + y² + z² - 2x + 4y - 6z - 2 = 0 có tâm I và bán kính R lần lượt là:', 'I(1; -2; 3), R = √12', 'I(-1; 2; -3), R = 4', 'I(1; -2; 3), R = 4', 'I(1; -2; 3), R = 16', 'C', 'a=1, b=-2, c=3, d=-2 ⇒ R = √(1 + 4 + 9 - (-2)) = √16 = 4.', 0.25, 'Thông hiểu', 12),
(11, 'true_false', 'Cho hàm số y = x³ - 3x² + 4.', 'a) Điểm cực đại của đồ thị hàm số là (0; 4).', 'b) Hàm số đồng biến trên khoảng (2; +∞).', 'c) Giá trị lớn nhất của hàm số trên đoạn [-1; 3] bằng 4.', 'd) Đường thẳng y = 2 cắt đồ thị hàm số tại đúng 2 điểm phân biệt.', 'D,D,D,S', 'a) Đúng: y''=3x²-6x=0 ⇒ x=0 (CĐ, y=4), x=2 (CT, y=0).
b) Đúng.
c) Đúng: f(-1)=0, f(0)=4, f(2)=0, f(3)=4 ⇒ Max = 4.
d) Sai: 0 < 2 < 4 nên y = 2 cắt đồ thị tại 3 điểm phân biệt.', 1.00, 'Thông hiểu', 13),
(11, 'true_false', 'Cho hình lập phương ABCD.A''B''C''D'' có cạnh bằng a = 2.', 'a) Thể tích của khối lập phương bằng 8.', 'b) Độ dài đường chéo AC'' bằng 2√3.', 'c) Góc giữa hai đường thẳng AB và B''C'' bằng 90°.', 'd) Khoảng cách từ điểm A đến mặt phẳng (BDD''B'') bằng 2.', 'D,D,D,S', 'a) Đúng: V = 2³ = 8.
b) Đúng: AC'' = a√3 = 2√3.
c) Đúng: B''C'' // BC và AB ⊥ BC ⇒ góc = 90°.
d) Sai: d(A,(BDD''B'')) = AC/2 = a√2/2 = √2.', 1.00, 'Vận dụng', 14),
(11, 'true_false', 'Trong không gian Oxyz, cho điểm A(1; 2; 3) và đường thẳng d: (x - 1)/1 = y/2 = (z + 1)/(-1).', 'a) Đường thẳng d đi qua điểm M(1; 0; -1).', 'b) Một vectơ chỉ phương của d là u = (1; 2; -1).', 'c) Điểm A nằm trên đường thẳng d.', 'd) Mặt phẳng đi qua A và vuông góc với d có phương trình x + 2y - z - 2 = 0.', 'D,D,S,D', 'a) Đúng.
b) Đúng.
c) Sai: Thay A(1;2;3) vào d được 0/1 = 2/2 = 4/(-1) (vô lý).
d) Đúng: 1(x-1) + 2(y-2) - 1(z-3) = 0 ⇔ x + 2y - z - 2 = 0.', 1.00, 'Vận dụng', 15),
(11, 'true_false', 'Thống kê điểm kiểm tra Toán của 40 học sinh lớp 12A được cho trong bảng ghép nhóm: [4;6): 8 học sinh, [6;8): 20 học sinh, [8;10): 12 học sinh.', 'a) Cỡ mẫu của bảng số liệu là n = 40.', 'b) Giá trị đại diện của nhóm [6; 8) là 7.', 'c) Số trung bình cộng của mẫu số liệu ghép nhóm bằng 7.2.', 'd) Nhóm chứa trung vị là nhóm [8; 10).', 'D,D,D,S', 'a) Đúng: 8 + 20 + 12 = 40.
b) Đúng: (6+8)/2 = 7.
c) Đúng: (5×8 + 7×20 + 9×12)/40 = (40+140+108)/40 = 288/40 = 7.2.
d) Sai: n/2 = 20, tần số tích lũy đến [6;8) là 8+20=28 ≥ 20 nên nhóm chứa trung vị là [6;8).', 1.00, 'Thông hiểu', 16),
(11, 'short_answer', 'Tính giá trị tích phân I = ∫₁² (4x³ - 2x) dx.', NULL, NULL, NULL, NULL, '12', 'I = [x⁴ - x²]₁² = (16 - 4) - (1 - 1) = 12.', 0.50, 'Thông hiểu', 17),
(11, 'short_answer', 'Tính tổng tất cả các nghiệm của phương trình 2^(x² - 3x) = 4.', NULL, NULL, NULL, NULL, '3', 'PT ⇔ x² - 3x = 2 ⇔ x² - 3x - 2 = 0. Theo Vi-et, x₁ + x₂ = 3.', 0.50, 'Thông hiểu', 18),
(11, 'short_answer', 'Trong không gian Oxyz, tính độ dài đoạn thẳng AB biết A(2; -1; 3) và B(-2; 2; 3).', NULL, NULL, NULL, NULL, '5', 'AB = (-4; 3; 0) ⇒ |AB| = √((-4)² + 3² + 0²) = 5.', 0.50, 'Nhận biết', 19),
(11, 'short_answer', 'Một hình trụ có bán kính đáy r = 2 và chiều cao h = 5. Thể tích của khối trụ đó bằng kπ. Tìm giá trị của k.', NULL, NULL, NULL, NULL, '20', 'V = πr²h = π × 2² × 5 = 20π ⇒ k = 20.', 0.50, 'Nhận biết', 20),
(11, 'short_answer', 'Tìm hoành độ điểm cực tiểu của hàm số y = (x² + 3)/(x + 1).', NULL, NULL, NULL, NULL, '1', 'y'' = (x² + 2x - 3)/(x+1)² = 0 ⇔ x = -3 (CĐ) hoặc x = 1 (CT). Vậy hoành độ điểm cực tiểu là 1.', 0.50, 'Vận dụng', 21),
(11, 'short_answer', 'Một xạ thủ bắn 2 phát đạn độc lập vào bia. Biết xác suất bắn trúng bia ở mỗi phát là 0.7. Tính xác suất để xạ thủ bắn trúng bia ít nhất 1 phát.', NULL, NULL, NULL, NULL, '0.91', 'P = 1 - P(cả 2 phát đều trượt) = 1 - 0.3 × 0.3 = 0.91.', 0.50, 'Vận dụng', 22),
(12, 'mcq', 'Choose the word whose underlined part differs from the other three in pronunciation: A. clean(ed)  B. play(ed)  C. watch(ed)  D. stay(ed)', 'stayed', 'played', 'watched', 'cleaned', 'C', '''-ed'' sau âm vô thanh /tʃ/ (watch) phát âm là /t/; các từ còn lại phát âm là /d/.', 0.25, 'Nhận biết', 1),
(12, 'mcq', 'Choose the word whose underlined part differs in pronunciation: A. h(ou)r  B. h(ou)se  C. m(ou)se  D. cl(ou)d', 'cloud', 'mouse', 'hour', 'house', 'C', '''hour'' đọc là /ˈaʊə(r)/ (âm h câm, nguyên âm /aʊə/), còn lại /aʊ/.', 0.25, 'Nhận biết', 2),
(12, 'mcq', 'Choose the word that differs from the other three in the position of primary stress:', 'beautiful', 'popular', 'important', 'dangerous', 'C', '''important'' nhấn âm 2; 3 từ còn lại nhấn âm 1.', 0.25, 'Nhận biết', 3),
(12, 'mcq', 'Choose the word that differs from the other three in the position of primary stress:', 'teacher', 'doctor', 'engineer', 'student', 'C', '''engineer'' nhấn âm 3; 3 từ còn lại nhấn âm 1.', 0.25, 'Nhận biết', 4),
(12, 'mcq', 'She ______ in Hanoi since she graduated from university in 2020.', 'is living', 'has lived', 'lives', 'lived', 'B', 'Dấu hiệu ''since + mốc quá khứ'' dùng thì hiện tại hoàn thành (has lived).', 0.25, 'Nhận biết', 5),
(12, 'mcq', 'If it ______ tomorrow, we will cancel the outdoor picnic.', 'rains', 'had rained', 'will rain', 'rained', 'A', 'Câu điều kiện loại 1: If + S + V(hiện tại đơn), S + will + V.', 0.25, 'Nhận biết', 6),
(12, 'mcq', 'The book ______ I borrowed from the library yesterday is very interesting.', 'which', 'who', 'whom', 'whose', 'A', 'Thay thế cho danh từ chỉ vật ''The book'' ở vị trí tân ngữ dùng ''which''.', 0.25, 'Nhận biết', 7),
(12, 'mcq', 'He is interested ______ learning foreign languages to broaden his horizons.', 'in', 'with', 'on', 'at', 'A', 'Cấu trúc ''be interested in + V-ing/N'': hứng thú với việc gì.', 0.25, 'Nhận biết', 8),
(12, 'mcq', 'My father stopped ______ five years ago for the sake of his health.', 'smoked', 'to smoke', 'smoking', 'smoke', 'C', '''stop + V-ing'': dừng hẳn việc đang làm (bỏ thuốc lá).', 0.25, 'Thông hiểu', 9),
(12, 'mcq', 'A new hospital ______ in our neighborhood next month.', 'is building', 'built', 'will build', 'will be built', 'D', 'Câu bị động thì tương lai đơn: will be + V3/ed.', 0.25, 'Thông hiểu', 10),
(12, 'mcq', 'The more carefully you prepare for the exam, ______ results you will get.', 'the best', 'better', 'best', 'the better', 'D', 'So sánh kép: The + so sánh hơn ..., the + so sánh hơn ... (''good'' → ''better'').', 0.25, 'Thông hiểu', 11),
(12, 'mcq', 'You have never been to Da Nang before, ______?', 'haven''t you', 'did you', 'have you', 'do you', 'C', 'Câu hỏi đuôi với ''never'' (mang nghĩa phủ định) ở thì hiện tại hoàn thành → đuôi khẳng định ''have you''.', 0.25, 'Thông hiểu', 12),
(12, 'mcq', 'We should ______ plastic bags with reusable cloth bags to protect the environment.', 'refuse', 'replace', 'reduce', 'remove', 'B', '''replace A with B'': thay thế A bằng B.', 0.25, 'Thông hiểu', 13),
(12, 'mcq', 'She had to ______ the meeting because of a sudden family emergency.', 'put on', 'take off', 'call off', 'turn up', 'C', '''call off'' = cancel (hủy bỏ).', 0.25, 'Vận dụng', 14),
(12, 'mcq', '______ the heavy rain, the football match took place as scheduled.', 'Despite', 'Because of', 'Because', 'Although', 'A', '''Despite + cụm danh từ (the heavy rain)'' = mặc dù.', 0.25, 'Thông hiểu', 15),
(12, 'mcq', 'Hardly ______ the station when the train left.', 'did we reach', 'we had reached', 'we reached', 'had we reached', 'D', 'Đảo ngữ: Hardly + had + S + V3/ed + when + S + V2/ed.', 0.25, 'Vận dụng', 16),
(12, 'mcq', 'Mark the word CLOSEST in meaning to ''enormous'': The company made an enormous profit last year.', 'huge', 'average', 'tiny', 'modest', 'A', '''enormous'' = khổng lồ, to lớn = ''huge''.', 0.25, 'Nhận biết', 17),
(12, 'mcq', 'Mark the word OPPOSITE in meaning to ''temporary'': He is looking for a temporary job during the summer.', 'seasonal', 'permanent', 'brief', 'short-term', 'B', 'Trái nghĩa với ''temporary'' (tạm thời) là ''permanent'' (lâu dài).', 0.25, 'Thông hiểu', 18),
(12, 'mcq', 'Find the mistake: ''Each of the students (A) have (B) to submit their (C) assignment before (D) Friday.''', 'have', 'students', 'their', 'before', 'A', 'Chủ ngữ ''Each of + N(số nhiều)'' chia động từ số ít → ''has''.', 0.25, 'Thông hiểu', 19),
(12, 'mcq', 'Find the mistake: ''Yesterday, I (A) go to the (B) bookstore to buy (C) some reference (D) books.''', 'books', 'some', 'go', 'bookstore', 'C', 'Có ''Yesterday'' → phải dùng quá khứ đơn ''went''.', 0.25, 'Nhận biết', 20),
(12, 'mcq', 'Tom: ''Thank you very much for helping me with the project.'' — Mary: ''______''', 'Yes, I''d love to.', 'It''s a pity.', 'You''re welcome.', 'Never mind.', 'C', 'Đáp lại lời cảm ơn lịch sự: ''You''re welcome.''', 0.25, 'Nhận biết', 21),
(12, 'mcq', 'Lan: ''Would you like to join us for dinner tonight?'' — Hoa: ''______''', 'Yes, I''d love to.', 'Not at all.', 'You''re right.', 'Congratulations!', 'A', 'Đáp lại lời mời lịch sự: ''Yes, I''d love to.''', 0.25, 'Nhận biết', 22),
(12, 'mcq', 'Choose the sentence that best combines: ''She was very tired. She finished all her homework before going to bed.''', 'Although she was very tired, she finished all her homework before going to bed.', 'She was too tired to finish her homework.', 'Because she was very tired, she finished all her homework.', 'Despite she was very tired, she finished her homework.', 'A', 'Hai mệnh đề tương phản dùng ''Although + clause''. (''Despite'' không đi với mệnh đề).', 0.25, 'Thông hiểu', 23),
(12, 'mcq', 'Choose the sentence closest in meaning: ''I haven''t seen my cousin for three years.''', 'The last time I saw my cousin was three years ago.', 'I didn''t see my cousin since three years.', 'I have seen my cousin three years ago.', 'I last saw my cousin for three years.', 'A', 'S + haven''t + V3 + for + time ⇔ The last time + S + V2 + was + time + ago.', 0.25, 'Thông hiểu', 24),
(12, 'mcq', 'Choose the best arrangement of utterances for a dialogue: (a) ''Hi, Anna! How was your weekend?'' (b) ''It was great! I went hiking with my family.'' (c) ''That sounds awesome!''', 'a - b - c', 'b - a - c', 'a - c - b', 'c - b - a', 'A', 'Mở đầu hỏi thăm (a) → trả lời (b) → phản hồi khen ngợi (c).', 0.25, 'Nhận biết', 25),
(12, 'mcq', '[Cloze - Q26] Volunteers play a vital (26) ______ in supporting local communities.', 'role', 'work', 'partly', 'rule', 'A', 'Cụm cố định ''play a vital role in'': đóng vai trò thiết yếu.', 0.25, 'Thông hiểu', 26),
(12, 'mcq', '[Cloze - Q27] Many young people participate in charity activities to help (27) ______ elderly and disadvantaged children.', 'the', 'an', 'a', 'no article', 'A', '''the + adj'' (the elderly) chỉ một nhóm người.', 0.25, 'Thông hiểu', 27),
(12, 'mcq', '[Cloze - Q28] Not only do these activities benefit others, (28) ______ they also help volunteers develop soft skills.', 'or', 'so', 'but', 'and', 'C', 'Cấu trúc ''Not only ... but also ...''.', 0.25, 'Nhận biết', 28),
(12, 'mcq', '[Cloze - Q29] Teamwork and communication are among the most valuable skills (29) ______ they gain.', 'who', 'where', 'that', 'whom', 'C', 'Mệnh đề quan hệ thay cho ''skills'' dùng ''that'' hoặc ''which''.', 0.25, 'Nhận biết', 29),
(12, 'mcq', '[Cloze - Q30] Therefore, schools often encourage students to (30) ______ in community service.', 'do', 'make', 'take', 'engage', 'D', '''engage in'' = tham gia vào.', 0.25, 'Thông hiểu', 30),
(12, 'mcq', '[Reading 1 - Q31] Passage: ''Urban green spaces, such as parks and community gardens, offer numerous benefits to city residents. They improve air quality, reduce the urban heat island effect, and provide areas for physical exercise and relaxation. Studies also show that spending time in nature lowers stress levels and boosts mental well-being.'' What is the main idea of the passage?', 'The benefits of urban green spaces for city residents.', 'Why people prefer living in the countryside.', 'How to build a community garden.', 'The causes of air pollution in big cities.', 'A', 'Đoạn văn tập trung nêu các lợi ích của không gian xanh đô thị đối với cư dân.', 0.25, 'Thông hiểu', 31),
(12, 'mcq', '[Reading 1 - Q32] According to the passage, urban green spaces help reduce ______.', 'housing prices', 'traffic congestion', 'noise from factories', 'the urban heat island effect', 'D', 'Thông tin trực tiếp: ''reduce the urban heat island effect''.', 0.25, 'Nhận biết', 32),
(12, 'mcq', '[Reading 1 - Q33] The word ''They'' in sentence 2 refers to ______.', 'studies', 'numerous benefits', 'urban green spaces', 'city residents', 'C', '''They'' thay thế cho chủ ngữ ''Urban green spaces'' ở câu trước.', 0.25, 'Thông hiểu', 33),
(12, 'mcq', '[Reading 1 - Q34] According to studies mentioned, spending time in nature helps ______.', 'lower stress levels', 'increase working hours', 'save money on travel', 'improve computer skills', 'A', 'Thông tin trực tiếp: ''lowers stress levels and boosts mental well-being''.', 0.25, 'Nhận biết', 34),
(12, 'mcq', '[Reading 1 - Q35] Which of the following is NOT mentioned as an example of urban green spaces?', 'Shopping malls', 'Parks', 'Community gardens', 'Areas with nature', 'A', 'Đoạn văn chỉ nhắc đến ''parks and community gardens''.', 0.25, 'Nhận biết', 35),
(12, 'mcq', '[Reading 2 - Q36] Passage: ''Artificial intelligence (AI) is transforming modern education. Adaptive learning platforms analyze each student''s strengths and weaknesses to customize lessons accordingly. Meanwhile, teachers can use AI tools to automate grading and administrative tasks, freeing up more time for direct mentoring. However, experts warn that over-reliance on AI may weaken students'' critical thinking if not guided properly.'' How do adaptive learning platforms help students?', 'By limiting students'' access to the internet.', 'By customizing lessons based on individual strengths and weaknesses.', 'By grading only multiple-choice tests.', 'By replacing all human teachers in classrooms.', 'B', 'Thông tin: ''analyze each student''s strengths and weaknesses to customize lessons accordingly''.', 0.25, 'Thông hiểu', 36),
(12, 'mcq', '[Reading 2 - Q37] What benefit do teachers get from AI tools according to the passage?', 'More time for direct mentoring.', 'Fewer students in each class.', 'Shorter school semesters.', 'Higher salaries from schools.', 'A', 'AI giúp tự động hóa chấm bài, ''freeing up more time for direct mentoring''.', 0.25, 'Nhận biết', 37),
(12, 'mcq', '[Reading 2 - Q38] The word ''automate'' in the passage is closest in meaning to ______.', 'abolish', 'delay', 'complicate', 'make automatic', 'D', '''automate'' = tự động hóa.', 0.25, 'Thông hiểu', 38),
(12, 'mcq', '[Reading 2 - Q39] What concern do experts express about AI in education?', 'AI tools are too expensive for all schools.', 'Over-reliance on AI might weaken critical thinking.', 'Students will stop attending school.', 'Teachers refuse to learn new technology.', 'B', 'Thông tin: ''over-reliance on AI may weaken students'' critical thinking''.', 0.25, 'Thông hiểu', 39),
(12, 'mcq', '[Reading 2 - Q40] What is the tone of the passage regarding AI in education?', 'Indifferent.', 'Completely negative.', 'Balanced (mentioning both benefits and a caution).', 'Humorous and sarcastic.', 'C', 'Bài viết nêu cả lợi ích và cảnh báo của chuyên gia → cân bằng, khách quan.', 0.25, 'Vận dụng', 40),
(13, 'mcq', 'Choose the word whose underlined part differs in pronunciation: A. book(s)  B. cat(s)  C. pen(s)  D. cup(s)', 'books', 'pens', 'cups', 'cats', 'B', '''-s'' sau âm hữu thanh /n/ (pen) phát âm là /z/; sau /k, t, p/ phát âm là /s/.', 0.25, 'Nhận biết', 1),
(13, 'mcq', 'Choose the word whose underlined part differs in pronunciation: A. m(a)ke  B. l(a)te  C. f(a)ce  D. h(a)t', 'late', 'make', 'face', 'hat', 'D', '''hat'' đọc là /æ/, 3 từ còn lại đọc là /eɪ/.', 0.25, 'Nhận biết', 2),
(13, 'mcq', 'Choose the word that differs in primary stress:', 'visit', 'travel', 'discover', 'listen', 'C', '''discover'' nhấn âm 2; các từ còn lại nhấn âm 1.', 0.25, 'Nhận biết', 3),
(13, 'mcq', 'Choose the word that differs in primary stress:', 'technology', 'experience', 'university', 'environment', 'C', '''university'' nhấn âm 3; 3 từ còn lại nhấn âm 2.', 0.25, 'Thông hiểu', 4),
(13, 'mcq', 'When I arrived at the party, everyone ______ happily.', 'danced', 'is dancing', 'has danced', 'was dancing', 'D', 'Hành động đang diễn ra (was dancing) khi một hành động khác xen vào (arrived).', 0.25, 'Nhận biết', 5),
(13, 'mcq', 'If she ______ harder, she would have passed the entrance exam.', 'had studied', 'studies', 'would study', 'studied', 'A', 'Câu điều kiện loại 3: If + S + had + V3/ed, S + would have + V3/ed.', 0.25, 'Thông hiểu', 6),
(13, 'mcq', 'The woman ______ son won the first prize is our English teacher.', 'whom', 'who', 'which', 'whose', 'D', 'Chỉ sở hữu trước danh từ ''son'' dùng ''whose''.', 0.25, 'Nhận biết', 7),
(13, 'mcq', 'We are looking forward ______ from you soon.', 'hearing', 'hear', 'to hear', 'to hearing', 'D', 'Cấu trúc ''look forward to + V-ing'': mong đợi điều gì.', 0.25, 'Thông hiểu', 8),
(13, 'mcq', 'It is essential that every student ______ the school regulations.', 'to obey', 'obeyed', 'obey', 'obeys', 'C', 'Thức giả định: It is essential that + S + V(nguyên thể không to).', 0.25, 'Vận dụng', 9),
(13, 'mcq', 'By the end of this year, they ______ the bridge across the river.', 'have completed', 'completed', 'will complete', 'will have completed', 'D', '''By the end of + mốc tương lai'' dùng tương lai hoàn thành (will have + V3/ed).', 0.25, 'Vận dụng', 10),
(13, 'mcq', 'This smartphone is ______ than the one I bought last year.', 'more expensive', 'expensiver', 'as expensive', 'most expensive', 'A', 'So sánh hơn với tính từ dài dùng ''more + adj + than''.', 0.25, 'Nhận biết', 11),
(13, 'mcq', 'Let''s go for a walk in the park, ______?', 'shall we', 'will we', 'don''t we', 'do we', 'A', 'Câu hỏi đuôi của ''Let''s ...'' luôn là ''shall we''.', 0.25, 'Nhận biết', 12),
(13, 'mcq', 'Good time management helps students ______ stress before final exams.', 'reduce', 'create', 'ignore', 'increase', 'A', '''reduce stress'': giảm căng thẳng.', 0.25, 'Nhận biết', 13),
(13, 'mcq', 'Don''t forget to ______ the lights before leaving the classroom.', 'turn up', 'give up', 'turn off', 'look after', 'C', '''turn off'': tắt (đèn, thiết bị điện).', 0.25, 'Nhận biết', 14),
(13, 'mcq', '______ she worked very hard, she didn''t get the promotion.', 'In spite of', 'Although', 'Because', 'Despite', 'B', '''Although + mệnh đề'' diễn tả sự nhượng bộ.', 0.25, 'Nhận biết', 15),
(13, 'mcq', 'Not until midnight ______ home from the trip.', 'did they return', 'had they returned', 'they returned', 'they had returned', 'A', 'Đảo ngữ: Not until + mốc thời gian + trợ động từ + S + V.', 0.25, 'Vận dụng', 16),
(13, 'mcq', 'Mark the word CLOSEST in meaning to ''vital'': Clean water is vital for human survival.', 'optional', 'essential', 'useless', 'harmful', 'B', '''vital'' = thiết yếu = ''essential''.', 0.25, 'Thông hiểu', 17),
(13, 'mcq', 'Mark the word OPPOSITE in meaning to ''scarce'': Fresh water has become scarce in this region.', 'limited', 'rare', 'abundant', 'insufficient', 'C', 'Trái nghĩa với ''scarce'' (khan hiếm) là ''abundant'' (dồi dào).', 0.25, 'Thông hiểu', 18),
(13, 'mcq', 'Find the mistake: ''Neither Lan nor her friends (A) was (B) present at (C) the ceremony (D) yesterday.''', 'yesterday', 'friends', 'was', 'at', 'C', 'Cấu trúc ''Neither A nor B'', động từ chia theo B (''her friends'' - số nhiều) → ''were''.', 0.25, 'Vận dụng', 19),
(13, 'mcq', 'Find the mistake: ''The film was (A) so bored (B) that we left the (C) cinema before (D) it ended.''', 'bored', 'so', 'cinema', 'it', 'A', 'Miêu tả tính chất của bộ phim dùng tính từ đuôi -ing: ''boring''.', 0.25, 'Thông hiểu', 20),
(13, 'mcq', 'Nam: ''I''ve just won a scholarship to study abroad!'' — Binh: ''______''', 'Congratulations!', 'What a pity!', 'Never mind.', 'I''m sorry to hear that.', 'A', 'Chúc mừng thành công dùng ''Congratulations!''.', 0.25, 'Nhận biết', 21),
(13, 'mcq', 'Waiter: ''Would you like tea or coffee?'' — Customer: ''______''', 'You''re welcome.', 'Coffee, please.', 'Yes, I do.', 'No, thanks.', 'B', 'Câu hỏi lựa chọn ''or'' cần chọn một phương án cụ thể.', 0.25, 'Nhận biết', 22),
(13, 'mcq', 'Closest in meaning: ''She started learning English five years ago.''', 'She stopped learning English five years ago.', 'She learned English in five years.', 'She hasn''t learned English for five years.', 'She has been learning English for five years.', 'D', 'started V-ing + time + ago ⇔ has/have been V-ing + for + time.', 0.25, 'Thông hiểu', 23),
(13, 'mcq', 'Closest in meaning: ''It''s a pity I can''t speak French fluently.''', 'If only I couldn''t speak French fluently.', 'I regret to speak French fluently.', 'I wish I could speak French fluently.', 'I wish I can speak French fluently.', 'C', 'Câu ước ở hiện tại: S + wish + S + could + V.', 0.25, 'Thông hiểu', 24),
(13, 'mcq', 'Arrange the dialogue: (a) ''Excuse me, could you tell me the way to the post office?'' (b) ''Go straight ahead and turn left at the traffic lights.'' (c) ''Thank you so much!''', 'a - b - c', 'a - c - b', 'c - a - b', 'b - a - c', 'A', 'Hỏi đường (a) → chỉ đường (b) → cảm ơn (c).', 0.25, 'Nhận biết', 25),
(13, 'mcq', '[Cloze - Q26] Reading books daily is a wonderful (26) ______ that brings lasting benefits.', 'habitat', 'hobbyist', 'habit', 'happening', 'C', '''a wonderful habit'': một thói quen tuyệt vời.', 0.25, 'Nhận biết', 26),
(13, 'mcq', '[Cloze - Q27] Firstly, reading helps expand our vocabulary and (27) ______ our writing skills.', 'improvement', 'improving', 'improve', 'improved', 'C', 'Cấu trúc song song: expand ... and improve ...', 0.25, 'Thông hiểu', 27),
(13, 'mcq', '[Cloze - Q28] Secondly, it stimulates our imagination and allows us to explore different cultures (28) ______ leaving home.', 'without', 'by', 'from', 'with', 'A', '''without + V-ing'': mà không cần làm gì.', 0.25, 'Thông hiểu', 28),
(13, 'mcq', '[Cloze - Q29] Moreover, people (29) ______ read regularly often have better concentration.', 'which', 'whom', 'whose', 'who', 'D', 'Thay thế cho ''people'' làm chủ ngữ dùng ''who''.', 0.25, 'Nhận biết', 29),
(13, 'mcq', '[Cloze - Q30] In short, spending just 20 minutes a day with a good book can make a big (30) ______ to your life.', 'effect', 'difference', 'result', 'change', 'B', 'Cụm cố định ''make a big difference'': tạo ra sự khác biệt lớn.', 0.25, 'Thông hiểu', 30),
(13, 'mcq', '[Reading 1 - Q31] Passage: ''Solar energy is one of the cleanest and most abundant renewable energy sources on Earth. Solar panels convert sunlight directly into electricity without emitting greenhouse gases. Although the initial installation cost can be high, solar power significantly reduces monthly electricity bills in the long run.'' What is the passage mainly about?', 'The history of electricity in Europe.', 'Why fossil fuels are cheaper than solar energy.', 'How to manufacture solar panels.', 'Solar energy as a clean and cost-effective renewable source.', 'D', 'Đoạn văn nói về năng lượng mặt trời: sạch, dồi dào và tiết kiệm chi phí dài hạn.', 0.25, 'Thông hiểu', 31),
(13, 'mcq', '[Reading 1 - Q32] What do solar panels convert sunlight into?', 'Greenhouse gases', 'Electricity', 'Fossil fuels', 'Heat only', 'B', 'Thông tin: ''convert sunlight directly into electricity''.', 0.25, 'Nhận biết', 32),
(13, 'mcq', '[Reading 1 - Q33] According to the passage, what is a disadvantage of solar power?', 'Limited availability of sunlight on Earth.', 'Short lifespan of sunlight.', 'High greenhouse gas emissions.', 'High initial installation cost.', 'D', 'Thông tin: ''the initial installation cost can be high''.', 0.25, 'Nhận biết', 33),
(13, 'mcq', '[Reading 1 - Q34] The phrase ''in the long run'' means ______.', 'only for one month', 'during a race', 'over a long period of time', 'at the very beginning', 'C', '''in the long run'' = về lâu dài.', 0.25, 'Thông hiểu', 34),
(13, 'mcq', '[Reading 1 - Q35] Which statement is TRUE according to the passage?', 'Solar panels only work indoors.', 'Solar power increases monthly electricity bills.', 'Solar energy is a non-renewable energy source.', 'Solar panels do not emit greenhouse gases when generating power.', 'D', 'Thông tin: ''without emitting greenhouse gases''.', 0.25, 'Thông hiểu', 35),
(13, 'mcq', '[Reading 2 - Q36] Passage: ''Remote work has become increasingly common since the rise of high-speed internet and cloud collaboration tools. Many employees appreciate the flexibility to balance work and personal life, as well as the time saved from daily commuting. However, remote workers sometimes face feelings of isolation and find it harder to separate work hours from rest time. Companies are now adopting hybrid models that combine office days with home days.'' Why do many employees appreciate remote work?', 'It guarantees automatic promotions.', 'It offers flexibility and saves commuting time.', 'It eliminates the need for internet access.', 'It requires working longer hours.', 'B', 'Thông tin: ''flexibility to balance work and personal life, as well as the time saved from daily commuting''.', 0.25, 'Thông hiểu', 36),
(13, 'mcq', '[Reading 2 - Q37] What challenge do remote workers sometimes face?', 'Lack of cloud tools.', 'Too much commuting.', 'Feelings of isolation.', 'No rest days.', 'C', 'Thông tin: ''face feelings of isolation''.', 0.25, 'Nhận biết', 37),
(13, 'mcq', '[Reading 2 - Q38] What does a ''hybrid model'' mean in the passage?', 'Hiring only freelance workers.', 'Closing all physical offices permanently.', 'Combining office days with working from home.', 'Working 24 hours a day.', 'C', 'Thông tin: ''combine office days with home days''.', 0.25, 'Thông hiểu', 38),
(13, 'mcq', '[Reading 2 - Q39] The word ''separate'' is closest in meaning to ______.', 'connect', 'divide', 'combine', 'merge', 'B', '''separate'' = tách biệt = ''divide''.', 0.25, 'Thông hiểu', 39),
(13, 'mcq', '[Reading 2 - Q40] What has enabled remote work to become common?', 'High-speed internet and cloud collaboration tools.', 'Cheaper public transportation.', 'Traditional paper mail.', 'Longer summer vacations.', 'A', 'Thông tin ở câu đầu tiên của đoạn văn.', 0.25, 'Nhận biết', 40),
(14, 'mcq', 'Choose the word whose underlined part differs in pronunciation: A. stopp(ed)  B. laugh(ed)  C. miss(ed)  D. need(ed)', 'needed', 'stopped', 'laughed', 'missed', 'A', '''needed'' có ''-ed'' phát âm là /ɪd/ (sau âm /d/); 3 từ còn lại phát âm là /t/.', 0.25, 'Nhận biết', 1),
(14, 'mcq', 'Choose the word whose underlined part differs in pronunciation: A. ch(air)  B. f(air)  C. p(air)  D. h(ear)', 'hear', 'chair', 'pair', 'fair', 'A', '''hear'' đọc là /ɪə(r)/; 3 từ còn lại đọc là /eə(r)/.', 0.25, 'Nhận biết', 2),
(14, 'mcq', 'Choose the word that differs in primary stress:', 'remember', 'develop', 'benefit', 'consider', 'C', '''benefit'' nhấn âm 1; 3 từ còn lại nhấn âm 2.', 0.25, 'Nhận biết', 3),
(14, 'mcq', 'Choose the word that differs in primary stress:', 'practical', 'personal', 'volunteer', 'confident', 'C', '''volunteer'' nhấn âm 3; 3 từ còn lại nhấn âm 1.', 0.25, 'Thông hiểu', 4),
(14, 'mcq', 'Listen! Someone ______ the piano in the next room.', 'has played', 'is playing', 'plays', 'played', 'B', 'Có ''Listen!'' diễn tả hành động đang xảy ra → hiện tại tiếp diễn.', 0.25, 'Nhận biết', 5),
(14, 'mcq', 'If I ______ you, I would apologize to her immediately.', 'was been', 'were', 'am', 'had been', 'B', 'Câu điều kiện loại 2: If I were you, ...', 0.25, 'Nhận biết', 6),
(14, 'mcq', 'The scientist ______ discovered this vaccine won the Nobel Prize.', 'which', 'whose', 'whom', 'who', 'D', 'Thay thế cho danh từ chỉ người ''The scientist'' làm chủ ngữ dùng ''who''.', 0.25, 'Nhận biết', 7),
(14, 'mcq', 'She is very proud ______ her daughter''s academic achievements.', 'of', 'with', 'on', 'in', 'A', 'Cấu trúc ''be proud of'': tự hào về.', 0.25, 'Nhận biết', 8),
(14, 'mcq', 'Remember ______ the door before you go to sleep.', 'lock', 'to lock', 'locking', 'locked', 'B', '''remember + to V'': nhớ phải làm gì (chưa làm).', 0.25, 'Thông hiểu', 9),
(14, 'mcq', 'This ancient temple ______ in the 11th century.', 'has built', 'built', 'is built', 'was built', 'D', 'Bị động quá khứ đơn (in the 11th century): was built.', 0.25, 'Nhận biết', 10),
(14, 'mcq', 'Mount Everest is ______ mountain in the world.', 'the highest', 'higher', 'highest', 'the most high', 'A', 'So sánh nhất với tính từ ngắn: the + adj-est.', 0.25, 'Nhận biết', 11),
(14, 'mcq', 'Nothing can stop us from achieving our goals, ______?', 'can''t it', 'can it', 'can''t they', 'can they', 'B', 'Chủ ngữ ''Nothing'' mang nghĩa phủ định và tương ứng đại từ ''it'' → ''can it''.', 0.25, 'Vận dụng', 12),
(14, 'mcq', 'Parents should ______ a good example for their children.', 'set', 'do', 'make', 'put', 'A', 'Collocation ''set a good example'': làm gương tốt.', 0.25, 'Thông hiểu', 13),
(14, 'mcq', 'He decided to ______ smoking after reading the doctor''s advice.', 'go on', 'take up', 'give up', 'look up', 'C', '''give up'': từ bỏ.', 0.25, 'Nhận biết', 14),
(14, 'mcq', '______ the traffic jam, we arrived at the airport on time.', 'Because', 'In spite of', 'Although', 'Even though', 'B', '''In spite of + cụm danh từ (the traffic jam)''.', 0.25, 'Thông hiểu', 15),
(14, 'mcq', 'Rarely ______ such a breathtaking sunset.', 'did I saw', 'have I seen', 'I saw', 'I have seen', 'B', 'Đảo ngữ với ''Rarely'' đứng đầu câu: Rarely + trợ động từ + S + V.', 0.25, 'Vận dụng', 16),
(14, 'mcq', 'Mark the word CLOSEST in meaning to ''assist'': Nurses assist doctors in taking care of patients.', 'help', 'ignore', 'criticize', 'prevent', 'A', '''assist'' = hỗ trợ, giúp đỡ = ''help''.', 0.25, 'Nhận biết', 17),
(14, 'mcq', 'Mark the word OPPOSITE in meaning to ''optimistic'': She remains optimistic about the future.', 'confident', 'pessimistic', 'hopeful', 'cheerful', 'B', 'Trái nghĩa với ''optimistic'' (lạc quan) là ''pessimistic'' (bi quan).', 0.25, 'Thông hiểu', 18),
(14, 'mcq', 'Find the mistake: ''The number of participants in the contest (A) have (B) increased significantly (C) this year (D).''', 'significantly', 'this year', 'have', 'participants', 'C', '''The number of + N(số nhiều)'' chia động từ số ít → ''has''.', 0.25, 'Vận dụng', 19),
(14, 'mcq', 'Find the mistake: ''She enjoys (A) to read (B) science fiction novels in her (C) free time (D).''', 'to read', 'free time', 'her', 'enjoys', 'A', '''enjoy + V-ing'' → ''reading''.', 0.25, 'Nhận biết', 20),
(14, 'mcq', 'Peter: ''What a lovely dress you are wearing!'' — Lisa: ''______''', 'Thank you. That''s very nice of you to say so.', 'Yes, please.', 'Not at all.', 'I don''t think so.', 'A', 'Đáp lại lời khen lịch sự: cảm ơn người khen.', 0.25, 'Nhận biết', 21),
(14, 'mcq', 'Student: ''May I open the window?'' — Teacher: ''______''', 'You''re welcome.', 'I''m fine, thank you.', 'Yes, please do.', 'See you later.', 'C', 'Đáp lại lời xin phép một cách đồng ý.', 0.25, 'Nhận biết', 22),
(14, 'mcq', 'Closest in meaning: ''He didn''t take an umbrella, so he got wet.''', 'If he takes an umbrella, he won''t get wet.', 'If he had taken an umbrella, he wouldn''t have gotten wet.', 'If he hadn''t taken an umbrella, he would have gotten wet.', 'If he took an umbrella, he wouldn''t get wet.', 'B', 'Trái với quá khứ dùng câu điều kiện loại 3.', 0.25, 'Thông hiểu', 23),
(14, 'mcq', 'Closest in meaning: ''''I will call you tomorrow,'' John said to me.''', 'John told me he will call me tomorrow.', 'John said me he would call me the next day.', 'John asked me if I would call him the next day.', 'John told me he would call me the next day.', 'D', 'Câu tường thuật lùi thì ''will → would'', ''tomorrow → the next day''.', 0.25, 'Thông hiểu', 24),
(14, 'mcq', 'Arrange the dialogue: (a) ''Would you like a cup of coffee?'' (b) ''Yes, please. With a little milk.'' (c) ''Here you are. Enjoy!''', 'a - c - b', 'b - a - c', 'c - b - a', 'a - b - c', 'D', 'Mời (a) → nhận lời (b) → đưa đồ uống (c).', 0.25, 'Nhận biết', 25),
(14, 'mcq', '[Cloze - Q26] Protecting biodiversity is crucial for maintaining the (26) ______ of ecosystems.', 'balance', 'balancing', 'unbalanced', 'balanced', 'A', 'Sau mạo từ ''the'' cần danh từ ''balance'' (sự cân bằng).', 0.25, 'Thông hiểu', 26),
(14, 'mcq', '[Cloze - Q27] Deforestation and illegal hunting have put many species (27) ______ risk of extinction.', 'in', 'on', 'at', 'by', 'C', 'Cụm cố định ''at risk of'': có nguy cơ bị.', 0.25, 'Thông hiểu', 27),
(14, 'mcq', '[Cloze - Q28] Governments need to enforce strict laws to (28) ______ endangered animals.', 'protect', 'ignore', 'hunt', 'destroy', 'A', '''protect endangered animals'': bảo vệ động vật có nguy cơ tuyệt chủng.', 0.25, 'Nhận biết', 28),
(14, 'mcq', '[Cloze - Q29] Every individual can also contribute (29) ______ reducing waste and recycling.', 'by', 'with', 'at', 'for', 'A', '''by + V-ing'': bằng cách làm gì.', 0.25, 'Nhận biết', 29),
(14, 'mcq', '[Cloze - Q30] Together, we can build a sustainable future for (30) ______ generations.', 'future', 'past', 'former', 'previous', 'A', '''future generations'': các thế hệ tương lai.', 0.25, 'Nhận biết', 30),
(14, 'mcq', '[Reading 1 - Q31] Passage: ''Sleep plays a critical role in memory consolidation and physical recovery. During deep sleep, the brain processes information learned during the day and clears out metabolic waste. Teenagers generally need 8 to 10 hours of sleep per night, yet many get far less due to late-night screen use.'' What happens during deep sleep?', 'Memory is permanently erased.', 'Teenagers watch screens for 8 to 10 hours.', 'The body stops all recovery processes.', 'The brain processes information and clears out waste.', 'D', 'Thông tin: ''the brain processes information learned during the day and clears out metabolic waste''.', 0.25, 'Thông hiểu', 31),
(14, 'mcq', '[Reading 1 - Q32] How many hours of sleep do teenagers generally need per night?', '6 hours', '4 to 5 hours', '8 to 10 hours', '12 to 14 hours', 'C', 'Thông tin trực tiếp: ''8 to 10 hours of sleep per night''.', 0.25, 'Nhận biết', 32),
(14, 'mcq', '[Reading 1 - Q33] Why do many teenagers get less sleep than needed?', 'Because of late-night screen use.', 'Because they sleep during classes.', 'Because they don''t have beds.', 'Because they exercise too much.', 'A', 'Thông tin: ''due to late-night screen use''.', 0.25, 'Nhận biết', 33),
(14, 'mcq', '[Reading 1 - Q34] The word ''critical'' is closest in meaning to ______.', 'crucial', 'harmless', 'minor', 'optional', 'A', '''critical'' = rất quan trọng = ''crucial''.', 0.25, 'Thông hiểu', 34),
(14, 'mcq', '[Reading 1 - Q35] Which is the best title for the passage?', 'The Importance of Sleep for Health and Learning', 'Types of Metabolic Waste', 'How to Buy a Better Smartphone', 'Why Teenagers Dislike School', 'A', 'Đoạn văn nói về vai trò của giấc ngủ đối với trí nhớ và hồi phục thể chất.', 0.25, 'Thông hiểu', 35),
(14, 'mcq', '[Reading 2 - Q36] Passage: ''Ecotourism focuses on responsible travel to natural areas that conserves the environment and improves the well-being of local people. Unlike mass tourism, which often damages fragile habitats, ecotourism encourages small groups, eco-friendly accommodations, and respect for local traditions. Revenue generated from ecotourism often funds wildlife conservation projects.'' What is a key goal of ecotourism?', 'Increasing the number of mass tourists.', 'Conserving the environment and supporting local communities.', 'Replacing local traditions with modern lifestyles.', 'Building large luxury resorts in forests.', 'B', 'Thông tin ngay câu đầu tiên của bài.', 0.25, 'Thông hiểu', 36),
(14, 'mcq', '[Reading 2 - Q37] How does mass tourism differ from ecotourism according to the passage?', 'Mass tourism often damages fragile habitats.', 'Mass tourism uses smaller groups.', 'Mass tourism funds all wildlife projects.', 'Mass tourism avoids natural areas completely.', 'A', 'Thông tin: ''mass tourism, which often damages fragile habitats''.', 0.25, 'Nhận biết', 37),
(14, 'mcq', '[Reading 2 - Q38] What does revenue from ecotourism often fund?', 'Fast food chains.', 'Highway construction.', 'Factory expansion.', 'Wildlife conservation projects.', 'D', 'Thông tin: ''often funds wildlife conservation projects''.', 0.25, 'Nhận biết', 38),
(14, 'mcq', '[Reading 2 - Q39] The word ''fragile'' means ______.', 'dangerous', 'easily damaged', 'extremely strong', 'artificial', 'B', '''fragile'' = mong manh, dễ bị tổn thương/phá hủy.', 0.25, 'Thông hiểu', 39),
(14, 'mcq', '[Reading 2 - Q40] Which of the following is encouraged by ecotourism?', 'Single-use plastic bottles.', 'Large crowds in national parks.', 'Small groups and eco-friendly accommodations.', 'Ignoring local customs.', 'C', 'Thông tin trực tiếp trong câu 2.', 0.25, 'Nhận biết', 40),
(15, 'mcq', 'Trong hệ SI, đơn vị của nhiệt dung riêng là:', 'J/K', 'J/(mol.K)', 'J/(kg.K)', 'J/kg', 'C', 'Q = m.c.ΔT ⇒ c = Q/(m.ΔT) có đơn vị J/(kg.K).', 0.25, 'Nhận biết', 1),
(15, 'mcq', 'Nhiệt độ 27°C tương ứng với nhiệt độ tuyệt đối trong thang Kelvin là:', '373 K', '300 K', '246 K', '273 K', 'B', 'T(K) = t(°C) + 273 = 27 + 273 = 300 K.', 0.25, 'Nhận biết', 2),
(15, 'mcq', 'Quá trình chuyển từ thể lỏng sang thể khí xảy ra ở cả bề mặt và trong lòng chất lỏng gọi là:', 'Sự sôi', 'Sự ngưng tụ', 'Sự bay hơi', 'Sự nóng chảy', 'A', 'Sự sôi xảy ra ở cả bề mặt và trong lòng chất lỏng ở nhiệt độ xác định.', 0.25, 'Nhận biết', 3),
(15, 'mcq', 'Theo định luật Boyle, với một lượng khí lí tưởng xác định ở nhiệt độ không đổi thì:', 'Áp suất tỉ lệ nghịch với thể tích', 'Tích p/V không đổi', 'Áp suất không phụ thuộc thể tích', 'Áp suất tỉ lệ thuận với thể tích', 'A', 'p.V = hằng số khi T không đổi.', 0.25, 'Nhận biết', 4),
(15, 'mcq', 'Động năng trung bình của phân tử khí lí tưởng phụ thuộc trực tiếp vào:', 'Thể tích bình chứa', 'Hình dạng bình chứa', 'Nhiệt độ tuyệt đối T', 'Khối lượng bình chứa', 'C', 'W_đ = (3/2)kT chỉ phụ thuộc nhiệt độ tuyệt đối T.', 0.25, 'Nhận biết', 5),
(15, 'mcq', 'Đơn vị đo cảm ứng từ B là:', 'Weber (Wb)', 'Volt (V)', 'Tesla (T)', 'Henry (H)', 'C', 'Cảm ứng từ B đo bằng Tesla (T).', 0.25, 'Nhận biết', 6),
(15, 'mcq', 'Từ thông qua một khung dây diện tích S đặt trong từ trường đều B có công thức là (α là góc giữa vectơ pháp tuyến n và B):', 'Φ = B.S.sin(α)', 'Φ = B/S', 'Φ = B.S.tan(α)', 'Φ = B.S.cos(α)', 'D', 'Φ = B.S.cos(α).', 0.25, 'Nhận biết', 7),
(15, 'mcq', 'Suất điện động cảm ứng trong mạch kín tỉ lệ với:', 'Tốc độ biến thiên từ thông qua mạch', 'Độ lớn từ thông qua mạch', 'Diện tích của mạch', 'Điện trở của mạch', 'A', 'Định luật Faraday: e_c = -ΔΦ/Δt.', 0.25, 'Nhận biết', 8),
(15, 'mcq', 'Hạt nhân nguyên tử được cấu tạo từ:', 'Chỉ có proton', 'Neutron và electron', 'Proton và neutron', 'Proton và electron', 'C', 'Hạt nhân gồm các nucleon: proton và neutron.', 0.25, 'Nhận biết', 9),
(15, 'mcq', 'Số neutron có trong hạt nhân ²³₁₁Na là:', '34', '23', '11', '12', 'D', 'N = A - Z = 23 - 11 = 12.', 0.25, 'Nhận biết', 10),
(15, 'mcq', 'Tia phóng xạ nào sau đây là dòng các hạt nhân ⁴₂He?', 'Tia β⁻', 'Tia γ', 'Tia β⁺', 'Tia α', 'D', 'Tia α là dòng hạt nhân Heli (⁴₂He).', 0.25, 'Nhận biết', 11),
(15, 'mcq', 'Một con lắc lò xo dao động điều hòa với tần số góc ω = 10 rad/s và biên độ A = 4 cm. Tốc độ cực đại của vật là:', '20 cm/s', '40 cm/s', '2.5 cm/s', '400 cm/s', 'B', 'v_max = ωA = 10 × 4 = 40 cm/s.', 0.25, 'Thông hiểu', 12),
(15, 'mcq', 'Sóng cơ có tần số f = 50 Hz truyền với tốc độ v = 100 m/s. Bước sóng λ bằng:', '5000 m', '50 m', '0.5 m', '2 m', 'D', 'λ = v / f = 100 / 50 = 2 m.', 0.25, 'Thông hiểu', 13),
(15, 'mcq', 'Một khối khí nhận nhiệt lượng Q = 500 J và thực hiện công có độ lớn 200 J. Độ biến thiên nội năng ΔU của khí là:', '700 J', '300 J', '-700 J', '-300 J', 'B', 'Nhận nhiệt Q = +500 J, thực hiện công A = -200 J ⇒ ΔU = Q + A = 300 J.', 0.25, 'Thông hiểu', 14),
(15, 'mcq', 'Một khung dây phẳng diện tích S = 0.02 m² đặt vuông góc với đường sức từ của từ trường đều có B = 0.5 T. Từ thông qua khung dây bằng:', '25 Wb', '0.01 Wb', '0.1 Wb', '0 Wb', 'B', 'Vuông góc mặt phẳng khung ⇒ α = 0° ⇒ Φ = B.S = 0.5 × 0.02 = 0.01 Wb.', 0.25, 'Thông hiểu', 15),
(15, 'mcq', 'Đoạn dây dẫn thẳng dài l = 0.5 m mang dòng điện I = 4 A đặt vuông góc với từ trường đều có B = 0.2 T. Lực từ tác dụng lên đoạn dây có độ lớn:', '2.5 N', '0.04 N', '4 N', '0.4 N', 'D', 'F = B.I.l.sin(90°) = 0.2 × 4 × 0.5 = 0.4 N.', 0.25, 'Thông hiểu', 16),
(15, 'mcq', 'Một dòng điện xoay chiều có cường độ cực đại I₀ = 4√2 A. Cường độ hiệu dụng I bằng:', '8 A', '2√2 A', '4 A', '4√2 A', 'C', 'I = I₀ / √2 = 4√2 / √2 = 4 A.', 0.25, 'Nhận biết', 17),
(15, 'mcq', 'Chất phóng xạ có chu kì bán rã T = 10 ngày. Sau 20 ngày, phần trăm khối lượng chất phóng xạ còn lại so với ban đầu là:', '75%', '50%', '25%', '12.5%', 'C', 'Sau 2T: m = m₀ / 2² = 0.25 m₀ = 25%.', 0.25, 'Thông hiểu', 18),
(15, 'true_false', 'Cung cấp nhiệt lượng để đun nóng 2 kg nước (nhiệt dung riêng c = 4200 J/(kg.K)) từ 20°C lên 70°C.', 'a) Độ tăng nhiệt độ của nước là ΔT = 50 K.', 'b) Nhiệt lượng nước đã thu vào là 420 kJ.', 'c) Nếu dùng ấm điện công suất 1400 W (hiệu suất 100%) thì thời gian đun là 300 giây.', 'd) Nội năng của nước giảm đi trong quá trình đun nóng.', 'D,D,D,S', 'a) Đúng: 70 - 20 = 50°C = 50 K.
b) Đúng: Q = 2 × 4200 × 50 = 420000 J = 420 kJ.
c) Đúng: t = Q/P = 420000/1400 = 300 s.
d) Sai: Nước nhận nhiệt nên nội năng tăng.', 1.00, 'Thông hiểu', 19),
(15, 'true_false', 'Một lượng khí lí tưởng có thể tích 4 lít ở áp suất 2 atm và nhiệt độ 27°C (300 K).', 'a) Nếu giữ nhiệt độ không đổi và nén để thể tích còn 2 lít thì áp suất tăng lên 4 atm.', 'b) Nếu giữ thể tích không đổi và đun nóng đến 327°C (600 K) thì áp suất tăng gấp đôi.', 'c) Ở nhiệt độ 300 K, các phân tử khí đứng yên hoàn toàn.', 'd) Áp suất của chất khí tỉ lệ thuận với mật độ phân tử khí ở cùng nhiệt độ.', 'D,D,S,D', 'a) Đúng: p₁V₁ = p₂V₂ ⇒ p₂ = 4 atm.
b) Đúng: T₂ = 2T₁ ⇒ p₂ = 2p₁.
c) Sai: Phân tử khí chuyển động hỗn loạn không ngừng.
d) Đúng: p = n k T.', 1.00, 'Thông hiểu', 20),
(15, 'true_false', 'Một khung dây dẫn tròn gồm N = 100 vòng, diện tích mỗi vòng S = 0.01 m², đặt trong từ trường đều sao cho vectơ cảm ứng từ vuông góc với mặt phẳng khung. Cho cảm ứng từ giảm đều từ 0.6 T về 0.2 T trong thời gian 0.1 s.', 'a) Từ thông ban đầu qua mỗi vòng dây là 0.006 Wb.', 'b) Độ biến thiên từ thông qua toàn bộ khung dây có độ lớn là 0.4 Wb.', 'c) Độ lớn suất điện động cảm ứng xuất hiện trong khung là 4 V.', 'd) Dòng điện cảm ứng sinh ra có chiều cùng chiều từ trường ban đầu để tăng cường sự giảm.', 'D,D,D,D', 'a) Đúng: Φ₁ = 0.6 × 0.01 = 0.006 Wb.
b) Đúng: |ΔΦ_toàn_phần| = N.|ΔB|.S = 100 × 0.4 × 0.01 = 0.4 Wb.
c) Đúng: |e_c| = 0.4 / 0.1 = 4 V.
d) Đúng: Theo định luật Lenz, từ trường cảm ứng chống lại sự giảm của từ thông ban đầu nên cùng chiều B₀.', 1.00, 'Vận dụng', 21),
(15, 'true_false', 'Cho phản ứng nhiệt hạch tổng hợp Heli: ²₁H + ³₁H → ⁴₂He + ¹₀n. Biết khối lượng các hạt: m(²₁H) = 2.0135 u; m(³₁H) = 3.0160 u; m(⁴₂He) = 4.0015 u; m(n) = 1.0087 u và 1 u.c² = 931.5 MeV.', 'a) Phản ứng trên là phản ứng tỏa năng lượng.', 'b) Tổng khối lượng các hạt trước phản ứng là 5.0295 u.', 'c) Độ hụt khối của phản ứng là Δm = 0.0193 u.', 'd) Năng lượng tỏa ra của mỗi phản ứng xấp xỉ 17.98 MeV.', 'D,D,D,D', 'a) Đúng.
b) Đúng: 2.0135 + 3.0160 = 5.0295 u.
c) Đúng: Δm = 5.0295 - (4.0015 + 1.0087) = 0.0193 u.
d) Đúng: ΔE = 0.0193 × 931.5 = 17.97795 ≈ 17.98 MeV.', 1.00, 'Vận dụng', 22),
(15, 'short_answer', 'Một bình kín dung tích 0.01 m³ chứa 2 mol khí lí tưởng ở nhiệt độ 27°C (300 K). Lấy R = 8.31 J/(mol.K). Tính áp suất của khối khí theo đơn vị kPa.', NULL, NULL, NULL, NULL, '498.6', 'p = nRT/V = (2 × 8.31 × 300)/0.01 = 498600 Pa = 498.6 kPa.', 0.25, 'Thông hiểu', 23),
(15, 'short_answer', 'Biết nhiệt nóng chảy riêng của nước đá ở 0°C là 334 kJ/kg. Tính nhiệt lượng cần thiết (theo đơn vị kJ) để làm nóng chảy hoàn toàn 0.5 kg nước đá ở 0°C.', NULL, NULL, NULL, NULL, '167', 'Q = λ.m = 334 × 0.5 = 167 kJ.', 0.25, 'Nhận biết', 24),
(15, 'short_answer', 'Một đài phát thanh phát sóng điện từ có tần số 100 MHz. Biết tốc độ truyền sóng điện từ trong chân không là 3×10⁸ m/s. Tính bước sóng của sóng này theo đơn vị mét.', NULL, NULL, NULL, NULL, '3', 'λ = c / f = (3×10⁸) / (100×10⁶) = 3 m.', 0.25, 'Nhận biết', 25),
(15, 'short_answer', 'Đoạn dây dẫn dài 0.25 m mang dòng điện 5 A đặt hợp với vectơ cảm ứng từ B = 0.4 T một góc 30°. Tính độ lớn lực từ tác dụng lên đoạn dây theo đơn vị Newton.', NULL, NULL, NULL, NULL, '0.25', 'F = B.I.l.sin(30°) = 0.4 × 5 × 0.25 × 0.5 = 0.25 N.', 0.25, 'Thông hiểu', 26),
(15, 'short_answer', 'Một máy biến áp lí tưởng có số vòng dây cuộn sơ cấp là 1000 vòng, cuộn thứ cấp là 200 vòng. Đặt vào hai đầu cuộn sơ cấp điện áp xoay chiều hiệu dụng 220 V. Tính điện áp hiệu dụng ở hai đầu cuộn thứ cấp (theo đơn vị V).', NULL, NULL, NULL, NULL, '44', 'U₂ = U₁.(N₂/N₁) = 220 × (200/1000) = 44 V.', 0.25, 'Thông hiểu', 27),
(15, 'short_answer', 'Một mẫu chất phóng xạ có chu kì bán rã T = 5 giờ. Sau thời gian 15 giờ kể từ thời điểm ban đầu, có bao nhiêu phần trăm số hạt nhân ban đầu đã bị phân rã?', NULL, NULL, NULL, NULL, '87.5', 't = 15 giờ = 3T ⇒ Số hạt còn lại N = N₀/2³ = 12.5% N₀ ⇒ Đã phân rã 87.5%.', 0.25, 'Vận dụng', 28),
(16, 'mcq', 'Trong thang nhiệt độ Celsius, điểm đóng băng của nước tinh khiết ở áp suất tiêu chuẩn 1 atm là:', '32°C', '0°C', '100°C', '-273°C', 'B', 'Mốc 0°C là nhiệt độ đóng băng của nước tinh khiết ở 1 atm.', 0.25, 'Nhận biết', 1),
(16, 'mcq', 'Nội năng của một vật phụ thuộc vào:', 'Chỉ khối lượng của vật', 'Độ cao của vật so với mặt đất', 'Nhiệt độ và thể tích của vật', 'Chỉ vận tốc của vật', 'C', 'Nội năng gồm tổng động năng (phụ thuộc T) và thế năng tương tác phân tử (phụ thuộc V).', 0.25, 'Nhận biết', 2),
(16, 'mcq', 'Trong quá trình đẳng áp của một lượng khí lí tưởng xác định, thể tích V:', 'Tỉ lệ nghịch với nhiệt độ tuyệt đối T', 'Tỉ lệ thuận với nhiệt độ t(°C)', 'Không đổi', 'Tỉ lệ thuận với nhiệt độ tuyệt đối T', 'D', 'Định luật Charles: V/T = hằng số.', 0.25, 'Nhận biết', 3),
(16, 'mcq', 'Lực tương tác giữa hai dòng điện thẳng song song cùng chiều là:', 'Lực vuông góc mặt phẳng chứa hai dây', 'Bằng không', 'Lực đẩy', 'Lực hút', 'D', 'Hai dòng điện song song cùng chiều hút nhau, ngược chiều đẩy nhau.', 0.25, 'Nhận biết', 4),
(16, 'mcq', 'Quy tắc xác định chiều dòng điện cảm ứng trong mạch kín là:', 'Định luật Lenz', 'Định luật Ohm', 'Định luật Charles', 'Định luật Boyle', 'A', 'Định luật Lenz xác định chiều dòng điện cảm ứng.', 0.25, 'Nhận biết', 5),
(16, 'mcq', 'Sóng điện từ là:', 'Sóng ngang, truyền được trong chân không', 'Không mang năng lượng', 'Sóng dọc, không truyền được trong chân không', 'Chỉ truyền trong chất rắn', 'A', 'Sóng điện từ là sóng ngang và truyền được trong chân không.', 0.25, 'Nhận biết', 6),
(16, 'mcq', 'Trong thí nghiệm Y-âng về giao thoa ánh sáng, khoảng vân i được tính bằng công thức:', 'i = λ / (aD)', 'i = λa / D', 'i = λD / a', 'i = aD / λ', 'C', 'Khoảng vân i = λD/a.', 0.25, 'Nhận biết', 7),
(16, 'mcq', 'Hạt nhân bền vững nhất trong tự nhiên nằm ở vùng số khối A khoảng:', 'Trên 250', '200 đến 240', '1 đến 4', '50 đến 80 (như Fe)', 'D', 'Năng lượng liên kết riêng lớn nhất ứng với hạt nhân có A ≈ 50–80.', 0.25, 'Nhận biết', 8),
(16, 'mcq', 'Trong phóng xạ β⁻, một neutron trong hạt nhân biến đổi thành:', 'Một proton, một electron và một phản neutrino', 'Chỉ một proton', 'Một hạt nhân Heli', 'Hai neutron', 'A', 'n → p + e⁻ + ν̄_e.', 0.25, 'Thông hiểu', 9),
(16, 'mcq', 'Chu kì dao động của con lắc lò xo (m, k) là:', 'T = 2π√(m/k)', 'T = (1/2π)√(k/m)', 'T = 2π√(k/m)', 'T = 2π√(l/g)', 'A', 'T = 2π√(m/k).', 0.25, 'Nhận biết', 10),
(16, 'mcq', 'Khi nén đẳng nhiệt một lượng khí lí tưởng từ thể tích 6 lít xuống còn 2 lít thì áp suất của khí sẽ:', 'Tăng lên 4 lần', 'Không đổi', 'Tăng lên 3 lần', 'Giảm đi 3 lần', 'C', 'p₁V₁ = p₂V₂ ⇒ V giảm 3 lần thì p tăng 3 lần.', 0.25, 'Thông hiểu', 11),
(16, 'mcq', 'Nhiệt lượng cần thiết để làm 100 g đồng (c = 380 J/(kg.K)) tăng nhiệt độ thêm 20°C là:', '7600 J', '760 J', '3800 J', '190 J', 'B', 'Q = 0.1 × 380 × 20 = 760 J.', 0.25, 'Thông hiểu', 12),
(16, 'mcq', 'Một khung dây diện tích 50 cm² đặt trong từ trường đều B = 0.4 T sao cho góc giữa đường sức từ và mặt phẳng khung là 30°. Từ thông qua khung bằng:', '0.02 Wb', '0.001 Wb', '0.002 Wb', '0.00173 Wb', 'B', 'Góc với mặt phẳng khung là 30° ⇒ góc với pháp tuyến α = 60° ⇒ Φ = 0.4 × 50×10⁻⁴ × cos(60°) = 0.001 Wb.', 0.25, 'Vận dụng', 13),
(16, 'mcq', 'Một vật dao động điều hòa có phương trình x = 6cos(4πt + π/3) cm. Chu kì dao động của vật là:', '4 s', '0.25 s', '0.5 s', '2 s', 'C', 'T = 2π / ω = 2π / (4π) = 0.5 s.', 0.25, 'Nhận biết', 14),
(16, 'mcq', 'Đặt điện áp xoay chiều u = 220√2 cos(100πt) V vào hai đầu điện trở thuần R = 44 Ω. Cường độ dòng điện hiệu dụng qua điện trở là:', '10 A', '5√2 A', '5 A', '2.5 A', 'C', 'U = 220 V ⇒ I = U/R = 220/44 = 5 A.', 0.25, 'Thông hiểu', 15),
(16, 'mcq', 'Hạt nhân ¹²₆C có độ hụt khối Δm = 0.0989 u. Lấy 1 u.c² = 931.5 MeV. Năng lượng liên kết riêng của hạt nhân này xấpỉ:', '7.68 MeV/nucleon', '92.13 MeV/nucleon', '12.00 MeV/nucleon', '15.35 MeV/nucleon', 'A', 'E_lk = 0.0989×931.5 ≈ 92.125 MeV ⇒ E_lkr = 92.125/12 ≈ 7.68 MeV/nucleon.', 0.25, 'Thông hiểu', 16),
(16, 'mcq', 'Một sóng dừng trên dây hai đầu cố định dài l = 1.2 m có 3 bó sóng. Bước sóng của sóng là:', '0.4 m', '2.4 m', '1.2 m', '0.8 m', 'D', 'l = k(λ/2) ⇒ 1.2 = 3×(λ/2) ⇒ λ = 0.8 m.', 0.25, 'Thông hiểu', 17),
(16, 'mcq', 'Trong thí nghiệm Y-âng, a = 1 mm, D = 2 m, λ = 0.5 μm. Khoảng vân giao thoa i bằng:', '0.5 mm', '2 mm', '1 mm', '0.25 mm', 'C', 'i = λD/a = (0.5×2)/1 = 1 mm.', 0.25, 'Thông hiểu', 18),
(16, 'true_false', 'Một xilanh chứa khí lí tưởng ở trạng thái (1): p₁ = 10⁵ Pa, V₁ = 3 lít, T₁ = 300 K. Đun nóng đẳng áp khí đến trạng thái (2) có thể tích V₂ = 4.5 lít.', 'a) Nhiệt độ T₂ của khí ở trạng thái (2) bằng 450 K.', 'b) Công mà khối khí đã thực hiện trong quá trình giãn nở đẳng áp có độ lớn là 150 J.', 'c) Nội năng của khí ở trạng thái (2) lớn hơn ở trạng thái (1).', 'd) Nếu tiếp tục làm lạnh đẳng tích từ trạng thái (2) về nhiệt độ 300 K thì áp suất lúc này là 10⁵ Pa.', 'D,D,D,S', 'a) Đúng: V₁/T₁ = V₂/T₂ ⇒ T₂ = 300×(4.5/3) = 450 K.
b) Đúng: |A| = p.ΔV = 10⁵ × (1.5×10⁻³) = 150 J.
c) Đúng: Nhiệt độ tăng nên nội năng tăng.
d) Sai: p₃ = p₂.(T₃/T₂) = 10⁵ × (300/450) = 6.67×10⁴ Pa.', 1.00, 'Vận dụng', 19),
(16, 'true_false', 'Một dây dẫn thẳng dài vô hạn đặt trong không khí mang dòng điện không đổi I = 10 A. Điểm M cách dây dẫn một khoảng r = 5 cm (biết B = 2×10⁻⁷.I/r).', 'a) Các đường sức từ quanh dây dẫn là các đường tròn đồng tâm nằm trong mặt phẳng vuông góc với dây.', 'b) Cảm ứng từ tại M có độ lớn bằng 4×10⁻⁵ T.', 'c) Nếu tăng khoảng cách r lên gấp đôi (10 cm) thì cảm ứng từ giảm đi một nửa.', 'd) Nếu đổi chiều dòng điện thì độ lớn cảm ứng từ tại M giảm xuống bằng 0.', 'D,D,D,S', 'a) Đúng.
b) Đúng: B = 2×10⁻⁷ × 10 / 0.05 = 4×10⁻⁵ T.
c) Đúng: B tỉ lệ nghịch với r.
d) Sai: Đổi chiều dòng điện chỉ làm đổi chiều vectơ B, độ lớn không đổi.', 1.00, 'Thông hiểu', 20),
(16, 'true_false', 'Một con lắc lò xo gồm vật nặng khối lượng m = 100 g và lò xo nhẹ có độ cứng k = 100 N/m dao động điều hòa với biên độ A = 4 cm. Lấy π² = 10.', 'a) Tần số góc của dao động là 10π rad/s.', 'b) Chu kì dao động của con lắc là 0.2 s.', 'c) Cơ năng dao động của con lắc bằng 0.08 J.', 'd) Tại vị trí có li độ x = 2 cm, động năng của vật bằng thế năng.', 'D,D,D,S', 'a) Đúng: ω = √(k/m) = √(100/0.1) = √1000 = 10√10 ≈ 10π rad/s.
b) Đúng: T = 2π/ω = 0.2 s.
c) Đúng: W = (1/2)kA² = 0.5 × 100 × 0.04² = 0.08 J.
d) Sai: Tại x = A/2 thì W_t = W/4, W_đ = 3W/4 nên W_đ = 3W_t.', 1.00, 'Vận dụng', 21),
(16, 'true_false', 'Chất phóng xạ Iốt ¹³¹₅₃I dùng trong y học có chu kì bán rã T = 8 ngày. Ban đầu có một mẫu ¹³¹₅₃I khối lượng 100 mg.', 'a) Sau 8 ngày, khối lượng ¹³¹₅₃I còn lại trong mẫu là 50 mg.', 'b) Sau 24 ngày, khối lượng ¹³¹₅₃I đã bị phân rã là 87.5 mg.', 'c) Hằng số phóng xạ của ¹³¹₅₃I là λ = ln(2)/8 (ngày⁻¹).', 'd) Nếu tăng nhiệt độ của mẫu chất lên 100°C thì chu kì bán rã sẽ giảm đi.', 'D,D,D,S', 'a) Đúng.
b) Đúng: t=3T ⇒ còn 100/8 = 12.5 mg ⇒ đã phân rã 87.5 mg.
c) Đúng.
d) Sai: Chu kì bán rã là hằng số đặc trưng, không phụ thuộc nhiệt độ hay áp suất ngoài.', 1.00, 'Thông hiểu', 22),
(16, 'short_answer', 'Tính động năng tịnh tiến trung bình của phân tử khí lí tưởng ở nhiệt độ 27°C (300 K) theo đơn vị 10⁻²¹ J (lấy hằng số Boltzmann k = 1.38×10⁻²³ J/K).', NULL, NULL, NULL, NULL, '6.21', 'W_đ = (3/2)kT = 1.5 × 1.38×10⁻²³ × 300 = 6.21×10⁻²¹ J.', 0.25, 'Thông hiểu', 23),
(16, 'short_answer', 'Một khối khí trong xilanh nhận công 400 J từ pít-tông và truyền ra môi trường xung quanh nhiệt lượng 150 J. Độ biến thiên nội năng của khối khí là bao nhiêu Jun?', NULL, NULL, NULL, NULL, '250', 'Nhận công A = +400 J, tỏa nhiệt Q = -150 J ⇒ ΔU = A + Q = 250 J.', 0.25, 'Thông hiểu', 24),
(16, 'short_answer', 'Đặt điện áp xoay chiều u = 100√2 cos(100πt) V vào hai đầu một điện trở thuần R = 25 Ω. Công suất tỏa nhiệt trên điện trở bằng bao nhiêu Watt (W)?', NULL, NULL, NULL, NULL, '400', 'U = 100 V ⇒ P = U²/R = 100² / 25 = 400 W.', 0.25, 'Thông hiểu', 25),
(16, 'short_answer', 'Hạt nhân ²³⁸₉₂U phóng xạ α tạo thành hạt nhân con X. Hạt nhân con X có bao nhiêu neutron?', NULL, NULL, NULL, NULL, '144', '²³⁸₉₂U → ⁴₂He + ²³⁴₉₀Th. Số neutron của X là 234 - 90 = 144.', 0.25, 'Thông hiểu', 26),
(16, 'short_answer', 'Một động cơ nhiệt nhận nhiệt lượng 1000 J từ nguồn nóng và nhả 600 J cho nguồn lạnh trong mỗi chu trình. Hiệu suất của động cơ nhiệt này là bao nhiêu phần trăm (%)?', NULL, NULL, NULL, NULL, '40', 'H = (Q₁ - Q₂)/Q₁ = (1000 - 600)/1000 = 0.4 = 40%.', 0.25, 'Nhận biết', 27),
(16, 'short_answer', 'Từ thông qua một mạch kín biến thiên đều một lượng 0.08 Wb trong khoảng thời gian 0.02 s. Độ lớn suất điện động cảm ứng xuất hiện trong mạch là bao nhiêu Volt?', NULL, NULL, NULL, NULL, '4', '|e_c| = |ΔΦ/Δt| = 0.08 / 0.02 = 4 V.', 0.25, 'Nhận biết', 28),
(17, 'mcq', 'Quá trình chất khí chuyển trực tiếp từ thể rắn sang thể khí (không qua thể lỏng) gọi là:', 'Sự bay hơi', 'Sự ngưng tụ', 'Sự nóng chảy', 'Sự thăng hoa', 'D', 'Rắn → Khí gọi là sự thăng hoa.', 0.25, 'Nhận biết', 1),
(17, 'mcq', 'Trong phương trình trạng thái khí lí tưởng pV/T = hằng số, T là:', 'Nhiệt độ Fahrenheit', 'Nhiệt độ tuyệt đối (Kelvin)', 'Nhiệt độ Celsius', 'Nhiệt dung riêng', 'B', 'T luôn đo theo thang Kelvin.', 0.25, 'Nhận biết', 2),
(17, 'mcq', 'Ở điều kiện áp suất không đổi, khi nhiệt độ tuyệt đối của một khối khí lí tưởng tăng gấp đôi thì thể tích của nó:', 'Không đổi', 'Tăng gấp đôi', 'Tăng gấp bốn', 'Giảm một nửa', 'B', 'V tỉ lệ thuận với T khi p không đổi.', 0.25, 'Nhận biết', 3),
(17, 'mcq', 'Từ trường không tác dụng lực từ lên:', 'Kim nam châm', 'Hạt mang điện đứng yên', 'Dòng điện thẳng', 'Hạt mang điện chuyển động cắt đường sức từ', 'B', 'Lực Lorentz f = |q|vBsinθ = 0 khi v = 0.', 0.25, 'Nhận biết', 4),
(17, 'mcq', 'Nguyên tắc hoạt động của máy phát điện xoay chiều dựa trên hiện tượng:', 'Tán sắc ánh sáng', 'Phóng xạ hạt nhân', 'Cảm ứng điện từ', 'Giao thoa ánh sáng', 'C', 'Máy phát điện hoạt động dựa trên hiện tượng cảm ứng điện từ.', 0.25, 'Nhận biết', 5),
(17, 'mcq', 'Tia nào sau đây không bị lệch trong điện trường và từ trường?', 'Tia γ', 'Tia α', 'Tia β⁻', 'Tia β⁺', 'A', 'Tia γ là sóng điện từ không mang điện nên không bị lệch.', 0.25, 'Nhận biết', 6),
(17, 'mcq', 'Trong các hạt nhân sau: ⁴₂He, ⁵⁶₂₆Fe, ²³⁵₉₂U, ²³⁸₉₂U, hạt nhân bền vững nhất là:', '²³⁸₉₂U', '⁴₂He', '⁵⁶₂₆Fe', '²³⁵₉₂U', 'C', 'Sắt (⁵⁶₂₆Fe) nằm ở đỉnh đường cong năng lượng liên kết riêng.', 0.25, 'Nhận biết', 7),
(17, 'mcq', 'Tần số dòng điện xoay chiều dân dụng ở Việt Nam là:', '220 Hz', '60 Hz', '100 Hz', '50 Hz', 'D', 'Mạng điện dân dụng Việt Nam có tần số 50 Hz.', 0.25, 'Nhận biết', 8),
(17, 'mcq', 'Một vật dao động điều hòa với phương trình x = 5cos(2πt) cm. Tại t = 0.5 s, li độ của vật là:', '5 cm', '0 cm', '2.5 cm', '-5 cm', 'D', 'x = 5cos(π) = -5 cm.', 0.25, 'Thông hiểu', 9),
(17, 'mcq', 'Âm sắc là một đặc trưng sinh lí của âm gắn liền với đặc trưng vật lí nào?', 'Mức cường độ âm', 'Cường độ âm', 'Tần số âm', 'Đồ thị dao động âm', 'D', 'Âm sắc phụ thuộc đồ thị dao động âm.', 0.25, 'Nhận biết', 10),
(17, 'mcq', 'Cần nhiệt lượng bao nhiêu để làm hóa hơi hoàn toàn 2 kg nước ở 100°C? Biết nhiệt hóa hơi riêng của nước ở 100°C là L = 2.26×10⁶ J/kg.', '4.52 kJ', '4.52 MJ', '2.26 MJ', '1.13 MJ', 'B', 'Q = L.m = 2.26×10⁶ × 2 = 4.52×10⁶ J = 4.52 MJ.', 0.25, 'Thông hiểu', 11),
(17, 'mcq', 'Một bình chứa khí ở nhiệt độ 27°C (300 K) có áp suất 2 atm. Đun nóng đẳng tích đến khi áp suất đạt 3 atm thì nhiệt độ của khí là:', '450°C', '177°C', '40.5°C', '150°C', 'B', 'T₂ = 300 × (3/2) = 450 K = 450 - 273 = 177°C.', 0.25, 'Thông hiểu', 12),
(17, 'mcq', 'Một electron bay với vận tốc v = 2×10⁶ m/s vuông góc vào từ trường đều B = 0.01 T. Độ lớn lực Lorentz tác dụng lên electron là (|e| = 1.6×10⁻¹⁹ C):', '3.2×10⁻¹³ N', '6.4×10⁻¹⁵ N', '1.6×10⁻¹⁵ N', '3.2×10⁻¹⁵ N', 'D', 'f = |q|vB = 1.6×10⁻¹⁹ × 2×10⁶ × 0.01 = 3.2×10⁻¹⁵ N.', 0.25, 'Thông hiểu', 13),
(17, 'mcq', 'Một sóng âm truyền từ không khí vào nước thì đại lượng nào sau đây KHÔNG thay đổi?', 'Bước sóng', 'Biên độ sóng', 'Tần số của sóng', 'Tốc độ truyền sóng', 'C', 'Tần số của sóng do nguồn phát quyết định và không đổi khi truyền qua các môi trường.', 0.25, 'Nhận biết', 14),
(17, 'mcq', 'Chiếu ánh sáng đơn sắc bước sóng λ = 0.6 μm trong thí nghiệm Y-âng với a = 1.2 mm, D = 2 m. Khoảng cách giữa 2 vân sáng liên tiếp là:', '0.5 mm', '1.5 mm', '2 mm', '1 mm', 'D', 'i = λD/a = (0.6×2)/1.2 = 1 mm.', 0.25, 'Thông hiểu', 15),
(17, 'mcq', 'Phản ứng hạt nhân ¹⁴₇N + ⁴₂He → ¹⁷₈O + X. Hạt nhân X là:', 'Đơteri (²₁H)', 'Electron (⁰₋₁e)', 'Neutron (¹₀n)', 'Proton (¹₁p)', 'D', 'Bảo toàn A: 14+4=17+1 ⇒ A=1. Bảo toàn Z: 7+2=8+1 ⇒ Z=1 ⇒ ¹₁p.', 0.25, 'Thông hiểu', 16),
(17, 'mcq', 'Chu kì bán rã của một đồng vị phóng xạ là 2 ngày. Ban đầu có 16 g chất này, sau 6 ngày khối lượng chất này còn lại là:', '1 g', '2 g', '8 g', '4 g', 'B', '6 ngày = 3T ⇒ m = 16 / 2³ = 2 g.', 0.25, 'Thông hiểu', 17),
(17, 'mcq', 'Một đoạn dây dẫn dài 1 m mang dòng điện 2 A đặt song song với đường sức từ của từ trường đều B = 0.5 T. Lực từ tác dụng lên đoạn dây có độ lớn:', '1 N', '0 N', '2 N', '0.5 N', 'B', 'Song song với B ⇒ θ = 0° ⇒ F = B.I.l.sin(0°) = 0 N.', 0.25, 'Thông hiểu', 18),
(17, 'true_false', 'Người ta thả một miếng đồng khối lượng 0.5 kg ở nhiệt độ 100°C vào 1 kg nước ở nhiệt độ 20°C. Biết nhiệt dung riêng của đồng là 380 J/(kg.K), của nước là 4200 J/(kg.K). Bỏ qua sự trao đổi nhiệt với môi trường.', 'a) Trong quá trình truyền nhiệt, miếng đồng tỏa nhiệt và nước thu nhiệt.', 'b) Nhiệt độ cân bằng của hệ nhỏ hơn 25°C.', 'c) Độ biến thiên nội năng của nước bằng độ giảm nội năng của miếng đồng.', 'd) Nhiệt độ cuối cùng của hệ là 60°C.', 'D,D,D,S', 'a) Đúng.
b) Đúng: 0.5×380×(100-t) = 1×4200×(t-20) ⇒ 190(100-t)=4200(t-20) ⇒ t ≈ 23.46°C < 25°C.
c) Đúng (bảo toàn năng lượng).
d) Sai: t ≈ 23.46°C.', 1.00, 'Vận dụng', 19),
(17, 'true_false', 'Một dòng điện xoay chiều có biểu thức i = 2√2 cos(100πt + π/6) A.', 'a) Cường độ dòng điện hiệu dụng bằng 2 A.', 'b) Tần số của dòng điện bằng 50 Hz.', 'c) Pha ban đầu của dòng điện là π/6 rad.', 'd) Trong mỗi giây, dòng điện đổi chiều 50 lần.', 'D,D,D,S', 'a) Đúng: I = 2√2 / √2 = 2 A.
b) Đúng: f = ω/(2π) = 50 Hz.
c) Đúng.
d) Sai: Mỗi chu kì đổi chiều 2 lần ⇒ 1 giây đổi chiều 2f = 100 lần.', 1.00, 'Thông hiểu', 20),
(17, 'true_false', 'Một khung dây dẫn phẳng diện tích S = 200 cm² (0.02 m²) gồm 50 vòng quay đều với tốc độ 50 vòng/giây quanh một trục nằm trong mặt phẳng khung và vuông góc với từ trường đều B = 0.1 T.', 'a) Tần số góc của khung dây là 100π rad/s.', 'b) Từ thông cực đại qua khung dây (toàn bộ 50 vòng) là 0.1 Wb.', 'c) Suất điện động cực đại cảm ứng trong khung bằng 10π V.', 'd) Giá trị hiệu dụng của suất điện động là 10π V.', 'D,D,D,S', 'a) Đúng: ω = 2πf = 100π rad/s.
b) Đúng: Φ₀ = N.B.S = 50 × 0.1 × 0.02 = 0.1 Wb.
c) Đúng: E₀ = ω.Φ₀ = 100π × 0.1 = 10π V.
d) Sai: E = E₀/√2 = 5π√2 V.', 1.00, 'Vận dụng', 21),
(17, 'true_false', 'Cho phản ứng phân hạch: ¹₀n + ²³⁵₉₂U → ¹⁴¹₅₆Ba + ⁹²₃₆Kr + k ¹₀n.', 'a) Hệ số k trong phương trình phản ứng bằng 3.', 'b) Đây là phản ứng hạt nhân thu năng lượng.', 'c) Tổng số khối của các hạt trước và sau phản ứng được bảo toàn.', 'd) Phản ứng phân hạch dây chuyền có kiểm soát được ứng dụng trong các nhà máy điện hạt nhân.', 'D,S,D,D', 'a) Đúng: 1 + 235 = 141 + 92 + k ⇒ k = 3.
b) Sai: Phân hạch hạt nhân nặng là phản ứng tỏa năng lượng.
c) Đúng.
d) Đúng.', 1.00, 'Thông hiểu', 22),
(17, 'short_answer', 'Một bình kín thể tích 0.02 m³ chứa 1 mol khí lí tưởng ở nhiệt độ 127°C (400 K). Lấy R = 8.31 J/(mol.K). Tính áp suất khí trong bình theo đơn vị kPa.', NULL, NULL, NULL, NULL, '166.2', 'p = nRT/V = (1 × 8.31 × 400)/0.02 = 166200 Pa = 166.2 kPa.', 0.25, 'Thông hiểu', 23),
(17, 'short_answer', 'Biết nhiệt nóng chảy riêng của chì ở nhiệt độ nóng chảy là 25 kJ/kg. Tính nhiệt lượng (theo đơn vị kJ) cần cung cấp để làm nóng chảy hoàn toàn 2 kg chì ở nhiệt độ nóng chảy.', NULL, NULL, NULL, NULL, '50', 'Q = λ.m = 25 × 2 = 50 kJ.', 0.25, 'Nhận biết', 24),
(17, 'short_answer', 'Một người quan sát mặt hồ thấy 5 ngọn sóng liên tiếp đi qua trước mặt trong khoảng cách 2 m và tần số sóng là 20 Hz. Tính tốc độ truyền sóng trên mặt nước (theo đơn vị m/s).', NULL, NULL, NULL, NULL, '10', '5 ngọn sóng liên tiếp cách nhau 4λ = 2 m ⇒ λ = 0.5 m ⇒ v = λf = 0.5 × 20 = 10 m/s.', 0.25, 'Thông hiểu', 25),
(17, 'short_answer', 'Cho khối lượng của proton là 1.0073 u, neutron là 1.0087 u và hạt nhân ⁴₂He là 4.0015 u. Tính độ hụt khối của hạt nhân ⁴₂He theo đơn vị u.', NULL, NULL, NULL, NULL, '0.0305', 'Δm = 2m_p + 2m_n - m_He = 2(1.0073) + 2(1.0087) - 4.0015 = 0.0305 u.', 0.25, 'Thông hiểu', 26),
(17, 'short_answer', 'Một đoạn dây dẫn thẳng dài 0.4 m đặt vuông góc với đường sức từ của từ trường đều có cảm ứng từ B = 0.5 T. Khi cho dòng điện cường độ 3 A chạy qua dây, lực từ tác dụng lên đoạn dây có độ lớn bằng bao nhiêu Newton?', NULL, NULL, NULL, NULL, '0.6', 'F = B.I.l = 0.5 × 3 × 0.4 = 0.6 N.', 0.25, 'Nhận biết', 27),
(17, 'short_answer', 'Một con lắc đơn có chiều dài dây treo l = 1 m dao động điều hòa tại nơi có gia tốc trọng trường g = π² m/s². Tính chu kì dao động của con lắc theo đơn vị giây.', NULL, NULL, NULL, NULL, '2', 'T = 2π√(l/g) = 2π√(1/π²) = 2 s.', 0.25, 'Nhận biết', 28),
(18, 'mcq', 'Este etyl axetat có công thức cấu tạo là:', 'C₂H₅COOCH₃', 'CH₃COOCH₃', 'CH₃COOC₂H₅', 'HCOOC₂H₅', 'C', 'Etyl axetat tạo bởi axit axetic (CH₃COOH) và ancol etylic (C₂H₅OH).', 0.25, 'Nhận biết', 1),
(18, 'mcq', 'Chất nào sau đây thuộc loại đisaccarit?', 'Saccarozơ', 'Fructozơ', 'Glucozơ', 'Tinh bột', 'A', 'Saccarozơ (C₁₂H₂₂O₁₁) và mantozơ là đisaccarit.', 0.25, 'Nhận biết', 2),
(18, 'mcq', 'Ở điều kiện thường, amin nào sau đây ở trạng thái khí và có mùi khai?', 'Glixin', 'Metylamin (CH₃NH₂)', 'Anilin (C₆H₅NH₂)', 'Alanin', 'B', 'CH₃NH₂, (CH₃)₂NH, (CH₃)₃N, C₂H₅NH₂ là các chất khí ở đk thường.', 0.25, 'Nhận biết', 3),
(18, 'mcq', 'Chất nào sau đây có phản ứng màu biure (tạo phức màu tím với Cu(OH)₂ trong môi trường kiềm)?', 'Glixin', 'Tripeptit trở lên (như Gly-Ala-Gly)', 'Đipeptit (Gly-Ala)', 'Glucozơ', 'B', 'Phản ứng màu biure xảy ra với peptit có từ 2 liên kết peptit trở lên (tripeptit trở lên).', 0.25, 'Nhận biết', 4),
(18, 'mcq', 'Polime nào sau đây được điều chế bằng phản ứng trùng ngưng?', 'Poli(vinyl clorua) (PVC)', 'Polietilen (PE)', 'Polistiren (PS)', 'Nilon-6,6', 'D', 'Nilon-6,6 điều chế bằng đồng trùng ngưng hexametylenđiamin và axit ađipic.', 0.25, 'Nhận biết', 5),
(18, 'mcq', 'Kim loại nào sau đây có độ cứng lớn nhất?', 'Crom (Cr)', 'Sắt (Fe)', 'Natri (Na)', 'Đồng (Cu)', 'A', 'Crom (Cr) là kim loại cứng nhất.', 0.25, 'Nhận biết', 6),
(18, 'mcq', 'Kim loại nào sau đây không tác dụng với dung dịch H₂SO₄ loãng?', 'Magie (Mg)', 'Bạc (Ag)', 'Sắt (Fe)', 'Kẽm (Zn)', 'B', 'Ag đứng sau H trong dãy hoạt động hóa học nên không phản ứng với H₂SO₄ loãng.', 0.25, 'Nhận biết', 7),
(18, 'mcq', 'Chất nào sau đây làm mềm được nước có tính cứng vĩnh cửu?', 'NaCl', 'CaCl₂', 'Na₂CO₃', 'HCl', 'C', 'CO₃²⁻ kết tủa cả Ca²⁺ và Mg²⁺ nên làm mềm được nước cứng vĩnh cửu và toàn phần.', 0.25, 'Nhận biết', 8),
(18, 'mcq', 'Khi điện phân dung dịch CuSO₄ với các điện cực trơ, ở catot (cực âm) xảy ra quá trình:', 'Oxi hóa Cu thành Cu²⁺', 'Khử nước thành H₂', 'Oxi hóa nước thành O₂', 'Khử ion Cu²⁺ thành Cu', 'D', 'Tại catot xảy ra sự khử: Cu²⁺ + 2e → Cu.', 0.25, 'Thông hiểu', 9),
(18, 'mcq', 'Số đồng phân cấu tạo este ứng với công thức phân tử C₃H₆O₂ là:', '3', '2', '1', '4', 'B', 'Gồm HCOOC₂H₅ và CH₃COOCH₃ (2 đồng phân).', 0.25, 'Nhận biết', 10),
(18, 'mcq', 'Dung dịch chất nào sau đây làm quỳ tím chuyển sang màu xanh?', 'Axit glutamic', 'Anilin (C₆H₅NH₂)', 'Glixin (H₂N-CH₂-COOH)', 'Etylamin (C₂H₅NH₂)', 'D', 'Amin no mạch hở có tính bazơ mạnh hơn NH₃ nên làm quỳ tím hóa xanh.', 0.25, 'Thông hiểu', 11),
(18, 'mcq', 'Thủy phân hoàn toàn 1 mol triolein (C₁₇H₃₃COO)₃C₃H₅ cần vừa đủ bao nhiêu mol NaOH?', '4 mol', '2 mol', '3 mol', '1 mol', 'C', 'Chất béo là trieste của glixerol nên phản ứng với NaOH theo tỉ lệ 1:3.', 0.25, 'Nhận biết', 12),
(18, 'mcq', 'Đốt cháy hoàn toàn 0.1 mol metyl fomat (HCOOCH₃) thu được số mol CO₂ là:', '0.4 mol', '0.1 mol', '0.3 mol', '0.2 mol', 'D', 'C₂H₄O₂ có 2C ⇒ n_CO₂ = 2 × 0.1 = 0.2 mol.', 0.25, 'Thông hiểu', 13),
(18, 'mcq', 'Cho 5.4 gam nhôm (Al = 27) tác dụng hoàn toàn với dung dịch HCl dư. Thể tích khí H₂ thu được ở ĐKC (24.79 lít/mol) là:', '9.916 lít', '2.479 lít', '4.958 lít', '7.437 lít', 'D', 'n_Al = 0.2 mol ⇒ n_H₂ = 1.5 × 0.2 = 0.3 mol ⇒ V = 0.3 × 24.79 = 7.437 lít.', 0.25, 'Thông hiểu', 14),
(18, 'mcq', 'Cho glucozơ (M = 180) lên men thành ancol etylic (C₂H₅OH, M = 46) với hiệu suất 100%. Từ 18 gam glucozơ thu được khối lượng ancol etylic là:', '4.6 gam', '13.8 gam', '18.4 gam', '9.2 gam', 'D', 'n_glu = 0.1 mol ⇒ n_C₂H₅OH = 0.2 mol ⇒ m = 0.2 × 46 = 9.2 gam.', 0.25, 'Thông hiểu', 15),
(18, 'mcq', 'Cho dãy các chất: NaOH, HCl, NaCl, Al₂O₃. Số chất trong dãy tác dụng được với dung dịch KOH là:', '3', '4', '1', '2', 'D', 'Gồm HCl và Al₂O₃ (oxit lưỡng tính).', 0.25, 'Thông hiểu', 16),
(18, 'mcq', 'Pin điện hóa Zn - Cu có thế điện cực chuẩn E°(Zn²⁺/Zn) = -0.76 V và E°(Cu²⁺/Cu) = +0.34 V. Sức điện động chuẩn của pin là:', '1.10 V', '-1.10 V', '0.42 V', '0.76 V', 'A', 'E°_pin = E°(Cu²⁺/Cu) - E°(Zn²⁺/Zn) = 0.34 - (-0.76) = 1.10 V.', 0.25, 'Thông hiểu', 17),
(18, 'mcq', 'Nhỏ vài giọt dung dịch I₂ vào lát cắt củ khoai lang thấy xuất hiện màu:', 'Xanh tím', 'Vàng cam', 'Trắng sữa', 'Đỏ gạch', 'A', 'Hồ tinh bột trong khoai lang tác dụng với I₂ cho màu xanh tím.', 0.25, 'Nhận biết', 18),
(18, 'true_false', 'Tiến hành thí nghiệm phản ứng tráng bạc của glucozơ: Cho 1 ml dung dịch AgNO₃ 1% vào ống nghiệm, nhỏ từ từ NH₃ cho đến khi kết tủa tan hết, thêm tiếp 1 ml dung dịch glucozơ 1%, đun nóng nhẹ.', 'a) Sau phản ứng thấy có lớp bạc sáng bám lên thành ống nghiệm.', 'b) Trong phản ứng này, glucozơ đóng vai trò là chất khử.', 'c) Một mol glucozơ phản ứng hoàn toàn tạo ra tối đa 2 mol Ag.', 'd) Sản phẩm hữu cơ thu được là axit gluconic tự do (không ở dạng muối).', 'D,D,D,S', 'a) Đúng.
b) Đúng: Glucozơ khử Ag⁺ thành Ag.
c) Đúng.
d) Sai: Trong môi trường NH₃, sản phẩm là muối amoni gluconat.', 1.00, 'Thông hiểu', 19),
(18, 'true_false', 'Cho amino axit X là glixin (H₂N-CH₂-COOH, M = 75).', 'a) Trong phân tử glixin có chứa 1 nhóm amino (-NH₂) và 1 nhóm cacboxyl (-COOH).', 'b) Glixin có tính chất lưỡng tính, tác dụng được với cả dung dịch HCl và NaOH.', 'c) Dung dịch glixin làm quỳ tím chuyển sang màu đỏ rõ rệt.', 'd) Cho 7.5 gam glixin tác dụng vừa đủ với dung dịch NaOH thu được 9.7 gam muối.', 'D,D,S,D', 'a) Đúng.
b) Đúng.
c) Sai: 1 nhóm NH₂ và 1 nhóm COOH nên dung dịch glixin hầu như không làm đổi màu quỳ tím.
d) Đúng: n=0.1 mol ⇒ m_muối = 0.1 × (75 + 22) = 9.7 gam.', 1.00, 'Thông hiểu', 20),
(18, 'true_false', 'Thực hiện phản ứng xà phòng hóa chất béo tristearin ((C₁₇H₃₅COO)₃C₃H₅, M = 890) bằng dung dịch NaOH dư, đun nóng.', 'a) Công thức của muối thu được sau phản ứng là C₁₇H₃₅COONa (natri stearat).', 'b) Sản phẩm phụ thu được là ancol etylic.', 'c) Từ 89 gam tristearin phản ứng hoàn toàn thu được 9.2 gam glixerol (M = 92).', 'd) Phản ứng xà phòng hóa là phản ứng một chiều.', 'D,S,D,D', 'a) Đúng.
b) Sai: Sản phẩm phụ là glixerol C₃H₅(OH)₃.
c) Đúng: n = 89/890 = 0.1 mol ⇒ m_glixerol = 0.1 × 92 = 9.2 gam.
d) Đúng.', 1.00, 'Vận dụng', 21),
(18, 'true_false', 'Cho sơ đồ ăn mòn điện hóa: Nhúng một thanh kẽm (Zn) và một thanh đồng (Cu) nối với nhau bằng dây dẫn vào cốc đựng dung dịch H₂SO₄ loãng.', 'a) Thanh kẽm (Zn) đóng vai trò là cực âm (anot) và bị ăn mòn.', 'b) Tại thanh đồng (Cu) có bọt khí H₂ thoát ra.', 'c) Electron di chuyển qua dây dẫn từ thanh đồng sang thanh kẽm.', 'd) Sau một thời gian, khối lượng thanh đồng không thay đổi.', 'D,D,S,D', 'a) Đúng: Zn hoạt động mạnh hơn nên là cực âm (anot): Zn → Zn²⁺ + 2e.
b) Đúng: 2H⁺ + 2e → H₂↑ tại cực dương (Cu).
c) Sai: Electron di chuyển từ cực âm (Zn) sang cực dương (Cu).
d) Đúng: Thanh Cu chỉ là điện cực nhận e, không bị hòa tan.', 1.00, 'Vận dụng', 22),
(18, 'short_answer', 'Đun nóng 8.8 gam etyl axetat (CH₃COOC₂H₅, M = 88) với dung dịch NaOH dư đến khi phản ứng hoàn toàn. Khối lượng muối CH₃COONa (M = 82) thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '8.2', 'n_este = 8.8/88 = 0.1 mol ⇒ m_muối = 0.1 × 82 = 8.2 gam.', 0.25, 'Nhận biết', 23),
(18, 'short_answer', 'Cho 11.2 gam bột Fe (M = 56) tác dụng hoàn toàn với dung dịch CuSO₄ dư. Khối lượng kim loại Cu (M = 64) thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '12.8', 'n_Fe = 11.2/56 = 0.2 mol ⇒ n_Cu = 0.2 mol ⇒ m_Cu = 0.2 × 64 = 12.8 gam.', 0.25, 'Nhận biết', 24),
(18, 'short_answer', 'Để trung hòa hoàn toàn 200 ml dung dịch HCl 1M cần vừa đủ V ml dung dịch NaOH 0.5M. Giá trị của V là bao nhiêu?', NULL, NULL, NULL, NULL, '400', 'n_HCl = 0.2 mol ⇒ n_NaOH = 0.2 mol ⇒ V = 0.2 / 0.5 = 0.4 lít = 400 ml.', 0.25, 'Thông hiểu', 25),
(18, 'short_answer', 'Đốt cháy hoàn toàn m gam alanin (C₃H₇NO₂, M = 89) thu được 0.3 mol khí CO₂. Giá trị của m là bao nhiêu gam?', NULL, NULL, NULL, NULL, '8.9', 'n_Ala = n_CO₂ / 3 = 0.1 mol ⇒ m = 0.1 × 89 = 8.9 gam.', 0.25, 'Thông hiểu', 26),
(18, 'short_answer', 'Cho 3.1 gam metylamin (CH₃NH₂, M = 31) tác dụng hoàn toàn với lượng dư dung dịch HCl. Khối lượng muối thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '6.75', 'n_amin = 0.1 mol ⇒ m_muối = 3.1 + 0.1 × 36.5 = 6.75 gam.', 0.25, 'Thông hiểu', 27),
(18, 'short_answer', 'Khử hoàn toàn 16 gam Fe₂O₃ (M = 160) bằng khí CO dư ở nhiệt độ cao, thu được m gam kim loại Fe (M = 56). Giá trị của m là bao nhiêu gam?', NULL, NULL, NULL, NULL, '11.2', 'n_Fe₂O₃ = 0.1 mol ⇒ n_Fe = 0.2 mol ⇒ m_Fe = 0.2 × 56 = 11.2 gam.', 0.25, 'Thông hiểu', 28),
(19, 'mcq', 'Chất nào sau đây là thành phần chính của sợi bông, gỗ, nứa?', 'Glucozơ', 'Xenlulozơ', 'Tinh bột', 'Saccarozơ', 'B', 'Xenlulozơ là thành phần chính tạo nên màng tế bào thực vật (bông, gỗ).', 0.25, 'Nhận biết', 1),
(19, 'mcq', 'Tên gọi của este HCOOCH₃ là:', 'Metyl fomat', 'Vinyl axetat', 'Etyl fomat', 'Metyl axetat', 'A', 'HCOOCH₃ là metyl fomat.', 0.25, 'Nhận biết', 2),
(19, 'mcq', 'Số nguyên tử nitơ có trong một phân tử đipeptit Ala-Gly là:', '3', '2', '1', '4', 'B', 'Mỗi gốc α-amino axit có 1 N ⇒ đipeptit có 2 N.', 0.25, 'Nhận biết', 3),
(19, 'mcq', 'Polime nào sau đây dùng để sản xuất thủy tinh hữu cơ (plexiglas)?', 'Poliacrilonitrin', 'Poli(vinyl clorua)', 'Polietilen', 'Poli(metyl metacrylat)', 'D', 'Thủy tinh hữu cơ là poli(metyl metacrylat).', 0.25, 'Nhận biết', 4),
(19, 'mcq', 'Kim loại nào sau đây có nhiệt độ nóng chảy thấp nhất (ở thể lỏng ở nhiệt độ thường)?', 'Đồng (Cu)', 'Sắt (Fe)', 'Thủy ngân (Hg)', 'Vonfram (W)', 'C', 'Thủy ngân (Hg) nóng chảy ở -39°C, là kim loại duy nhất ở thể lỏng ở nhiệt độ thường.', 0.25, 'Nhận biết', 5),
(19, 'mcq', 'Công thức hóa học của thạch cao sống là:', 'CaSO₄.H₂O', 'CaSO₄.2H₂O', 'CaSO₄', 'CaCO₃', 'B', 'Thạch cao sống là CaSO₄.2H₂O.', 0.25, 'Nhận biết', 6),
(19, 'mcq', 'Trong bảng tuần hoàn, các kim loại kiềm thuộc nhóm:', 'IIA', 'VIIA', 'IIIA', 'IA', 'D', 'Kim loại kiềm (Li, Na, K, Rb, Cs) thuộc nhóm IA.', 0.25, 'Nhận biết', 7),
(19, 'mcq', 'Khí nào sau đây là nguyên nhân chính gây ra hiệu ứng nhà kính làm Trái Đất nóng lên?', 'CO₂', 'N₂', 'Ar', 'O₂', 'A', 'Khí CO₂ là tác nhân chính gây hiệu ứng nhà kính.', 0.25, 'Nhận biết', 8),
(19, 'mcq', 'Phản ứng giữa axit axetic và ancol etylic (xúc tác H₂SO₄ đặc, đun nóng) gọi là:', 'Phản ứng cracking', 'Phản ứng xà phòng hóa', 'Phản ứng este hóa', 'Phản ứng trùng hợp', 'C', 'Axit cacboxylic + Ancol ⇌ Este + Nước là phản ứng este hóa.', 0.25, 'Nhận biết', 9),
(19, 'mcq', 'Trong phức chất [Ag(NH₃)₂]⁺, phối tử là:', 'Ag⁺', 'Cl⁻', 'H₂O', 'NH₃', 'D', 'Phối tử liên kết với ion trung tâm Ag⁺ là NH₃.', 0.25, 'Nhận biết', 10),
(19, 'mcq', 'Dung dịch nào sau đây hòa tan được kết tủa Cu(OH)₂ tạo thành dung dịch màu xanh lam đặc trưng (do tạo phức)?', 'Glucozơ', 'Ancol etylic', 'Benzen', 'Etyl axetat', 'A', 'Glucozơ có nhiều nhóm -OH liền kề (poliancol) nên hòa tan Cu(OH)₂ tạo dung dịch xanh lam.', 0.25, 'Thông hiểu', 11),
(19, 'mcq', 'Nhúng thanh Zn vào dung dịch nào sau đây KHÔNG xảy ra phản ứng ăn mòn điện hóa?', 'Dung dịch FeCl₂', 'Dung dịch AgNO₃', 'Dung dịch CuSO₄', 'Dung dịch HCl nguyên chất', 'D', 'Zn + HCl chỉ xảy ra ăn mòn hóa học (chỉ có 1 điện cực Zn, không tạo thành 2 điện cực khác bản chất).', 0.25, 'Thông hiểu', 12),
(19, 'mcq', 'Cho 4.6 gam kim loại Na (M = 23) tác dụng hết với nước dư. Thể tích khí H₂ thu được ở ĐKC (24.79 lít/mol) là:', '2.479 lít', '1.2395 lít', '4.958 lít', '7.437 lít', 'A', 'n_Na = 0.2 mol ⇒ n_H₂ = 0.1 mol ⇒ V = 2.479 lít.', 0.25, 'Thông hiểu', 13),
(19, 'mcq', 'Thủy phân 17.1 gam saccarozơ (M = 342) trong môi trường axit với hiệu suất 100%, thu được dung dịch chứa tổng số mol glucozơ và fructozơ là:', '0.20 mol', '0.15 mol', '0.10 mol', '0.05 mol', 'C', 'n_sac = 17.1/342 = 0.05 mol ⇒ tạo 0.05 mol glu + 0.05 mol fruc = 0.10 mol.', 0.25, 'Thông hiểu', 14),
(19, 'mcq', 'Cho dung dịch FeCl₃ tác dụng với dung dịch NaOH dư thu được kết tủa có màu:', 'Trắng xanh', 'Vàng nhạt', 'Xanh lam', 'Nâu đỏ', 'D', 'Fe(OH)₃ kết tủa màu nâu đỏ.', 0.25, 'Nhận biết', 15),
(19, 'mcq', 'Số liên kết peptit trong phân tử pentapeptit mạch hở là:', '4', '5', '6', '3', 'A', 'Pentapeptit gồm 5 gốc α-amino axit nên có 5 - 1 = 4 liên kết peptit.', 0.25, 'Nhận biết', 16),
(19, 'mcq', 'Kim loại nào sau đây vừa tác dụng được với dung dịch HCl vừa tác dụng được với dung dịch NaOH?', 'Magie (Mg)', 'Nhôm (Al)', 'Sắt (Fe)', 'Đồng (Cu)', 'B', 'Al tan được trong cả dung dịch axit HCl và dung dịch kiềm NaOH.', 0.25, 'Nhận biết', 17),
(19, 'mcq', 'Cho 0.1 mol anilin (C₆H₅NH₂) tác dụng với nước brom dư thu được kết tủa trắng 2,4,6-tribromanilin (M = 330). Khối lượng kết tủa thu được là:', '33.0 gam', '9.3 gam', '16.5 gam', '25.1 gam', 'A', 'Tỉ lệ 1:1 ⇒ m = 0.1 × 330 = 33.0 gam.', 0.25, 'Thông hiểu', 18),
(19, 'true_false', 'Cho hai cặp oxi hóa - khử chuẩn: E°(Fe²⁺/Fe) = -0.44 V và E°(Cu²⁺/Cu) = +0.34 V.', 'a) Tính khử của kim loại Fe mạnh hơn kim loại Cu.', 'b) Ion Cu²⁺ oxi hóa được kim loại Fe thành Fe²⁺.', 'c) Sức điện động chuẩn của pin điện hóa Fe - Cu là 0.78 V.', 'd) Trong pin Fe - Cu, thanh Cu đóng vai trò là anot (cực âm).', 'D,D,D,S', 'a) Đúng: E°(Fe²⁺/Fe) < E°(Cu²⁺/Cu).
b) Đúng.
c) Đúng: E°_pin = 0.34 - (-0.44) = 0.78 V.
d) Sai: Fe có E° nhỏ hơn nên là anot (cực âm), Cu là catot (cực dương).', 1.00, 'Thông hiểu', 19),
(19, 'true_false', 'Cho este X có công thức phân tử C₄H₈O₂. Khi thủy phân X trong dung dịch NaOH thu được muối Y và ancol Z. Biết oxi hóa Z bằng CuO đun nóng thu được anđehit axetic (CH₃CHO).', 'a) Ancol Z là ancol etylic (C₂H₅OH).', 'b) Công thức cấu tạo của este X là CH₃COOC₂H₅.', 'c) Muối Y là natri axetat (CH₃COONa).', 'd) Tên gọi của X là metyl propionat.', 'D,D,D,S', 'a) Đúng: C₂H₅OH + CuO → CH₃CHO + Cu + H₂O.
b) Đúng: Tổng 4C mà ancol là 2C ⇒ axit là 2C (CH₃COOH).
c) Đúng.
d) Sai: X là etyl axetat.', 1.00, 'Vận dụng', 20),
(19, 'true_false', 'Phức chất [Pt(NH₃)₂Cl₂] (cisplatin) được sử dụng phổ biến trong y học để điều trị một số loại ung thư.', 'a) Nguyên tử trung tâm của phức chất là Pt²⁺.', 'b) Phối tử trong phức chất gồm NH₃ và Cl⁻.', 'c) Số phối trí của nguyên tử trung tâm trong phức chất bằng 4.', 'd) Phức chất trên là phức chất mang điện tích +2.', 'D,D,D,S', 'a) Đúng: 2 Cl⁻ có điện tích -2, NH₃ trung hòa ⇒ Pt mang +2.
b) Đúng.
c) Đúng: Có 2 phối tử NH₃ và 2 phối tử Cl⁻ ⇒ số phối trí 4.
d) Sai: (+2) + 2(0) + 2(-1) = 0 ⇒ phức chất trung hòa điện.', 1.00, 'Vận dụng', 21),
(19, 'true_false', 'Hòa tan hoàn toàn 11 gam hỗn hợp gồm Al và Fe trong dung dịch HCl dư thu được 9.916 lít khí H₂ (ở ĐKC 24.79 lít/mol).', 'a) Số mol khí H₂ thu được là 0.4 mol.', 'b) Đặt số mol Al là x, số mol Fe là y, ta có hệ: 27x + 56y = 11 và 1.5x + y = 0.4.', 'c) Số mol Al trong hỗn hợp là 0.2 mol.', 'd) Phần trăm khối lượng của sắt trong hỗn hợp ban đầu là 50.91%.', 'D,D,D,D', 'a) Đúng: 9.916/24.79 = 0.4 mol.
b) Đúng.
c) Đúng: Giải hệ ⇒ x = 0.2 mol, y = 0.1 mol.
d) Đúng: %m_Fe = (0.1×56)/11 × 100% = 50.91%.', 1.00, 'Vận dụng', 22),
(19, 'short_answer', 'Cho 15 gam glixin (H₂N-CH₂-COOH, M = 75) tác dụng hoàn toàn với dung dịch HCl dư. Khối lượng muối thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '22.3', 'n_Gly = 15/75 = 0.2 mol ⇒ m_muối = 15 + 0.2 × 36.5 = 22.3 gam.', 0.25, 'Nhận biết', 23),
(19, 'short_answer', 'Cho 6.5 gam kẽm (Zn = 65) tác dụng hoàn toàn với dung dịch AgNO₃ dư. Khối lượng kim loại bạc (Ag = 108) thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '21.6', 'n_Zn = 0.1 mol ⇒ n_Ag = 0.2 mol ⇒ m_Ag = 0.2 × 108 = 21.6 gam.', 0.25, 'Thông hiểu', 24),
(19, 'short_answer', 'Hòa tan hoàn toàn 3.6 gam Mg (M = 24) trong dung dịch HNO₃ đặc, nóng dư thu được V lít khí NO₂ (sản phẩm khử duy nhất, ở ĐKC 24.79 lít/mol). Tính V (làm tròn đến hàng phần trăm).', NULL, NULL, NULL, NULL, '7.44', 'n_Mg = 0.15 mol ⇒ n_NO₂ = 0.3 mol ⇒ V = 0.3 × 24.79 = 7.437 ≈ 7.44 lít.', 0.25, 'Thông hiểu', 25),
(19, 'short_answer', 'Thủy phân hoàn toàn 16.2 gam tinh bột thành glucozơ (M = 180) với hiệu suất 80%. Khối lượng glucozơ thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '14.4', 'n_tinh bột = 0.1 mol ⇒ m_glu = 0.1 × 0.8 × 180 = 14.4 gam.', 0.25, 'Thông hiểu', 26),
(19, 'short_answer', 'Cho phương trình hóa học: a Fe + b HNO₃(loãng) → c Fe(NO₃)₃ + d NO + e H₂O (với a, b, c, d, e là các số nguyên tối giản). Tính tổng (a + b + c + d + e).', NULL, NULL, NULL, NULL, '9', 'Fe + 4HNO₃ → Fe(NO₃)₃ + NO + 2H₂O ⇒ 1 + 4 + 1 + 1 + 2 = 9.', 0.25, 'Thông hiểu', 27),
(19, 'short_answer', 'Để thủy phân hoàn toàn 0.2 mol hỗn hợp gồm metyl fomat và etyl axetat cần vừa đủ bao nhiêu mol NaOH?', NULL, NULL, NULL, NULL, '0.2', 'Cả hai đều là este đơn chức của ancol nên phản ứng với NaOH theo tỉ lệ 1:1 ⇒ cần 0.2 mol NaOH.', 0.25, 'Nhận biết', 28),
(20, 'mcq', 'Chất nào sau đây có vị ngọt sắc, nhiều trong mật ong?', 'Xenlulozơ', 'Axit axetic', 'Tinh bột', 'Fructozơ', 'D', 'Fructozơ có nhiều trong mật ong (chiếm ~40%).', 0.25, 'Nhận biết', 1),
(20, 'mcq', 'Khi đốt cháy hoàn toàn một este no, đơn chức, mạch hở, ta luôn thu được:', 'n_CO₂ = n_H₂O', 'n_H₂O = 2n_CO₂', 'n_CO₂ > n_H₂O', 'n_CO₂ < n_H₂O', 'A', 'Este no đơn chức mạch hở CₙH₂ₙO₂ khi đốt cho n_CO₂ = n_H₂O.', 0.25, 'Nhận biết', 2),
(20, 'mcq', 'Số nguyên tử cacbon trong phân tử axit glutamic là:', '5', '2', '3', '6', 'A', 'HOOC-CH₂-CH₂-CH(NH₂)-COOH có 5 nguyên tử C.', 0.25, 'Nhận biết', 3),
(20, 'mcq', 'Chất nào sau đây thuộc loại polime thiên nhiên?', 'Tơ visco', 'Polietilen', 'Tinh bột', 'Nilon-6', 'C', 'Tinh bột có sẵn trong tự nhiên; tơ visco là bán tổng hợp; PE và nilon-6 là tổng hợp.', 0.25, 'Nhận biết', 4),
(20, 'mcq', 'Kim loại nào sau đây có tính dẫn điện tốt nhất?', 'Bạc (Ag)', 'Đồng (Cu)', 'Vàng (Au)', 'Nhôm (Al)', 'A', 'Thứ tự dẫn điện: Ag > Cu > Au > Al > Fe.', 0.25, 'Nhận biết', 5),
(20, 'mcq', 'Trong công nghiệp, quặng boxit là nguyên liệu chính để sản xuất kim loại nào?', 'Kẽm (Zn)', 'Sắt (Fe)', 'Đồng (Cu)', 'Nhôm (Al)', 'D', 'Quặng boxit (Al₂O₃.2H₂O) dùng để sản xuất nhôm.', 0.25, 'Nhận biết', 6),
(20, 'mcq', 'Chất nào sau đây tác dụng với dung dịch FeCl₂ tạo kết tủa trắng hơi xanh?', 'NaCl', 'NaOH', 'CuSO₄', 'HCl', 'B', 'FeCl₂ + 2NaOH → Fe(OH)₂↓ (trắng xanh) + 2NaCl.', 0.25, 'Nhận biết', 7),
(20, 'mcq', 'Kim loại nào sau đây bị thụ động hóa trong dung dịch HNO₃ đặc, nguội?', 'Sắt (Fe) và Nhôm (Al)', 'Kẽm (Zn)', 'Magie (Mg)', 'Đồng (Cu)', 'A', 'Al, Fe, Cr bị thụ động hóa trong HNO₃ đặc nguội và H₂SO₄ đặc nguội.', 0.25, 'Nhận biết', 8),
(20, 'mcq', 'Cặp chất nào sau đây KHÔNG phải là đồng phân của nhau?', 'Glucozơ và Saccarozơ', 'Glucozơ và Fructozơ', 'Etyl axetat và Axit butiric', 'Axit axetic và Metyl fomat', 'A', 'Glucozơ (C₆H₁₂O₆) và Saccarozơ (C₁₂H₂₂O₁₁) khác CTPT nên không phải đồng phân.', 0.25, 'Thông hiểu', 9),
(20, 'mcq', 'Thủy phân hoàn toàn tristearin thu được glixerol và:', 'Axit stearic (hoặc muối stearat)', 'Axit axetic', 'Axit panmitic', 'Axit oleic', 'A', 'Tristearin là trieste của axit stearic C₁₇H₃₅COOH.', 0.25, 'Nhận biết', 10),
(20, 'mcq', 'Khi bảo quản kim loại natri (Na) trong phòng thí nghiệm, người ta thường ngâm Na trong:', 'Ancol etylic', 'Nước cất', 'Dung dịch HCl', 'Dầu hỏa', 'D', 'Na phản ứng mạnh với nước và ancol, nhẹ hơn nước nên được bảo quản bằng cách ngâm ngập trong dầu hỏa.', 0.25, 'Nhận biết', 11),
(20, 'mcq', 'Trong pin điện hóa, quá trình oxi hóa luôn xảy ra ở:', 'Điện cực dương (catot)', 'Cầu muối', 'Mạch ngoài', 'Điện cực âm (anot)', 'D', 'Tại anot (cực âm) luôn xảy ra quá trình oxi hóa (nhường electron).', 0.25, 'Nhận biết', 12),
(20, 'mcq', 'Cho 6 gam axit axetic (M = 60) tác dụng với lượng dư ancol etylic (xúc tác H₂SO₄ đặc, đun nóng) với hiệu suất 75%. Khối lượng etyl axetat (M = 88) thu được là:', '7.5 gam', '6.6 gam', '8.8 gam', '4.4 gam', 'B', 'n_axit = 0.1 mol ⇒ m_este = 0.1 × 0.75 × 88 = 6.6 gam.', 0.25, 'Thông hiểu', 13),
(20, 'mcq', 'Cho 2.7 gam Al (M = 27) tác dụng hết với dung dịch NaOH dư. Thể tích khí H₂ thoát ra ở ĐKC (24.79 lít/mol) là:', '3.718 lít', '7.437 lít', '2.479 lít', '4.958 lít', 'A', 'n_Al = 0.1 mol ⇒ n_H₂ = 1.5 × 0.1 = 0.15 mol ⇒ V = 0.15 × 24.79 = 3.7185 lít.', 0.25, 'Thông hiểu', 14),
(20, 'mcq', 'Cho dung dịch chứa 10.6 gam Na₂CO₃ (M = 106) tác dụng với lượng dư dung dịch CaCl₂. Khối lượng kết tủa CaCO₃ (M = 100) thu được là:', '20 gam', '5 gam', '10 gam', '15 gam', 'C', 'n_Na₂CO₃ = 0.1 mol ⇒ n_CaCO₃ = 0.1 mol ⇒ m = 10 gam.', 0.25, 'Nhận biết', 15),
(20, 'mcq', 'Số đồng phân amin bậc một ứng với công thức phân tử C₃H₉N là:', '4', '2', '3', '1', 'B', 'Gồm CH₃-CH₂-CH₂-NH₂ và CH₃-CH(NH₂)-CH₃ (2 đồng phân bậc 1).', 0.25, 'Thông hiểu', 16),
(20, 'mcq', 'Chất nào sau đây có thể dùng để phân biệt dung dịch glucozơ và dung dịch saccarozơ?', 'Nước cất', 'Thuốc thử Tollens (AgNO₃/NH₃)', 'Dung dịch NaCl', 'Quỳ tím', 'B', 'Glucozơ có phản ứng tráng bạc với AgNO₃/NH₃, còn saccarozơ không phản ứng.', 0.25, 'Thông hiểu', 17),
(20, 'mcq', 'Cho 12 gam hỗn hợp Cu và Fe tác dụng hoàn toàn với dung dịch HCl dư, thu được 2.479 lít khí H₂ (ĐKC 24.79 lít/mol). Khối lượng Cu trong hỗn hợp ban đầu là (Fe = 56):', '6.0 gam', '6.4 gam', '5.6 gam', '3.2 gam', 'B', 'Chỉ Fe phản ứng: n_Fe = n_H₂ = 0.1 mol ⇒ m_Fe = 5.6 g ⇒ m_Cu = 12 - 5.6 = 6.4 gam.', 0.25, 'Thông hiểu', 18),
(20, 'true_false', 'Cho các polime sau: polietilen (PE), poli(vinyl clorua) (PVC), tơ nilon-6,6 và tinh bột.', 'a) PE được tổng hợp từ monome etilen (CH₂=CH₂).', 'b) Trong phân tử PVC có chứa nguyên tố clo.', 'c) Tơ nilon-6,6 thuộc loại tơ poliamit.', 'd) Cả 4 polime trên đều thuộc loại polime tổng hợp.', 'D,D,D,S', 'a) Đúng.
b) Đúng.
c) Đúng (chứa nhóm -CO-NH-).
d) Sai: Tinh bột là polime thiên nhiên.', 1.00, 'Thông hiểu', 19),
(20, 'true_false', 'Cho dung dịch axit glutamic (HOOC-CH₂-CH₂-CH(NH₂)-COOH, M = 147).', 'a) Dung dịch axit glutamic làm quỳ tím chuyển sang màu hồng/đỏ.', 'b) Muối mononatri của axit glutamic (bột ngọt/mì chính) được dùng làm gia vị thực phẩm.', 'c) Một mol axit glutamic phản ứng tối đa với 2 mol NaOH.', 'd) Một mol axit glutamic phản ứng tối đa với 2 mol HCl.', 'D,D,D,S', 'a) Đúng (2 nhóm COOH, 1 nhóm NH₂).
b) Đúng.
c) Đúng.
d) Sai: Chỉ có 1 nhóm NH₂ nên phản ứng tối đa với 1 mol HCl.', 1.00, 'Thông hiểu', 20),
(20, 'true_false', 'Thực hiện thí nghiệm điện phân dung dịch NaCl bão hòa có màng ngăn xốp với điện cực trơ.', 'a) Tại catot (cực âm) thu được khí H₂ và dung dịch NaOH.', 'b) Tại anot (cực dương) thu được khí Cl₂.', 'c) Nếu không có màng ngăn xốp, sản phẩm thu được sẽ là nước Javen (NaCl, NaClO).', 'd) Kim loại Na sinh ra bám trực tiếp vào điện cực catot.', 'D,D,D,S', 'a) Đúng: 2H₂O + 2e → H₂↑ + 2OH⁻.
b) Đúng: 2Cl⁻ → Cl₂↑ + 2e.
c) Đúng: Cl₂ + 2NaOH → NaCl + NaClO + H₂O.
d) Sai: Trong dung dịch nước, ion Na⁺ không bị khử mà H₂O bị khử tạo H₂.', 1.00, 'Vận dụng', 21),
(20, 'true_false', 'Cho 13.44 gam sắt (Fe = 56) tác dụng với 200 ml dung dịch AgNO₃ 2M đến khi phản ứng hoàn toàn.', 'a) Số mol Fe ban đầu là 0.24 mol.', 'b) Số mol AgNO₃ ban đầu là 0.40 mol.', 'c) Sau phản ứng, kim loại thu được chỉ gồm Ag.', 'd) Tổng khối lượng kim loại thu được sau phản ứng bằng 45.44 gam.', 'D,D,S,D', 'a) Đúng: 13.44/56 = 0.24 mol.
b) Đúng: 0.2×2 = 0.40 mol.
c) Sai: 2n_Fe = 0.48 > n_Ag⁺ = 0.40 ⇒ Fe dư, tạo Fe(NO₃)₂ và hỗn hợp kim loại gồm Ag và Fe dư.
d) Đúng: n_Fe phản ứng = 0.20 mol ⇒ Fe dư = 0.04 mol (2.24 g); m_Ag = 0.40×108 = 43.2 g ⇒ Tổng = 45.44 g.', 1.00, 'Vận dụng cao', 22),
(20, 'short_answer', 'Thủy phân hoàn toàn 14.8 gam metyl axetat (CH₃COOCH₃, M = 74) bằng dung dịch NaOH dư. Khối lượng ancol metylic (CH₃OH, M = 32) thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '6.4', 'n_este = 14.8/74 = 0.2 mol ⇒ m_ancol = 0.2 × 32 = 6.4 gam.', 0.25, 'Nhận biết', 23),
(20, 'short_answer', 'Cho 18 gam glucozơ (C₆H₁₂O₆, M = 180) tác dụng hoàn toàn với lượng dư dung dịch AgNO₃ trong NH₃, đun nóng. Khối lượng bạc (Ag = 108) thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '21.6', 'n_glu = 0.1 mol ⇒ n_Ag = 0.2 mol ⇒ m_Ag = 0.2 × 108 = 21.6 gam.', 0.25, 'Nhận biết', 24),
(20, 'short_answer', 'Hấp thụ hoàn toàn 2.479 lít khí CO₂ (ở ĐKC 24.79 lít/mol) vào lượng dư dung dịch Ca(OH)₂. Khối lượng kết tủa CaCO₃ (M = 100) thu được là bao nhiêu gam?', NULL, NULL, NULL, NULL, '10', 'n_CO₂ = 0.1 mol ⇒ n_CaCO₃ = 0.1 mol ⇒ m = 0.1 × 100 = 10 gam.', 0.25, 'Nhận biết', 25),
(20, 'short_answer', 'Cho thế điện cực chuẩn E°(Mg²⁺/Mg) = -2.37 V và E°(Ag⁺/Ag) = +0.80 V. Tính sức điện động chuẩn của pin điện hóa Mg - Ag theo đơn vị Volt.', NULL, NULL, NULL, NULL, '3.17', 'E°_pin = E°(Ag⁺/Ag) - E°(Mg²⁺/Mg) = 0.80 - (-2.37) = 3.17 V.', 0.25, 'Thông hiểu', 26),
(20, 'short_answer', 'Đốt cháy hoàn toàn 0.1 mol tripeptit mạch hở Ala-Ala-Ala thu được bao nhiêu mol khí N₂?', NULL, NULL, NULL, NULL, '0.15', 'Tripeptit có 3 nguyên tử N ⇒ n_N₂ = (0.1 × 3)/2 = 0.15 mol.', 0.25, 'Thông hiểu', 27),
(20, 'short_answer', 'Điện phân dung dịch CuSO₄ với điện cực trơ, cường độ dòng điện không đổi I = 9.65 A trong thời gian 2000 giây (lấy F = 96500 C/mol). Khối lượng đồng (Cu = 64) bám vào catot là bao nhiêu gam?', NULL, NULL, NULL, NULL, '6.4', 'n_e = I.t/F = (9.65 × 2000)/96500 = 0.2 mol ⇒ n_Cu = 0.1 mol ⇒ m_Cu = 6.4 gam.', 0.25, 'Vận dụng', 28);
