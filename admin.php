<?php
require_once __DIR__ . '/config/db.php';
requireAdmin();

$tab = $_GET['tab'] ?? 'exams';
$manageExamId = (int)($_GET['exam_id'] ?? 0);

// XỬ LÝ CÁC THAO TÁC QUẢN TRỊ (POST)
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $action = $_POST['action'] ?? '';

    // 1. Thêm đề thi mới
    if ($action === 'add_exam') {
        $subjectId = (int)($_POST['subject_id'] ?? 1);
        $title = trim($_POST['title'] ?? '');
        $description = trim($_POST['description'] ?? '');
        $duration = max(1, (int)($_POST['duration_minutes'] ?? 15));
        $level = $_POST['level'] ?? 'Thông hiểu';

        if ($title !== '') {
            $stmt = $pdo->prepare("INSERT INTO exams (subject_id, title, description, duration_minutes, level, is_active) VALUES (?, ?, ?, ?, ?, 1)");
            $stmt->execute([$subjectId, $title, $description, $duration, $level]);
            $newExamId = (int)$pdo->lastInsertId();
            $_SESSION['flash_success'] = 'Đã tạo đề thi mới thành công! Hãy thêm câu hỏi cho đề này.';
            header('Location: admin.php?tab=questions&exam_id=' . $newExamId);
            exit;
        }
    }

    // 2. Xóa đề thi
    if ($action === 'delete_exam') {
        $delExamId = (int)($_POST['exam_id'] ?? 0);
        $stmt = $pdo->prepare("DELETE FROM exams WHERE id = ?");
        $stmt->execute([$delExamId]);
        $_SESSION['flash_success'] = 'Đã xóa đề thi khỏi hệ thống!';
        header('Location: admin.php?tab=exams');
        exit;
    }

    // 3. Thêm câu hỏi chuẩn Form 2025 vào đề (mcq / true_false / short_answer)
    if ($action === 'add_question') {
        $examId = (int)($_POST['exam_id'] ?? 0);
        $questionType = $_POST['question_type'] ?? 'mcq';
        if (!in_array($questionType, ['mcq', 'true_false', 'short_answer'], true)) {
            $questionType = 'mcq';
        }
        $questionText = trim($_POST['question_text'] ?? '');
        $pointsValue = max(0.10, (float)($_POST['points_value'] ?? 0.25));
        $difficulty = $_POST['difficulty'] ?? 'Nhận biết';
        if (!in_array($difficulty, ['Nhận biết', 'Thông hiểu', 'Vận dụng', 'Vận dụng cao'], true)) {
            $difficulty = 'Nhận biết';
        }
        $explanation = trim($_POST['explanation'] ?? '');

        $optA = null;
        $optB = null;
        $optC = null;
        $optD = null;
        $correct = '';

        if ($questionType === 'mcq') {
            $optA = trim($_POST['option_a'] ?? '');
            $optB = trim($_POST['option_b'] ?? '');
            $optC = trim($_POST['option_c'] ?? '');
            $optD = trim($_POST['option_d'] ?? '');
            $correct = $_POST['correct_option'] ?? 'A';
        } elseif ($questionType === 'true_false') {
            $optA = trim($_POST['tf_stmt_a'] ?? '');
            $optB = trim($_POST['tf_stmt_b'] ?? '');
            $optC = trim($_POST['tf_stmt_c'] ?? '');
            $optD = trim($_POST['tf_stmt_d'] ?? '');
            $tfAns = [
                ($_POST['tf_ans_a'] ?? 'D') === 'S' ? 'S' : 'D',
                ($_POST['tf_ans_b'] ?? 'D') === 'S' ? 'S' : 'D',
                ($_POST['tf_ans_c'] ?? 'D') === 'S' ? 'S' : 'D',
                ($_POST['tf_ans_d'] ?? 'D') === 'S' ? 'S' : 'D',
            ];
            $correct = implode(',', $tfAns);
            $pointsValue = 1.00;
        } else {
            $correct = trim($_POST['short_correct_answer'] ?? '');
        }

        if ($examId > 0 && $questionText !== '' && $correct !== '') {
            $stmt = $pdo->prepare("
                INSERT INTO questions (exam_id, question_type, question_text, option_a, option_b, option_c, option_d, correct_option, explanation, points_value, difficulty)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ");
            $stmt->execute([$examId, $questionType, $questionText, $optA, $optB, $optC, $optD, $correct, $explanation, $pointsValue, $difficulty]);
            $_SESSION['flash_success'] = 'Đã thêm câu hỏi chuẩn 2025 mới vào đề thi!';
            header('Location: admin.php?tab=questions&exam_id=' . $examId);
            exit;
        }
    }

    // 4. Xóa câu hỏi
    if ($action === 'delete_question') {
        $qId = (int)($_POST['question_id'] ?? 0);
        $examId = (int)($_POST['exam_id'] ?? 0);
        $stmt = $pdo->prepare("DELETE FROM questions WHERE id = ?");
        $stmt->execute([$qId]);
        $_SESSION['flash_success'] = 'Đã xóa câu hỏi!';
        header('Location: admin.php?tab=questions&exam_id=' . $examId);
        exit;
    }

}

// THỐNG KÊ TỔNG QUAN CHO ADMIN
$totalExams = (int)$pdo->query("SELECT COUNT(*) FROM exams")->fetchColumn();
$totalQuestions = (int)$pdo->query("SELECT COUNT(*) FROM questions")->fetchColumn();
$totalStudents = (int)$pdo->query("SELECT COUNT(*) FROM users WHERE role = 'student'")->fetchColumn();
$totalAttempts = (int)$pdo->query("SELECT COUNT(*) FROM exam_attempts")->fetchColumn();

