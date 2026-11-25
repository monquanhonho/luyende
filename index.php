<?php
require_once __DIR__ . '/config/db.php';

$selectedSubjectCode = trim($_GET['subject'] ?? '');
$searchQuery = trim($_GET['q'] ?? '');
$selectedLevel = trim($_GET['level'] ?? '');

// Lấy danh sách 4 môn học kèm tổng số đề thi
$subjectsStmt = $pdo->query("
    SELECT s.*, COUNT(e.id) AS exam_count
    FROM subjects s
    LEFT JOIN exams e ON e.subject_id = s.id AND e.is_active = 1
    GROUP BY s.id
    ORDER BY s.id ASC
");
$subjects = $subjectsStmt->fetchAll();

// Truy vấn danh sách đề thi theo bộ lọc
$where = ['e.is_active = 1'];
$params = [];

if ($selectedSubjectCode !== '') {
    $where[] = 's.code = ?';
    $params[] = $selectedSubjectCode;
}
if ($selectedLevel !== '') {
    $where[] = 'e.level = ?';
    $params[] = $selectedLevel;
}
if ($searchQuery !== '') {
    $where[] = '(e.title LIKE ? OR e.description LIKE ? OR s.name LIKE ?)';
    $params[] = "%$searchQuery%";
    $params[] = "%$searchQuery%";
    $params[] = "%$searchQuery%";
}

$whereSql = implode(' AND ', $where);

$examsStmt = $pdo->prepare("
    SELECT e.*, s.code AS subject_code, s.name AS subject_name, s.icon AS subject_icon,
           (SELECT COUNT(*) FROM questions q WHERE q.exam_id = e.id) AS question_count,
           (SELECT COUNT(*) FROM questions q WHERE q.exam_id = e.id AND q.question_type = 'mcq') AS mcq_count,
           (SELECT COUNT(*) FROM questions q WHERE q.exam_id = e.id AND q.question_type = 'true_false') AS tf_count,
           (SELECT COUNT(*) FROM questions q WHERE q.exam_id = e.id AND q.question_type = 'short_answer') AS sa_count,
           (SELECT MIN(points_value) FROM questions q WHERE q.exam_id = e.id) AS min_point,
           (SELECT COUNT(*) FROM exam_attempts ea WHERE ea.exam_id = e.id) AS attempt_count
    FROM exams e
    JOIN subjects s ON e.subject_id = s.id
    WHERE $whereSql
    ORDER BY s.id ASC, e.id ASC
");
$examsStmt->execute($params);
$exams = $examsStmt->fetchAll();

// Lấy điểm cao nhất của học sinh hiện tại cho từng đề (nếu đã đăng nhập)
$userBestScores = [];
$userStats = ['total_attempts' => 0, 'avg_score' => 0, 'best_score' => 0];
if (isLoggedIn()) {
    $uid = currentUser()['id'];
    $bestStmt = $pdo->prepare("
        SELECT exam_id, MAX(score) AS best_score, COUNT(*) AS my_attempts
        FROM exam_attempts
        WHERE user_id = ?
        GROUP BY exam_id
    ");
    $bestStmt->execute([$uid]);
    foreach ($bestStmt->fetchAll() as $row) {
        $userBestScores[(int)$row['exam_id']] = $row;
    }

    $statStmt = $pdo->prepare("
        SELECT COUNT(*) AS total_attempts, COALESCE(AVG(score), 0) AS avg_score, COALESCE(MAX(score), 0) AS best_score
        FROM exam_attempts
        WHERE user_id = ?
    ");
    $statStmt->execute([$uid]);
    $userStats = $statStmt->fetch();
}

// Nhóm các đề theo môn học để hiển thị phân chia rõ ràng
$examsBySubject = [];
foreach ($exams as $exam) {
    $examsBySubject[$exam['subject_code']][] = $exam;
}

$pageTitle = 'Kho Đề Luyện Tập Toán • Anh • Lý • Hóa';
require_once __DIR__ . '/includes/header.php';
?>

<!-- Banner Hero -->
<section class="relative overflow-hidden bg-gradient-to-br from-slate-900 via-indigo-950 to-slate-900 text-white">
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-10 sm:py-12 relative z-10">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
            <div class="lg:col-span-7">
                <div class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-indigo-500/20 border border-indigo-400/30 text-indigo-200 text-xs font-semibold mb-4">
                    <span class="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
                    Phòng Luyện Đề Trực Tuyến THPT Quốc Gia
                </div>
                <h1 class="text-3xl sm:text-4xl font-extrabold tracking-tight leading-tight">
                    Luyện Đề Trắc Nghiệm <span class="bg-gradient-to-r from-blue-400 via-teal-300 to-amber-300 bg-clip-text text-transparent">Toán • Anh • Lý • Hóa</span>
                </h1>
                <p class="text-slate-300 text-sm sm:text-base mt-3 max-w-2xl leading-relaxed">
                    Kho đề được phân chia rõ ràng theo từng bộ môn và mức độ nhận thức. Học sinh làm bài trực tiếp, bấm giờ tự động và xem lời giải chi tiết ngay sau khi nộp bài.
                </p>

                <?php if (!isLoggedIn()): ?>
                    <div class="mt-6 flex flex-wrap items-center gap-3">
                        <a href="login.php" class="px-5 py-3 rounded-xl bg-indigo-500 hover:bg-indigo-600 text-white font-bold text-sm shadow-lg shadow-indigo-500/30 transition flex items-center gap-2">
                            <i class="fa-solid fa-play"></i> Đăng nhập làm bài ngay
                        </a>
                        <a href="register.php" class="px-5 py-3 rounded-xl bg-white/10 hover:bg-white/20 text-white font-bold text-sm border border-white/20 transition flex items-center gap-2">
                            <i class="fa-solid fa-user-plus"></i> Đăng ký Học sinh
                        </a>
                    </div>
                <?php endif; ?>
            </div>

            <!-- Thống kê nhanh cho Học sinh / Hệ thống -->
            <div class="lg:col-span-5">
                <?php if (isLoggedIn()): ?>
                    <div class="bg-white/10 backdrop-blur-md border border-white/15 rounded-3xl p-6">
                        <div class="flex items-center justify-between mb-4">
                            <div>
                                <span class="text-xs uppercase tracking-wider text-indigo-200 font-bold">Tiến độ học tập của bạn</span>
                                <h3 class="text-lg font-extrabold text-white"><?= htmlspecialchars(currentUser()['fullname']) ?></h3>
                            </div>
                            <a href="history.php" class="text-xs font-bold px-3 py-1.5 rounded-xl bg-white/15 hover:bg-white/25 transition">
                                Xem lịch sử &rarr;
                            </a>
                        </div>
                        <div class="grid grid-cols-3 gap-3 text-center">
                            <div class="bg-slate-900/50 rounded-2xl p-3.5 border border-white/10">
                                <div class="text-2xl font-extrabold text-blue-300"><?= (int)$userStats['total_attempts'] ?></div>
                                <div class="text-[11px] text-slate-300 mt-0.5">Đề đã luyện</div>
                            </div>
                            <div class="bg-slate-900/50 rounded-2xl p-3.5 border border-white/10">
                                <div class="text-2xl font-extrabold text-emerald-300"><?= number_format((float)$userStats['avg_score'], 1) ?></div>
                                <div class="text-[11px] text-slate-300 mt-0.5">Điểm TB</div>
                            </div>
                            <div class="bg-slate-900/50 rounded-2xl p-3.5 border border-white/10">
                                <div class="text-2xl font-extrabold text-amber-300"><?= number_format((float)$userStats['best_score'], 1) ?></div>
                                <div class="text-[11px] text-slate-300 mt-0.5">Điểm cao nhất</div>
                            </div>
                        </div>
                    </div>
                <?php else: ?>
                    <div class="grid grid-cols-2 gap-3">
                        <?php foreach ($subjects as $sub): ?>
                            <a href="index.php?subject=<?= urlencode($sub['code']) ?>" class="p-4 rounded-2xl bg-white/10 hover:bg-white/15 border border-white/15 transition flex items-center gap-3.5">
                                <div class="w-11 h-11 rounded-xl bg-gradient-to-br <?= htmlspecialchars($sub['gradient']) ?> flex items-center justify-center text-white text-lg shadow">
                                    <i class="fa-solid <?= htmlspecialchars($sub['icon']) ?>"></i>
                                </div>
                                <div>
                                    <div class="font-bold text-sm text-white"><?= htmlspecialchars($sub['name']) ?></div>
                                    <div class="text-xs text-slate-300"><?= (int)$sub['exam_count'] ?> đề luyện tập</div>
                                </div>
                            </a>
                        <?php endforeach; ?>
                    </div>
                <?php endif; ?>
            </div>
        </div>
    </div>
</section>

<!-- Khu vực Phân chia 4 môn học rõ ràng (Cards chọn môn) -->
<section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 -mt-6 relative z-20">
    <div class="grid grid-cols-2 lg:grid-cols-5 gap-3 sm:gap-4">
        <!-- Nút Tất cả các môn -->
        <a href="index.php" class="card-hover p-4 rounded-2xl border transition flex items-center gap-3.5 <?= $selectedSubjectCode === '' ? 'bg-indigo-600 text-white border-indigo-600 shadow-lg shadow-indigo-500/25' : 'bg-white text-slate-700 border-slate-200/80 shadow-sm' ?>">
            <div class="w-11 h-11 rounded-xl flex items-center justify-center text-lg <?= $selectedSubjectCode === '' ? 'bg-white/20 text-white' : 'bg-indigo-50 text-indigo-600' ?>">
                <i class="fa-solid fa-layer-group"></i>
            </div>
            <div>
                <div class="font-extrabold text-sm">Tất Cả Môn</div>
                <div class="text-xs <?= $selectedSubjectCode === '' ? 'text-indigo-100' : 'text-slate-400' ?>">4 môn học</div>
            </div>
        </a>

        <?php foreach ($subjects as $sub):
            $isActiveSub = ($selectedSubjectCode === $sub['code']);
            $style = getSubjectBadgeStyle($sub['code']);
        ?>
            <a href="index.php?subject=<?= urlencode($sub['code']) ?>"
               class="card-hover p-4 rounded-2xl border transition flex items-center gap-3.5 <?= $isActiveSub ? 'bg-gradient-to-r ' . $style['gradient'] . ' text-white border-transparent shadow-lg' : 'bg-white text-slate-800 border-slate-200/80 shadow-sm' ?>">
                <div class="w-11 h-11 rounded-xl flex items-center justify-center text-lg shrink-0 <?= $isActiveSub ? 'bg-white/20 text-white' : $style['soft_icon'] ?>">
                    <i class="fa-solid <?= htmlspecialchars($sub['icon']) ?>"></i>
                </div>
                <div class="min-w-0">
                    <div class="font-extrabold text-sm truncate"><?= htmlspecialchars($sub['name']) ?></div>
                    <div class="text-xs <?= $isActiveSub ? 'text-white/85' : 'text-slate-500' ?>"><?= (int)$sub['exam_count'] ?> đề thi chuẩn</div>
                </div>
            </a>
        <?php endforeach; ?>
    </div>
</section>

<!-- Thanh tìm kiếm & lọc mức độ đề -->
<section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8">
    <form method="GET" action="index.php" class="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <?php if ($selectedSubjectCode !== ''): ?>
            <input type="hidden" name="subject" value="<?= htmlspecialchars($selectedSubjectCode) ?>">
        <?php endif; ?>

        <div class="relative flex-1">
            <span class="absolute inset-y-0 left-0 pl-4 flex items-center text-slate-400">
                <i class="fa-solid fa-magnifying-glass"></i>
            </span>
            <input type="text" name="q" value="<?= htmlspecialchars($searchQuery) ?>"
                   placeholder="Tìm kiếm đề thi theo chuyên đề (VD: Hàm số, Ngữ pháp, Dao động, Este...)"
                   class="w-full pl-11 pr-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 focus:bg-white focus:border-indigo-500 outline-none text-sm">
        </div>

        <select name="level" onchange="this.form.submit()" class="px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm font-semibold text-slate-700 outline-none focus:border-indigo-500">
            <option value="">🎯 Tất cả mức độ</option>
            <option value="Chuẩn THPT QG" <?= $selectedLevel === 'Chuẩn THPT QG' ? 'selected' : '' ?>>Chuẩn THPT QG</option>
            <option value="Cơ bản" <?= $selectedLevel === 'Cơ bản' ? 'selected' : '' ?>>Mức độ: Cơ bản</option>
            <option value="Thông hiểu" <?= $selectedLevel === 'Thông hiểu' ? 'selected' : '' ?>>Mức độ: Thông hiểu</option>
            <option value="Vận dụng cao" <?= $selectedLevel === 'Vận dụng cao' ? 'selected' : '' ?>>Mức độ: Vận dụng cao</option>
        </select>

        <button type="submit" class="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-bold transition">
            Lọc đề thi
        </button>

        <?php if ($searchQuery !== '' || $selectedLevel !== '' || $selectedSubjectCode !== ''): ?>
            <a href="index.php" class="px-4 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-600 text-sm font-semibold text-center transition">
                Xóa lọc
            </a>
        <?php endif; ?>
    </form>
</section>

<!-- Danh sách Đề thi phân chia rõ ràng theo từng môn -->
<section class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-8 space-y-10">
    <?php if (empty($exams)): ?>
        <div class="bg-white rounded-3xl border border-slate-200/80 p-12 text-center">
            <div class="w-16 h-16 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center mx-auto text-2xl mb-4">
                <i class="fa-solid fa-folder-open"></i>
            </div>
            <h3 class="text-lg font-extrabold text-slate-800">Không tìm thấy đề thi phù hợp</h3>
            <p class="text-sm text-slate-500 mt-1">Hãy thử đổi từ khóa tìm kiếm hoặc chọn môn học khác.</p>
            <a href="index.php" class="inline-flex items-center gap-2 mt-4 px-5 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-bold">
                Xem tất cả đề thi
            </a>
        </div>
    <?php else: ?>
        <?php foreach ($subjects as $sub):
            $code = $sub['code'];
            if (empty($examsBySubject[$code])) {
                continue;
            }
            $style = getSubjectBadgeStyle($code);
            $subjectExams = $examsBySubject[$code];
        ?>
            <div>
                <!-- Tiêu đề từng phân khu Môn Học -->
                <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-4 mb-5 border-b border-slate-200">
                    <div class="flex items-center gap-3.5">
                        <div class="w-11 h-11 rounded-2xl bg-gradient-to-br <?= htmlspecialchars($sub['gradient']) ?> text-white flex items-center justify-center text-lg shadow-sm">
                            <i class="fa-solid <?= htmlspecialchars($sub['icon']) ?>"></i>
                        </div>
                        <div>
                            <div class="flex items-center gap-2.5">
                                <h2 class="text-xl font-extrabold text-slate-900">Bộ Đề Môn <?= htmlspecialchars($sub['name']) ?></h2>
                                <span class="px-2.5 py-0.5 rounded-full text-xs font-bold <?= $style['bg'] ?> <?= $style['text'] ?> border <?= $style['border'] ?>">
                                    <?= count($subjectExams) ?> đề
                                </span>
                            </div>
                            <p class="text-xs text-slate-500 mt-0.5"><?= htmlspecialchars($sub['description']) ?></p>
                        </div>
                    </div>

                    <?php if ($selectedSubjectCode === ''): ?>
                        <a href="index.php?subject=<?= urlencode($code) ?>" class="text-xs font-bold <?= $style['text'] ?> hover:underline flex items-center gap-1">
                            Xem riêng môn <?= htmlspecialchars($sub['name']) ?> <i class="fa-solid fa-arrow-right"></i>
                        </a>
                    <?php endif; ?>
                </div>

                <!-- Grid các đề của môn này -->
                <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                    <?php foreach ($subjectExams as $exam):
                        $examId = (int)$exam['id'];
                        $myRecord = $userBestScores[$examId] ?? null;
                    ?>
                        <div class="card-hover bg-white rounded-3xl border border-slate-200/80 p-6 flex flex-col justify-between shadow-sm">
                            <div>
                                <!-- Hàng badge trên cùng -->
                                <div class="flex flex-wrap items-center justify-between gap-2 mb-3">
                                    <div class="flex items-center gap-2">
                                        <span class="px-3 py-1 rounded-xl text-xs font-extrabold <?= $style['badge'] ?>">
                                            <?= htmlspecialchars($exam['subject_name']) ?>
                                        </span>
                                        <span class="px-2.5 py-1 rounded-xl text-xs font-bold bg-slate-100 text-slate-700">
                                            <?= htmlspecialchars($exam['level']) ?>
                                        </span>
                                    </div>

                                    <?php if ($myRecord): ?>
                                        <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                            <i class="fa-solid fa-trophy text-amber-500"></i>
                                            Cao nhất: <?= number_format((float)$myRecord['best_score'], 1) ?>/10
                                        </span>
                                    <?php endif; ?>
                                </div>

                                <!-- Tên đề thi -->
                                <h3 class="text-lg font-extrabold text-slate-900 leading-snug">
                                    <?= htmlspecialchars($exam['title']) ?>
                                </h3>
                                <p class="text-xs text-slate-500 mt-2 line-clamp-2 leading-relaxed">
                                    <?= htmlspecialchars($exam['description']) ?>
                                </p>

                                <?php if ($exam['level'] === 'Chuẩn THPT QG'): ?>
                                    <div class="mt-3 flex flex-wrap items-center gap-1.5 text-[11px] font-bold">
                                        <span class="px-2 py-0.5 rounded-lg bg-indigo-50 text-indigo-700 border border-indigo-200">
                                            Chuẩn GDPT 2018
                                        </span>
                                        <?php if ((int)$exam['tf_count'] > 0 || (int)$exam['sa_count'] > 0): ?>
                                            <span class="px-2 py-0.5 rounded-lg bg-violet-50 text-violet-700 border border-violet-200">
                                                <?= (int)$exam['mcq_count'] ?> TN • <?= (int)$exam['tf_count'] ?> Đ/S • <?= (int)$exam['sa_count'] ?> TLN
                                            </span>
                                        <?php else: ?>
                                            <span class="px-2 py-0.5 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200">
                                                <?= number_format((float)($exam['min_point'] ?? 0.25), 2) ?>đ/câu • Thang 10.00
                                            </span>
                                        <?php endif; ?>
                                    </div>
                                <?php endif; ?>
                            </div>

                            <!-- Thông số & Nút Vào Luyện Đề -->
                            <div class="mt-5 pt-4 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3">
                                <div class="flex items-center gap-4 text-xs font-semibold text-slate-500">
                                    <span class="flex items-center gap-1.5 font-bold text-slate-700">
                                        <i class="fa-regular fa-clock text-indigo-500"></i>
                                        <?= (int)$exam['duration_minutes'] ?> phút
                                    </span>
                                    <span class="flex items-center gap-1.5 font-bold text-slate-700">
                                        <i class="fa-regular fa-circle-question text-indigo-500"></i>
                                        <?= (int)$exam['question_count'] ?> câu
                                    </span>
                                    <span class="flex items-center gap-1.5">
                                        <i class="fa-solid fa-star text-amber-500"></i>
                                        <?= ((int)$exam['tf_count'] > 0 || (int)$exam['sa_count'] > 0) ? 'Thang 10.00' : number_format((float)($exam['min_point'] ?? 0.25), 2) . 'đ/câu' ?>
                                    </span>
                                    <span class="flex items-center gap-1.5">
                                        <i class="fa-solid fa-users text-indigo-500"></i>
                                        <?= (int)$exam['attempt_count'] ?> lượt thi
                                    </span>
                                </div>

                                <a href="take_exam.php?id=<?= $examId ?>"
                                   class="px-4 py-2.5 rounded-xl text-white font-bold text-xs shadow-sm transition flex items-center gap-2 <?= $style['btn'] ?>">
                                    <i class="fa-solid fa-pen-to-square"></i>
                                    <?= $myRecord ? 'Luyện lại đề này' : 'Bắt đầu làm bài' ?>
                                </a>
                            </div>
                        </div>
                    <?php endforeach; ?>
                </div>
            </div>
        <?php endforeach; ?>
    <?php endif; ?>
</section>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
