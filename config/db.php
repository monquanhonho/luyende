<?php
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

date_default_timezone_set('Asia/Ho_Chi_Minh');

$db_host = '127.0.0.1';
$db_name = 'webluyende';
$db_user = 'root';
$db_pass = '';

try {
    $pdo = new PDO("mysql:host=$db_host;charset=utf8mb4", $db_user, $db_pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
    ]);

    $sqlFile = __DIR__ . '/../database.sql';

    // Kiểm tra xem database `webluyende` đã tồn tại chưa, nếu chưa thì tự động khởi tạo từ database.sql
    $stmt = $pdo->query("SHOW DATABASES LIKE '$db_name'");
    $dbExists = (bool)$stmt->fetch();

    if (!$dbExists && file_exists($sqlFile)) {
        $pdo->exec(file_get_contents($sqlFile));
    }

    $pdo->exec("USE `$db_name`");

    // Tự động nâng cấp nếu DB đang ở phiên bản cũ (chưa có cột `question_type` chuẩn form 2025)
    $colCheck = $pdo->query("SHOW COLUMNS FROM `questions` LIKE 'question_type'");
    if (!$colCheck->fetch() && file_exists($sqlFile)) {
        $pdo->exec(file_get_contents($sqlFile));
    }

    // Tự động bổ sung các cột & bảng giám sát học sinh nếu chưa có (không làm mất dữ liệu)
    if (!$pdo->query("SHOW COLUMNS FROM `users` LIKE 'last_active_at'")->fetch()) {
        $pdo->exec("ALTER TABLE `users` ADD COLUMN `last_active_at` TIMESTAMP NULL DEFAULT NULL AFTER `role`");
    }
    if (!$pdo->query("SHOW COLUMNS FROM `exam_attempts` LIKE 'tab_switch_count'")->fetch()) {
        $pdo->exec("ALTER TABLE `exam_attempts` ADD COLUMN `tab_switch_count` INT NOT NULL DEFAULT 0 AFTER `time_spent_seconds`");
    }
    $pdo->exec("CREATE TABLE IF NOT EXISTS `exam_sessions` (
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
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci");

    // Cập nhật thời gian hoạt động gần nhất của tài khoản đang đăng nhập
    if (isset($_SESSION['user']['id'])) {
        $pingStmt = $pdo->prepare("UPDATE `users` SET `last_active_at` = NOW() WHERE `id` = ?");
        $pingStmt->execute([(int)$_SESSION['user']['id']]);
    }
} catch (PDOException $e) {
    die('<div style="font-family:sans-serif;max-width:600px;margin:60px auto;padding:24px;border-radius:12px;background:#fef2f2;border:1px solid #fecaca;color:#991b1b;">
        <h2 style="margin-top:0;">⚠️ Không thể kết nối Cơ sở dữ liệu MySQL</h2>
        <p>Vui lòng kiểm tra xem <b>MySQL trong XAMPP</b> đã được bật (Start) chưa, hoặc import file <code>database.sql</code> vào phpMyAdmin.</p>
        <p style="font-size:13px;color:#b91c1c;">Chi tiết lỗi: ' . htmlspecialchars($e->getMessage()) . '</p>
    </div>');
}

// Các hàm tiện ích phân quyền & giao diện
function isLoggedIn(): bool {
    return isset($_SESSION['user']);
}

function currentUser(): ?array {
    return $_SESSION['user'] ?? null;
}

function isAdmin(): bool {
    return isLoggedIn() && ($_SESSION['user']['role'] === 'admin');
}

function isStudent(): bool {
    return isLoggedIn() && ($_SESSION['user']['role'] === 'student');
}

function requireLogin(): void {
    if (!isLoggedIn()) {
        $_SESSION['flash_error'] = 'Vui lòng đăng nhập để tiếp tục luyện đề!';
        header('Location: login.php');
        exit;
    }
}

function requireAdmin(): void {
    requireLogin();
    if (!isAdmin()) {
        $_SESSION['flash_error'] = 'Khu vực này chỉ dành cho Quản trị viên (Admin)!';
        header('Location: index.php');
        exit;
    }
}

function formatDuration(int $seconds): string {
    $mins = floor($seconds / 60);
    $secs = $seconds % 60;
    if ($mins > 0) {
        return sprintf('%d phút %02d giây', $mins, $secs);
    }
    return sprintf('%d giây', $secs);
}

function getSubjectBadgeStyle(string $code): array {
    $map = [
        'TOAN' => [
            'bg' => 'bg-blue-50',
            'text' => 'text-blue-700',
            'border' => 'border-blue-200',
            'badge' => 'bg-blue-600 text-white',
            'soft_icon' => 'bg-blue-100 text-blue-600',
            'ring' => 'focus:ring-blue-500',
            'gradient' => 'from-blue-600 to-indigo-600',
            'btn' => 'bg-blue-600 hover:bg-blue-700',
        ],
        'ANH' => [
            'bg' => 'bg-emerald-50',
            'text' => 'text-emerald-700',
            'border' => 'border-emerald-200',
            'badge' => 'bg-emerald-600 text-white',
            'soft_icon' => 'bg-emerald-100 text-emerald-600',
            'ring' => 'focus:ring-emerald-500',
            'gradient' => 'from-emerald-500 to-teal-600',
            'btn' => 'bg-emerald-600 hover:bg-emerald-700',
        ],
        'LY' => [
            'bg' => 'bg-amber-50',
            'text' => 'text-amber-700',
            'border' => 'border-amber-200',
            'badge' => 'bg-amber-500 text-white',
            'soft_icon' => 'bg-amber-100 text-amber-600',
            'ring' => 'focus:ring-amber-500',
            'gradient' => 'from-amber-500 to-orange-600',
            'btn' => 'bg-amber-600 hover:bg-amber-700',
        ],
        'HOA' => [
            'bg' => 'bg-rose-50',
            'text' => 'text-rose-700',
            'border' => 'border-rose-200',
            'badge' => 'bg-rose-600 text-white',
            'soft_icon' => 'bg-rose-100 text-rose-600',
            'ring' => 'focus:ring-rose-500',
            'gradient' => 'from-rose-500 to-pink-600',
            'btn' => 'bg-rose-600 hover:bg-rose-700',
        ],
    ];
    return $map[$code] ?? $map['TOAN'];
}

function getDifficultyBadgeStyle(string $difficulty): array {
    $map = [
        'Nhận biết' => [
            'pill' => 'bg-emerald-50 text-emerald-700 border-emerald-200',
            'bar' => 'bg-emerald-500',
            'icon' => 'fa-seedling',
        ],
        'Thông hiểu' => [
            'pill' => 'bg-sky-50 text-sky-700 border-sky-200',
            'bar' => 'bg-sky-500',
            'icon' => 'fa-lightbulb',
        ],
        'Vận dụng' => [
            'pill' => 'bg-amber-50 text-amber-700 border-amber-200',
            'bar' => 'bg-amber-500',
            'icon' => 'fa-gears',
        ],
        'Vận dụng cao' => [
            'pill' => 'bg-rose-50 text-rose-700 border-rose-200',
            'bar' => 'bg-rose-500',
            'icon' => 'fa-fire',
        ],
    ];
    return $map[$difficulty] ?? $map['Nhận biết'];
}

function getQuestionTypeInfo(string $type): array {
    $map = [
        'mcq' => [
            'label' => 'Phần I: Trắc nghiệm nhiều phương án lựa chọn',
            'short' => 'TN ABCD',
            'desc' => 'Thí sinh chọn 1 phương án đúng nhất (A, B, C hoặc D). Mỗi câu trả lời đúng được 0.25 điểm.',
            'pill' => 'bg-indigo-50 text-indigo-800 border-indigo-200',
            'bar' => 'bg-indigo-600',
            'icon' => 'fa-list-ul',
        ],
        'true_false' => [
            'label' => 'Phần II: Trắc nghiệm Đúng / Sai (4 ý a, b, c, d)',
            'short' => 'Đúng / Sai',
            'desc' => 'Thang điểm lũy tiến Bộ GD&ĐT 2025: Đúng 1 ý được 0.10đ • 2 ý: 0.25đ • 3 ý: 0.50đ • cả 4 ý: 1.00đ.',
            'pill' => 'bg-violet-50 text-violet-800 border-violet-200',
            'bar' => 'bg-violet-600',
            'icon' => 'fa-check-double',
        ],
        'short_answer' => [
            'label' => 'Phần III: Trắc nghiệm Trả lời ngắn',
            'short' => 'Trả lời ngắn',
            'desc' => 'Thí sinh tính toán và điền trực tiếp kết quả số vào ô trả lời (dùng dấu chấm cho số thập phân).',
            'pill' => 'bg-teal-50 text-teal-800 border-teal-200',
            'bar' => 'bg-teal-600',
            'icon' => 'fa-keyboard',
        ],
    ];
    return $map[$type] ?? $map['mcq'];
}

/**
 * Chấm điểm một câu hỏi theo chuẩn Bộ GD&ĐT từ năm 2025
 */
function gradeQuestion(array $q, $rawAnswer): array {
    $type = $q['question_type'] ?? 'mcq';
    $maxPoints = (float)($q['points_value'] ?? 0.25);

    if ($type === 'true_false') {
        $expectedParts = array_map('trim', explode(',', strtoupper($q['correct_option'])));
        $selectedArr = is_array($rawAnswer) ? $rawAnswer : [];
        $userParts = [];
        $correctItems = 0;

        foreach (['a', 'b', 'c', 'd'] as $idx => $key) {
            $val = isset($selectedArr[$key]) ? strtoupper(trim((string)$selectedArr[$key])) : '';
            if (!in_array($val, ['D', 'S'], true)) {
                $val = '';
            }
            $userParts[] = $val;
            if ($val !== '' && isset($expectedParts[$idx]) && $val === $expectedParts[$idx]) {
                $correctItems++;
            }
        }

        $scoreTable = [0 => 0.00, 1 => 0.10, 2 => 0.25, 3 => 0.50, 4 => 1.00];
        $earned = $scoreTable[$correctItems] ?? 0.00;
        $storedSelection = implode(',', $userParts);
        if ($storedSelection === ',,,') {
            $storedSelection = null;
        }

        return [
            'selected_option' => $storedSelection,
            'is_correct' => ($correctItems === 4) ? 1 : 0,
            'earned_points' => $earned,
            'correct_items' => $correctItems,
        ];
    }

    if ($type === 'short_answer') {
        $rawStr = is_string($rawAnswer) ? trim($rawAnswer) : '';
        if ($rawStr === '') {
            return [
                'selected_option' => null,
                'is_correct' => 0,
                'earned_points' => 0.00,
                'correct_items' => 0,
            ];
        }

        $normUser = str_replace([',', ' '], ['.', ''], $rawStr);
        $normExpected = str_replace([',', ' '], ['.', ''], trim($q['correct_option']));

        $isRight = false;
        if (strcasecmp($normUser, $normExpected) === 0) {
            $isRight = true;
        } elseif (is_numeric($normUser) && is_numeric($normExpected)) {
            $isRight = (abs((float)$normUser - (float)$normExpected) < 0.0001);
        }

        return [
            'selected_option' => $rawStr,
            'is_correct' => $isRight ? 1 : 0,
            'earned_points' => $isRight ? $maxPoints : 0.00,
            'correct_items' => $isRight ? 1 : 0,
        ];
    }

    // Mặc định: mcq
    $selected = is_string($rawAnswer) ? strtoupper(trim($rawAnswer)) : '';
    if (!in_array($selected, ['A', 'B', 'C', 'D'], true)) {
        $selected = null;
    }
    $isRight = ($selected !== null && $selected === strtoupper(trim($q['correct_option'])));

    return [
        'selected_option' => $selected,
        'is_correct' => $isRight ? 1 : 0,
        'earned_points' => $isRight ? $maxPoints : 0.00,
        'correct_items' => $isRight ? 1 : 0,
    ];
}