$subjects = $pdo->query("SELECT * FROM subjects ORDER BY id ASC")->fetchAll();

$allExams = $pdo->query("
    SELECT e.*, s.code AS subject_code, s.name AS subject_name,
           (SELECT COUNT(*) FROM questions q WHERE q.exam_id = e.id) AS q_count,
           (SELECT COUNT(*) FROM exam_attempts ea WHERE ea.exam_id = e.id) AS attempt_count
    FROM exams e
    JOIN subjects s ON e.subject_id = s.id
    ORDER BY s.id ASC, e.id DESC
")->fetchAll();

if ($manageExamId === 0 && !empty($allExams)) {
    $manageExamId = (int)$allExams[0]['id'];
}

$pageTitle = 'Bảng Điều Khiển Quản Trị (Admin)';
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Header Admin -->
    <div class="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 rounded-3xl p-6 sm:p-8 text-white mb-8 shadow-lg">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div>
                <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/20 border border-amber-400/30 text-amber-300 text-xs font-extrabold uppercase">
                    <i class="fa-solid fa-user-shield"></i> Khu Vực Phân Quyền Quản Trị Viên (Admin)
                </span>
                <h1 class="text-2xl sm:text-3xl font-extrabold mt-2">Quản Lý Kho Đề Toán • Anh • Lý • Hóa</h1>
                <p class="text-slate-300 text-xs sm:text-sm mt-1">
                    Thêm đề thi mới, biên soạn câu hỏi trắc nghiệm, phân quyền Học sinh / Admin và theo dõi bảng điểm toàn trường.
                </p>
            </div>

        </div>
    </div>

    <!-- Thanh Tab chức năng của Admin -->
    <?php
    $liveExamCount = (int)$pdo->query("
        SELECT COUNT(*) FROM exam_sessions
        WHERE status = 'in_progress' AND last_heartbeat >= DATE_SUB(NOW(), INTERVAL 3 MINUTE)
    ")->fetchColumn();
    ?>
    <div class="flex flex-wrap items-center gap-2 mb-6 border-b border-slate-200 pb-3">
        <a href="admin.php?tab=exams"
           class="px-4 py-2.5 rounded-xl text-sm font-extrabold transition flex items-center gap-2 <?= $tab === 'exams' ? 'bg-indigo-600 text-white shadow-sm' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50' ?>">
            <i class="fa-solid fa-folder-plus"></i> 1. Quản lý Đề thi
        </a>
        <a href="admin.php?tab=questions&exam_id=<?= $manageExamId ?>"
           class="px-4 py-2.5 rounded-xl text-sm font-extrabold transition flex items-center gap-2 <?= $tab === 'questions' ? 'bg-indigo-600 text-white shadow-sm' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50' ?>">
            <i class="fa-solid fa-list-check"></i> 2. Câu hỏi &amp; Đáp án
        </a>
        <a href="admin.php?tab=results"
           class="px-4 py-2.5 rounded-xl text-sm font-extrabold transition flex items-center gap-2 <?= $tab === 'results' ? 'bg-indigo-600 text-white shadow-sm' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50' ?>">
            <i class="fa-solid fa-square-poll-vertical"></i> 3. Bảng điểm
        </a>
        <a href="admin.php?tab=monitor"
           class="px-4 py-2.5 rounded-xl text-sm font-extrabold transition flex items-center gap-2 <?= $tab === 'monitor' ? 'bg-rose-600 text-white shadow-sm' : 'bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-100' ?>">
            <i class="fa-solid fa-desktop"></i> 4. Giám sát Học sinh
            <?php if ($liveExamCount > 0): ?>
                <span class="px-2 py-0.5 rounded-full text-[11px] bg-white text-rose-600 font-black animate-pulse"><?= $liveExamCount ?></span>
            <?php endif; ?>
        </a>
    </div>

    <?php if ($tab === 'exams'): ?>
        <!-- TAB 1: QUẢN LÝ ĐỀ THI -->
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            <!-- Form tạo đề thi mới -->
            <div class="lg:col-span-4 bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm">
                <h2 class="text-lg font-extrabold text-slate-900 mb-4 flex items-center gap-2">
                    <i class="fa-solid fa-circle-plus text-indigo-600"></i> Tạo Đề Thi Mới
                </h2>
                <form method="POST" action="admin.php?tab=exams" class="space-y-4">
                    <input type="hidden" name="action" value="add_exam">
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1.5">Chọn môn học *</label>
                        <select name="subject_id" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-slate-800 outline-none focus:border-indigo-500">
                            <?php foreach ($subjects as $s): ?>
                                <option value="<?= (int)$s['id'] ?>">Môn <?= htmlspecialchars($s['name']) ?> (<?= htmlspecialchars($s['code']) ?>)</option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1.5">Tên đề thi *</label>
                        <input type="text" name="title" required
                               placeholder="VD: Đề số 03: Chuyên đề Logarit & Mũ"
                               class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500">
                    </div>
                    <div class="grid grid-cols-2 gap-3">
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1.5">Thời gian (Phút)</label>
                            <input type="number" name="duration_minutes" value="60" min="1" max="180" required
                                   class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-bold outline-none focus:border-indigo-500">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1.5">Mức độ</label>
                            <select name="level" class="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm font-semibold outline-none focus:border-indigo-500">
                                <option value="Chuẩn THPT QG" selected>Chuẩn THPT QG</option>
                                <option value="Cơ bản">Cơ bản</option>
                                <option value="Thông hiểu">Thông hiểu</option>
                                <option value="Vận dụng cao">Vận dụng cao</option>
                            </select>
                        </div>
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1.5">Mô tả nội dung đề</label>
                        <textarea name="description" rows="3"
                                  placeholder="Mô tả ngắn các kiến thức trọng tâm trong đề..."
                                  class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500"></textarea>
                    </div>
                    <button type="submit" class="w-full py-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-sm transition">
                        <i class="fa-solid fa-plus mr-1"></i> Lưu & Thêm câu hỏi
                    </button>
                </form>
            </div>

            <!-- Danh sách tất cả đề thi -->
            <div class="lg:col-span-8 bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
                    <h2 class="font-extrabold text-slate-800">Danh sách Đề thi hiện có (<?= count($allExams) ?> đề)</h2>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <thead>
                            <tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70">
                                <th class="py-3.5 px-5">Môn</th>
                                <th class="py-3.5 px-4">Tên đề thi</th>
                                <th class="py-3.5 px-3 text-center">Số câu</th>
                                <th class="py-3.5 px-3 text-center">Thời gian</th>
                                <th class="py-3.5 px-5 text-right">Quản lý</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100 text-sm">
                            <?php foreach ($allExams as $ex):
                                $st = getSubjectBadgeStyle($ex['subject_code']);
                            ?>
                                <tr class="hover:bg-slate-50/80 transition">
                                    <td class="py-3.5 px-5">
                                        <span class="px-2.5 py-1 rounded-lg text-xs font-extrabold <?= $st['badge'] ?>">
                                            <?= htmlspecialchars($ex['subject_name']) ?>
                                        </span>
                                    </td>
                                    <td class="py-3.5 px-4">
                                        <div class="font-bold text-slate-800"><?= htmlspecialchars($ex['title']) ?></div>
                                        <div class="text-xs text-slate-400">Mức độ: <?= htmlspecialchars($ex['level']) ?> • <?= (int)$ex['attempt_count'] ?> lượt thi</div>
                                    </td>
                                    <td class="py-3.5 px-3 text-center font-bold text-indigo-600">
                                        <?= (int)$ex['q_count'] ?> câu
                                    </td>
                                    <td class="py-3.5 px-3 text-center text-xs font-semibold text-slate-600">
                                        <?= (int)$ex['duration_minutes'] ?> phút
                                    </td>
                                    <td class="py-3.5 px-5 text-right">
                                        <div class="inline-flex items-center gap-2">
                                            <a href="admin.php?tab=questions&exam_id=<?= (int)$ex['id'] ?>"
                                               class="px-3 py-1.5 rounded-xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold text-xs transition">
                                                <i class="fa-solid fa-pen-ruler mr-1"></i> Câu hỏi
                                            </a>
                                            <form method="POST" action="admin.php?tab=exams" onsubmit="return confirm('Xóa đề thi này sẽ xóa toàn bộ câu hỏi bên trong. Tiếp tục?')">
                                                <input type="hidden" name="action" value="delete_exam">
                                                <input type="hidden" name="exam_id" value="<?= (int)$ex['id'] ?>">
                                                <button type="submit" class="p-1.5 rounded-xl text-slate-400 hover:text-rose-600 hover:bg-rose-50 transition" title="Xóa đề">
                                                    <i class="fa-solid fa-trash-can"></i>
                                                </button>
                                            </form>
                                        </div>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

    <?php elseif ($tab === 'questions'): ?>
        <!-- TAB 2: QUẢN LÝ CÂU HỎI TRONG ĐỀ -->
        <?php
        $examQuestionsStmt = $pdo->prepare("SELECT * FROM questions WHERE exam_id = ? ORDER BY sort_order ASC, id ASC");
        $examQuestionsStmt->execute([$manageExamId]);
        $examQuestions = $examQuestionsStmt->fetchAll();
        ?>
        <div class="bg-white rounded-2xl border border-slate-200/80 p-4 mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div class="flex items-center gap-2 text-sm font-bold text-slate-700">
                <i class="fa-solid fa-filter text-indigo-600"></i> Chọn đề thi cần biên soạn câu hỏi:
            </div>
            <form method="GET" action="admin.php" class="flex-1 max-w-xl">
                <input type="hidden" name="tab" value="questions">
                <select name="exam_id" onchange="this.form.submit()" class="w-full px-4 py-2.5 rounded-xl bg-slate-50 border border-slate-200 text-sm font-bold text-slate-800 outline-none focus:border-indigo-500">
                    <?php foreach ($allExams as $ex): ?>
                        <option value="<?= (int)$ex['id'] ?>" <?= (int)$ex['id'] === $manageExamId ? 'selected' : '' ?>>
                            [<?= htmlspecialchars($ex['subject_name']) ?>] <?= htmlspecialchars($ex['title']) ?> (<?= (int)$ex['q_count'] ?> câu)
                        </option>
                    <?php endforeach; ?>
                </select>
            </form>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            <!-- Form thêm câu hỏi mới -->
            <div class="lg:col-span-5 bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm">
                <h2 class="text-lg font-extrabold text-slate-900 mb-4 flex items-center gap-2">
                    <i class="fa-solid fa-circle-question text-indigo-600"></i> Thêm Câu Hỏi Trắc Nghiệm
                </h2>
                <form method="POST" action="admin.php?tab=questions&exam_id=<?= $manageExamId ?>" class="space-y-3.5" id="adminAddQForm">
                    <input type="hidden" name="action" value="add_question">
                    <input type="hidden" name="exam_id" value="<?= $manageExamId ?>">

                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Dạng câu hỏi 2025 *</label>
                            <select name="question_type" id="adminQType" onchange="toggleAdminQuestionFields()" class="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-indigo-700 bg-indigo-50 outline-none">
                                <option value="mcq">Phần I: TN 4 phương án</option>
                                <option value="true_false">Phần II: Đúng / Sai (4 ý)</option>
                                <option value="short_answer">Phần III: Trả lời ngắn</option>
                            </select>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Điểm câu hỏi *</label>
                            <select name="points_value" id="adminQPoints" class="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-slate-800 bg-slate-50 outline-none">
                                <option value="0.20">0.20 điểm (Toán 50 câu)</option>
                                <option value="0.25" selected>0.25 điểm (40 câu)</option>
                                <option value="0.50">0.50 điểm</option>
                                <option value="1.00">1.00 điểm (Đúng/Sai)</option>
                            </select>
                        </div>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Nội dung câu hỏi / Đề dẫn *</label>
                        <textarea name="question_text" rows="3" required
                                  placeholder="Nhập đề bài hoặc đoạn dẫn câu hỏi..."
                                  class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500"></textarea>
                    </div>

                    <!-- KHỐI NHẬP CHO DẠNG 1: MCQ (A/B/C/D) -->
                    <div id="adminMcqFields" class="space-y-3">
                        <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                            <div>
                                <label class="block text-xs font-bold text-slate-600 mb-1">Đáp án A *</label>
                                <input type="text" name="option_a" placeholder="Phương án A"
                                       class="mcq-req w-full px-3.5 py-2 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500" required>
                            </div>
                            <div>
                                <label class="block text-xs font-bold text-slate-600 mb-1">Đáp án B *</label>
                                <input type="text" name="option_b" placeholder="Phương án B"
                                       class="mcq-req w-full px-3.5 py-2 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500" required>
                            </div>
                            <div>
                                <label class="block text-xs font-bold text-slate-600 mb-1">Đáp án C *</label>
                                <input type="text" name="option_c" placeholder="Phương án C"
                                       class="mcq-req w-full px-3.5 py-2 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500" required>
                            </div>
                            <div>
                                <label class="block text-xs font-bold text-slate-600 mb-1">Đáp án D *</label>
                                <input type="text" name="option_d" placeholder="Phương án D"
                                       class="mcq-req w-full px-3.5 py-2 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500" required>
                            </div>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Đáp án đúng *</label>
                            <select name="correct_option" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-extrabold text-emerald-700 bg-emerald-50 outline-none">
                                <option value="A">Đáp án đúng là A</option>
                                <option value="B">Đáp án đúng là B</option>
                                <option value="C">Đáp án đúng là C</option>
                                <option value="D">Đáp án đúng là D</option>
                            </select>
                        </div>
                    </div>

                    <!-- KHỐI NHẬP CHO DẠNG 2: ĐÚNG / SAI (4 Ý) -->
                    <div id="adminTfFields" class="space-y-2.5 hidden">
                        <div class="text-xs font-bold text-violet-700 bg-violet-50 px-3 py-2 rounded-xl border border-violet-200">
                            Nhập 4 mệnh đề a, b, c, d và chọn đáp án Đúng (D) hoặc Sai (S) cho từng ý:
                        </div>
                        <?php foreach (['a', 'b', 'c', 'd'] as $subK): ?>
                            <div class="flex items-center gap-2">
                                <input type="text" name="tf_stmt_<?= $subK ?>" placeholder="Ý <?= $subK ?>) ..."
                                       class="tf-req flex-1 px-3 py-2 rounded-xl border border-slate-200 text-xs outline-none focus:border-violet-500">
                                <select name="tf_ans_<?= $subK ?>" class="px-2.5 py-2 rounded-xl border border-slate-200 text-xs font-extrabold bg-slate-50">
                                    <option value="D">Đúng</option>
                                    <option value="S">Sai</option>
                                </select>
                            </div>
                        <?php endforeach; ?>
                    </div>

                    <!-- KHỐI NHẬP CHO DẠNG 3: TRẢ LỜI NGẮN -->
                    <div id="adminSaFields" class="hidden">
                        <label class="block text-xs font-bold uppercase text-teal-700 mb-1">Đáp số chuẩn *</label>
                        <input type="text" name="short_correct_answer" placeholder="Nhập đáp số chính xác..."
                               class="sa-req w-full px-4 py-2.5 rounded-xl border border-teal-300 bg-teal-50/50 text-sm font-extrabold font-mono outline-none focus:border-teal-600">
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Mức độ phân hóa *</label>
                        <select name="difficulty" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-slate-800 bg-slate-50 outline-none">
                            <option value="Nhận biết">Nhận biết (Cơ bản)</option>
                            <option value="Thông hiểu">Thông hiểu</option>
                            <option value="Vận dụng">Vận dụng</option>
                            <option value="Vận dụng cao">Vận dụng cao (Nâng cao)</option>
                        </select>
                    </div>

                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Lời giải / Hướng dẫn chi tiết</label>
                        <textarea name="explanation" rows="2"
                                  placeholder="Giải thích chi tiết để học sinh ôn tập..."
                                  class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500"></textarea>
                    </div>

                    <button type="submit" class="w-full py-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-sm transition">
                        <i class="fa-solid fa-plus mr-1"></i> Thêm câu hỏi vào đề
                    </button>
                </form>

                <script>
                function toggleAdminQuestionFields() {
                    const type = document.getElementById('adminQType').value;
                    const mcqBox = document.getElementById('adminMcqFields');
                    const tfBox = document.getElementById('adminTfFields');
                    const saBox = document.getElementById('adminSaFields');
                    const ptsSel = document.getElementById('adminQPoints');

                    mcqBox.classList.toggle('hidden', type !== 'mcq');
                    tfBox.classList.toggle('hidden', type !== 'true_false');
                    saBox.classList.toggle('hidden', type !== 'short_answer');

                    document.querySelectorAll('.mcq-req').forEach(el => el.required = (type === 'mcq'));
                    document.querySelectorAll('.tf-req').forEach(el => el.required = (type === 'true_false'));
                    document.querySelectorAll('.sa-req').forEach(el => el.required = (type === 'short_answer'));

                    if (type === 'true_false') ptsSel.value = '1.00';
                    else if (type === 'mcq') ptsSel.value = '0.25';
                    else ptsSel.value = '0.50';
                }
                </script>
            </div>

            <!-- Danh sách câu hỏi của đề đang chọn -->
            <div class="lg:col-span-7 space-y-4">
                <?php if (empty($examQuestions)): ?>
                    <div class="bg-white rounded-3xl border border-slate-200 p-10 text-center text-slate-500 text-sm">
                        Đề thi này chưa có câu hỏi nào. Hãy điền form bên trái để thêm câu hỏi đầu tiên!
                    </div>
                <?php else: ?>
                    <?php foreach ($examQuestions as $idx => $q):
                        $qType = $q['question_type'] ?? 'mcq';
                        $typeInfo = getQuestionTypeInfo($qType);
                        $diff = $q['difficulty'] ?? 'Nhận biết';
                        $diffStyle = getDifficultyBadgeStyle($diff);
                    ?>
                        <div class="bg-white rounded-3xl border border-slate-200/80 p-5 shadow-sm">
                            <div class="flex items-start justify-between gap-3 mb-2">
                                <div class="flex flex-wrap items-center gap-2">
                                    <span class="px-3 py-1 rounded-xl bg-indigo-50 text-indigo-700 font-extrabold text-xs">
                                        Câu <?= $idx + 1 ?> • <?= htmlspecialchars($typeInfo['short']) ?> (<?= number_format((float)$q['points_value'], 2) ?>đ)
                                    </span>
                                    <span class="px-2.5 py-1 rounded-xl border text-[11px] font-extrabold <?= $diffStyle['pill'] ?>">
                                        <?= htmlspecialchars($diff) ?>
                                    </span>
                                    <span class="px-2.5 py-1 rounded-xl bg-emerald-50 text-emerald-700 border border-emerald-200 text-[11px] font-extrabold">
                                        Đáp án: <?= htmlspecialchars($q['correct_option']) ?>
                                    </span>
                                </div>
                                <form method="POST" action="admin.php?tab=questions&exam_id=<?= $manageExamId ?>" onsubmit="return confirm('Xóa câu hỏi này?')">
                                    <input type="hidden" name="action" value="delete_question">
                                    <input type="hidden" name="question_id" value="<?= (int)$q['id'] ?>">
                                    <input type="hidden" name="exam_id" value="<?= $manageExamId ?>">
                                    <button type="submit" class="text-xs font-bold text-rose-500 hover:text-rose-700">
                                        <i class="fa-solid fa-trash-can mr-1"></i> Xóa
                                    </button>
                                </form>
                            </div>
                            <div class="font-bold text-slate-800 text-sm mb-3"><?= nl2br(htmlspecialchars($q['question_text'])) ?></div>
                            <?php if ($qType === 'mcq'): ?>
                                <div class="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
                                    <?php foreach (['A' => $q['option_a'], 'B' => $q['option_b'], 'C' => $q['option_c'], 'D' => $q['option_d']] as $k => $v): ?>
                                        <div class="p-2.5 rounded-xl border <?= $q['correct_option'] === $k ? 'bg-emerald-50 border-emerald-300 text-emerald-900 font-bold' : 'bg-slate-50 border-slate-200 text-slate-600' ?>">
                                            <b><?= $k ?>.</b> <?= htmlspecialchars((string)$v) ?>
                                        </div>
                                    <?php endforeach; ?>
                                </div>
                            <?php elseif ($qType === 'true_false'): ?>
                                <?php $tfAns = array_map('trim', explode(',', $q['correct_option'])); ?>
                                <div class="space-y-1.5 text-xs">
                                    <?php foreach ([$q['option_a'], $q['option_b'], $q['option_c'], $q['option_d']] as $k => $v): ?>
                                        <div class="p-2 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-between gap-2">
                                            <span><?= htmlspecialchars((string)$v) ?></span>
                                            <span class="px-2 py-0.5 rounded font-extrabold <?= ($tfAns[$k] ?? 'D') === 'D' ? 'bg-emerald-100 text-emerald-800' : 'bg-rose-100 text-rose-800' ?>">
                                                <?= ($tfAns[$k] ?? 'D') === 'D' ? 'Đúng' : 'Sai' ?>
                                            </span>
                                        </div>
                                    <?php endforeach; ?>
                                </div>
                            <?php else: ?>
                                <div class="p-2.5 rounded-xl bg-teal-50 border border-teal-200 text-xs font-extrabold text-teal-900 font-mono">
                                    Đáp số chuẩn: <?= htmlspecialchars($q['correct_option']) ?>
                                </div>
                            <?php endif; ?>
                        </div>
                    <?php endforeach; ?>
                <?php endif; ?>
            </div>
        </div>

    <?php elseif ($tab === 'results'): ?>
        <!-- TAB 4: BẢNG ĐIỂM HỌC SINH TOÀN HỆ THỐNG -->
        <?php
        $allAttempts = $pdo->query("
            SELECT ea.*, u.fullname, u.username, u.class_name,
                   e.title AS exam_title, s.code AS subject_code, s.name AS subject_name
            FROM exam_attempts ea
            JOIN users u ON ea.user_id = u.id
            JOIN exams e ON ea.exam_id = e.id
            JOIN subjects s ON e.subject_id = s.id
            ORDER BY ea.completed_at DESC
        ")->fetchAll();
        ?>
        <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
            <div class="px-6 py-4 border-b border-slate-100">
                <h2 class="font-extrabold text-slate-800">Bảng Điểm Luyện Đề &amp; Giám Sát Toàn Trường</h2>
            </div>
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70">
                            <th class="py-3.5 px-6">Học sinh</th>
                            <th class="py-3.5 px-4">Môn &amp; Đề thi</th>
                            <th class="py-3.5 px-4 text-center">Kết quả</th>
                            <th class="py-3.5 px-4 text-center">Thời gian làm</th>
                            <th class="py-3.5 px-4 text-center">Thoát màn hình</th>
                            <th class="py-3.5 px-4 text-center">Điểm số</th>
                            <th class="py-3.5 px-4">Thời gian nộp</th>
                            <th class="py-3.5 px-6 text-right">Chi tiết</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 text-sm">
                        <?php foreach ($allAttempts as $row):
                            $st = getSubjectBadgeStyle($row['subject_code']);
                            $exits = (int)($row['tab_switch_count'] ?? 0);
                        ?>
                            <tr class="hover:bg-slate-50/80 transition">
                                <td class="py-4 px-6">
                                    <div class="font-bold text-slate-800"><?= htmlspecialchars($row['fullname']) ?></div>
                                    <div class="text-xs text-slate-400">@<?= htmlspecialchars($row['username']) ?></div>
                                </td>
                                <td class="py-4 px-4">
                                    <span class="px-2 py-0.5 rounded-md text-[11px] font-extrabold <?= $st['badge'] ?> mr-1.5">
                                        <?= htmlspecialchars($row['subject_name']) ?>
                                    </span>
                                    <span class="font-bold text-slate-700"><?= htmlspecialchars($row['exam_title']) ?></span>
                                </td>
                                <td class="py-4 px-4 text-center font-bold text-slate-600">
                                    <?= (int)$row['correct_count'] ?> / <?= (int)$row['total_questions'] ?> câu
                                </td>
                                <td class="py-4 px-4 text-center text-xs font-bold text-slate-600">
                                    <?= formatDuration((int)$row['time_spent_seconds']) ?>
                                </td>
                                <td class="py-4 px-4 text-center">
                                    <?php if ($exits === 0): ?>
                                        <span class="px-2.5 py-1 rounded-xl text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                            0 lần (Hợp lệ)
                                        </span>
                                    <?php else: ?>
                                        <span class="px-2.5 py-1 rounded-xl text-xs font-extrabold bg-rose-50 text-rose-700 border border-rose-200">
                                            <i class="fa-solid fa-triangle-exclamation mr-1"></i>Thoát <?= $exits ?> lần
                                        </span>
                                    <?php endif; ?>
                                </td>
                                <td class="py-4 px-4 text-center">
                                    <span class="px-3 py-1 rounded-xl font-extrabold text-xs bg-indigo-100 text-indigo-800">
                                        <?= number_format((float)$row['score'], 2) ?> đ
                                    </span>
                                </td>
                                <td class="py-4 px-4 text-xs text-slate-500">
                                    <?= date('H:i - d/m/Y', strtotime($row['completed_at'])) ?>
                                </td>
                                <td class="py-4 px-6 text-right">
                                    <a href="result.php?attempt_id=<?= (int)$row['id'] ?>" class="px-3 py-1.5 rounded-xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold text-xs transition">
                                        Xem bài làm
                                    </a>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        </div>

    <?php elseif ($tab === 'monitor'): ?>
        <!-- TAB 5: GIÁM SÁT HỌC SINH ĐANG HOẠT ĐỘNG & KIỂM TRA VI PHẠM -->
        <?php
        $activeSessions = $pdo->query("
            SELECT es.*, u.fullname, u.username, u.role,
                   e.title AS exam_title, e.duration_minutes,
                   s.code AS subject_code, s.name AS subject_name,
                   TIMESTAMPDIFF(SECOND, es.last_heartbeat, NOW()) AS idle_seconds
            FROM exam_sessions es
            JOIN users u ON es.user_id = u.id
            JOIN exams e ON es.exam_id = e.id
            JOIN subjects s ON e.subject_id = s.id
            WHERE es.status = 'in_progress' AND es.last_heartbeat >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
            ORDER BY es.tab_switch_count DESC, es.last_heartbeat DESC
        ")->fetchAll();

        $onlineUsers = $pdo->query("
            SELECT u.*,
                   TIMESTAMPDIFF(SECOND, u.last_active_at, NOW()) AS idle_seconds,
                   (SELECT e.title FROM exam_sessions es2 JOIN exams e ON es2.exam_id = e.id
                    WHERE es2.user_id = u.id AND es2.status = 'in_progress' AND es2.last_heartbeat >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
                    ORDER BY es2.id DESC LIMIT 1) AS current_exam_title
            FROM users u
            WHERE u.last_active_at >= DATE_SUB(NOW(), INTERVAL 5 MINUTE)
            ORDER BY u.last_active_at DESC
        ")->fetchAll();

        $recentSubmissions = $pdo->query("
            SELECT ea.*, u.fullname, u.username,
                   e.title AS exam_title, s.code AS subject_code, s.name AS subject_name
            FROM exam_attempts ea
            JOIN users u ON ea.user_id = u.id
            JOIN exams e ON ea.exam_id = e.id
            JOIN subjects s ON e.subject_id = s.id
            ORDER BY ea.completed_at DESC
            LIMIT 20
        ")->fetchAll();
        ?>

        <div class="space-y-6">
            <!-- Thanh điều khiển làm mới tự động -->
            <div class="bg-white rounded-2xl border border-slate-200/80 p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3 shadow-sm">
                <div class="flex items-center gap-3">
                    <span class="w-3 h-3 rounded-full bg-emerald-500 animate-ping"></span>
                    <div class="text-sm font-bold text-slate-700">
                        Trạng thái giám sát trực tiếp • Tự động cập nhật mỗi <span class="text-indigo-600">10 giây</span>
                    </div>
                </div>
                <div class="flex items-center gap-2">
                    <button type="button" id="toggleAutoRefreshBtn" onclick="toggleMonitorAutoRefresh()" class="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition">
                        <i class="fa-solid fa-pause mr-1"></i> Tạm dừng tự động
                    </button>
                    <a href="admin.php?tab=monitor" class="px-4 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold shadow-sm transition">
                        <i class="fa-solid fa-rotate mr-1"></i> Làm mới ngay
                    </a>
                </div>
            </div>

            <!-- 1. Học sinh ĐANG LÀM BÀI THI trực tiếp -->
            <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between bg-rose-50/40">
                    <h2 class="font-extrabold text-slate-900 flex items-center gap-2">
                        <i class="fa-solid fa-user-clock text-rose-600"></i>
                        Học sinh đang làm bài thi ngay lúc này (<?= count($activeSessions) ?>)
                    </h2>
                    <span class="text-xs text-slate-500 font-medium">Ghi nhận tự động khi học sinh chuyển tab / thoát màn hình</span>
                </div>

                <?php if (empty($activeSessions)): ?>
                    <div class="p-8 text-center text-sm text-slate-500">
                        Hiện chưa có học sinh nào đang mở phòng thi trực tiếp.
                    </div>
                <?php else: ?>
                    <div class="overflow-x-auto">
                        <table class="w-full text-left border-collapse">
                            <thead>
                                <tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70">
                                    <th class="py-3.5 px-6">Học sinh</th>
                                    <th class="py-3.5 px-4">Đề đang làm</th>
                                    <th class="py-3.5 px-4 text-center">Đã làm (Thời gian)</th>
                                    <th class="py-3.5 px-4 text-center">Tiến độ câu</th>
                                    <th class="py-3.5 px-4 text-center">Thoát màn hình</th>
                                    <th class="py-3.5 px-6 text-right">Tín hiệu</th>
                                </tr>
                            </thead>
                            <tbody class="divide-y divide-slate-100 text-sm">
                                <?php foreach ($activeSessions as $ses):
                                    $st = getSubjectBadgeStyle($ses['subject_code']);
                                    $exits = (int)$ses['tab_switch_count'];
                                    $idle = max(0, (int)$ses['idle_seconds']);
                                ?>
                                    <tr class="hover:bg-slate-50/80 transition">
                                        <td class="py-4 px-6">
                                            <div class="font-bold text-slate-800"><?= htmlspecialchars($ses['fullname']) ?></div>
                                            <div class="text-xs text-slate-400">@<?= htmlspecialchars($ses['username']) ?></div>
                                        </td>
                                        <td class="py-4 px-4">
                                            <span class="px-2 py-0.5 rounded-md text-[11px] font-extrabold <?= $st['badge'] ?> mr-1.5">
                                                <?= htmlspecialchars($ses['subject_name']) ?>
                                            </span>
                                            <span class="font-bold text-slate-700"><?= htmlspecialchars($ses['exam_title']) ?></span>
                                        </td>
                                        <td class="py-4 px-4 text-center font-bold text-indigo-700">
                                            <?= formatDuration((int)$ses['elapsed_seconds']) ?>
                                            <div class="text-[11px] text-slate-400 font-normal">/ <?= (int)$ses['duration_minutes'] ?> phút</div>
                                        </td>
                                        <td class="py-4 px-4 text-center font-bold text-slate-700">
                                            <?= (int)$ses['answered_count'] ?> / <?= (int)$ses['total_questions'] ?> câu
                                        </td>
                                        <td class="py-4 px-4 text-center">
                                            <?php if ($exits === 0): ?>
                                                <span class="px-3 py-1 rounded-xl text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                                    0 lần (Tập trung)
                                                </span>
                                            <?php else: ?>
                                                <span class="px-3 py-1 rounded-xl text-xs font-extrabold bg-rose-100 text-rose-800 border border-rose-300 animate-pulse">
                                                    <i class="fa-solid fa-triangle-exclamation mr-1"></i>Thoát <?= $exits ?> lần
                                                </span>
                                            <?php endif; ?>
                                        </td>
                                        <td class="py-4 px-6 text-right text-xs font-semibold text-emerald-600">
                                            <?= $idle <= 15 ? 'Đang trực tuyến' : $idle . 's trước' ?>
                                        </td>
                                    </tr>
                                <?php endforeach; ?>
                            </tbody>
                        </table>
                    </div>
                <?php endif; ?>
            </div>

            <!-- 2. Tất cả tài khoản đang hoạt động (Online) -->
            <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-100">
                    <h2 class="font-extrabold text-slate-800 flex items-center gap-2">
                        <i class="fa-solid fa-signal text-emerald-600"></i>
                        Tài khoản đang hoạt động trong 5 phút gần đây (<?= count($onlineUsers) ?>)
                    </h2>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <thead>
                            <tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70">
                                <th class="py-3 px-6">Tài khoản</th>
                                <th class="py-3 px-4">Vai trò</th>
                                <th class="py-3 px-4">Hoạt động hiện tại</th>
                                <th class="py-3 px-6 text-right">Lần tương tác cuối</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100 text-sm">
                            <?php foreach ($onlineUsers as $ou):
                                $idle = max(0, (int)$ou['idle_seconds']);
                            ?>
                                <tr class="hover:bg-slate-50/80 transition">
                                    <td class="py-3.5 px-6">
                                        <div class="font-bold text-slate-800"><?= htmlspecialchars($ou['fullname']) ?></div>
                                        <div class="text-xs text-slate-400">@<?= htmlspecialchars($ou['username']) ?></div>
                                    </td>
                                    <td class="py-3.5 px-4">
                                        <?php if ($ou['role'] === 'admin'): ?>
                                            <span class="px-2.5 py-1 rounded-lg text-xs font-extrabold bg-amber-100 text-amber-800">ADMIN</span>
                                        <?php else: ?>
                                            <span class="px-2.5 py-1 rounded-lg text-xs font-bold bg-indigo-50 text-indigo-700">HỌC SINH</span>
                                        <?php endif; ?>
                                    </td>
                                    <td class="py-3.5 px-4 text-xs font-bold">
                                        <?php if (!empty($ou['current_exam_title'])): ?>
                                            <span class="text-rose-600"><i class="fa-solid fa-pen-to-square mr-1"></i>Đang thi: <?= htmlspecialchars($ou['current_exam_title']) ?></span>
                                        <?php else: ?>
                                            <span class="text-emerald-600"><i class="fa-solid fa-circle text-[8px] mr-1.5"></i>Đang xem kho đề / kết quả</span>
                                        <?php endif; ?>
                                    </td>
                                    <td class="py-3.5 px-6 text-right text-xs text-slate-500">
                                        <?= $idle < 60 ? $idle . ' giây trước' : floor($idle / 60) . ' phút trước' ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- 3. Nhật ký các bài đã làm xong & Số lần thoát màn hình -->
            <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-100">
                    <h2 class="font-extrabold text-slate-800 flex items-center gap-2">
                        <i class="fa-solid fa-shield-halved text-indigo-600"></i>
                        Lịch sử đã làm đề &amp; Số lần thoát màn hình (20 lượt gần nhất)
                    </h2>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <thead>
                            <tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70">
                                <th class="py-3 px-6">Học sinh</th>
                                <th class="py-3 px-4">Đề đã làm</th>
                                <th class="py-3 px-4 text-center">Thời gian làm</th>
                                <th class="py-3 px-4 text-center">Điểm số</th>
                                <th class="py-3 px-4 text-center">Thoát màn hình</th>
                                <th class="py-3 px-6 text-right">Nộp lúc</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100 text-sm">
                            <?php foreach ($recentSubmissions as $sub):
                                $st = getSubjectBadgeStyle($sub['subject_code']);
                                $exits = (int)($sub['tab_switch_count'] ?? 0);
                            ?>
                                <tr class="hover:bg-slate-50/80 transition">
                                    <td class="py-3.5 px-6">
                                        <div class="font-bold text-slate-800"><?= htmlspecialchars($sub['fullname']) ?></div>
                                        <div class="text-xs text-slate-400">@<?= htmlspecialchars($sub['username']) ?></div>
                                    </td>
                                    <td class="py-3.5 px-4">
                                        <span class="px-2 py-0.5 rounded-md text-[11px] font-extrabold <?= $st['badge'] ?> mr-1.5">
                                            <?= htmlspecialchars($sub['subject_name']) ?>
                                        </span>
                                        <span class="font-bold text-slate-700"><?= htmlspecialchars($sub['exam_title']) ?></span>
                                    </td>
                                    <td class="py-3.5 px-4 text-center text-xs font-bold text-slate-600">
                                        <?= formatDuration((int)$sub['time_spent_seconds']) ?>
                                    </td>
                                    <td class="py-3.5 px-4 text-center font-extrabold text-indigo-700">
                                        <?= number_format((float)$sub['score'], 2) ?> đ
                                    </td>
                                    <td class="py-3.5 px-4 text-center">
                                        <?php if ($exits === 0): ?>
                                            <span class="px-2.5 py-1 rounded-xl text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                                0 lần
                                            </span>
                                        <?php else: ?>
                                            <span class="px-2.5 py-1 rounded-xl text-xs font-extrabold bg-rose-50 text-rose-700 border border-rose-200">
                                                ⚠️ <?= $exits ?> lần
                                            </span>
                                        <?php endif; ?>
                                    </td>
                                    <td class="py-3.5 px-6 text-right text-xs text-slate-500">
                                        <?= date('H:i - d/m/Y', strtotime($sub['completed_at'])) ?>
                                    </td>
                                </tr>
                            <?php endforeach; ?>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>

        <script>
        let monitorAutoRefresh = true;
        const monitorTimer = setInterval(() => {
            if (monitorAutoRefresh) {
                window.location.reload();
            }
        }, 10000);

        function toggleMonitorAutoRefresh() {
            monitorAutoRefresh = !monitorAutoRefresh;
            const btn = document.getElementById('toggleAutoRefreshBtn');
            if (monitorAutoRefresh) {
                btn.innerHTML = '<i class="fa-solid fa-pause mr-1"></i> Tạm dừng tự động';
                btn.className = 'px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition';
            } else {
                btn.innerHTML = '<i class="fa-solid fa-play mr-1"></i> Tiếp tục tự động';
                btn.className = 'px-3.5 py-2 rounded-xl bg-emerald-100 hover:bg-emerald-200 text-emerald-800 text-xs font-bold transition';
            }
        }
        </script>
    <?php endif; ?>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
