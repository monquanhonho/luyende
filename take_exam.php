<?php
require_once __DIR__ . '/config/db.php';
requireLogin();

$examId = (int)($_GET['id'] ?? $_POST['exam_id'] ?? 0);

// Lấy thông tin đề thi & môn học
$stmt = $pdo->prepare("
    SELECT e.*, s.code AS subject_code, s.name AS subject_name, s.icon AS subject_icon, s.gradient AS subject_gradient
    FROM exams e
    JOIN subjects s ON e.subject_id = s.id
    WHERE e.id = ?
    LIMIT 1
");
$stmt->execute([$examId]);
$exam = $stmt->fetch();

if (!$exam) {
    $_SESSION['flash_error'] = 'Đề thi không tồn tại hoặc đã bị xóa!';
    header('Location: index.php');
    exit;
}

// Lấy danh sách câu hỏi của đề
$qStmt = $pdo->prepare("SELECT * FROM questions WHERE exam_id = ? ORDER BY sort_order ASC, id ASC");
$qStmt->execute([$examId]);
$questions = $qStmt->fetchAll();

if (empty($questions)) {
    $_SESSION['flash_error'] = 'Đề thi này hiện chưa có câu hỏi nào. Quản trị viên vui lòng bổ sung câu hỏi!';
    header('Location: index.php');
    exit;
}

// Xử lý khi Học sinh nộp bài (Chấm theo thang điểm chuẩn THPT Quốc Gia 2026)
if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['submit_exam'])) {
    $userAnswers = $_POST['answers'] ?? [];
    $timeSpent = max(1, (int)($_POST['time_spent_seconds'] ?? 60));
    $examSessionId = (int)($_POST['exam_session_id'] ?? 0);
    $tabSwitchCount = max(0, (int)($_POST['tab_switch_count'] ?? 0));
    $totalQuestions = count($questions);
    $correctCount = 0;
    $totalEarnedScore = 0.00;
    $gradedResults = [];

    foreach ($questions as $q) {
        $qid = (int)$q['id'];
        $rawAns = $userAnswers[$qid] ?? null;
        $graded = gradeQuestion($q, $rawAns);
        $gradedResults[$qid] = $graded;
        $totalEarnedScore += $graded['earned_points'];
        if ($graded['is_correct'] === 1) {
            $correctCount++;
        }
    }

    $finalScore = round(min(10.00, $totalEarnedScore), 2);

    $pdo->beginTransaction();
    try {
        $insertAttempt = $pdo->prepare("
            INSERT INTO exam_attempts (user_id, exam_id, score, correct_count, total_questions, time_spent_seconds, tab_switch_count)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        ");
        $insertAttempt->execute([
            currentUser()['id'],
            $examId,
            $finalScore,
            $correctCount,
            $totalQuestions,
            $timeSpent,
            $tabSwitchCount
        ]);
        $attemptId = (int)$pdo->lastInsertId();

        $insertAns = $pdo->prepare("
            INSERT INTO attempt_answers (attempt_id, question_id, selected_option, is_correct, earned_points)
            VALUES (?, ?, ?, ?, ?)
        ");

        foreach ($questions as $q) {
            $qid = (int)$q['id'];
            $res = $gradedResults[$qid];
            $insertAns->execute([
                $attemptId,
                $qid,
                $res['selected_option'],
                $res['is_correct'],
                $res['earned_points']
            ]);
        }

        if ($examSessionId > 0) {
            $closeSession = $pdo->prepare("
                UPDATE exam_sessions
                SET status = 'submitted',
                    last_heartbeat = NOW(),
                    elapsed_seconds = ?,
                    tab_switch_count = ?
                WHERE id = ? AND user_id = ?
            ");
            $closeSession->execute([$timeSpent, $tabSwitchCount, $examSessionId, currentUser()['id']]);
        }

        $pdo->commit();
        $_SESSION['flash_success'] = 'Chúc mừng bạn đã hoàn thành bài thi! Dưới đây là điểm số và lời giải chi tiết.';
        header('Location: result.php?attempt_id=' . $attemptId);
        exit;
    } catch (Exception $e) {
        $pdo->rollBack();
        $_SESSION['flash_error'] = 'Có lỗi khi lưu bài làm: ' . $e->getMessage();
    }
}

// Khởi tạo phiên giám sát làm bài khi học sinh vào phòng thi
$createSession = $pdo->prepare("
    INSERT INTO exam_sessions (user_id, exam_id, total_questions, status)
    VALUES (?, ?, ?, 'in_progress')
");
$createSession->execute([currentUser()['id'], $examId, count($questions)]);
$examSessionId = (int)$pdo->lastInsertId();

$style = getSubjectBadgeStyle($exam['subject_code']);
$pageTitle = 'Làm bài: ' . $exam['title'];
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
    <!-- Thanh thông tin đề thi -->
    <div class="bg-white rounded-3xl border border-slate-200/80 p-5 sm:p-6 shadow-sm mb-6">
        <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div class="flex items-start gap-4">
                <div class="w-12 h-12 rounded-2xl bg-gradient-to-br <?= htmlspecialchars($exam['subject_gradient']) ?> text-white flex items-center justify-center text-xl shrink-0 shadow">
                    <i class="fa-solid <?= htmlspecialchars($exam['subject_icon']) ?>"></i>
                </div>
                <div>
                    <div class="flex flex-wrap items-center gap-2">
                        <span class="px-2.5 py-0.5 rounded-lg text-xs font-extrabold <?= $style['badge'] ?>">
                            Môn <?= htmlspecialchars($exam['subject_name']) ?>
                        </span>
                        <span class="px-2.5 py-0.5 rounded-lg text-xs font-extrabold bg-indigo-50 text-indigo-700 border border-indigo-200">
                            <?= htmlspecialchars($exam['level']) ?>
                        </span>
                        <span class="text-xs text-slate-500 font-semibold">
                            • <?= count($questions) ?> câu • <?= (int)$exam['duration_minutes'] ?> phút • Thang điểm 10.00
                        </span>
                    </div>
                    <h1 class="text-xl sm:text-2xl font-extrabold text-slate-900 mt-1">
                        <?= htmlspecialchars($exam['title']) ?>
                    </h1>
                </div>
            </div>

            <div class="flex flex-wrap items-center gap-2 self-start md:self-center">
                <span id="proctorBadge" class="px-3 py-2 rounded-xl bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-bold flex items-center gap-1.5">
                    <i class="fa-solid fa-eye"></i> Giám sát: <span id="tabSwitchBadgeCount">0</span> lần rời màn hình
                </span>
                <a href="index.php?subject=<?= urlencode($exam['subject_code']) ?>"
                   onclick="return confirmExitExam()"
                   class="px-4 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition">
                    <i class="fa-solid fa-arrow-left mr-1"></i> Thoát phòng thi
                </a>
            </div>
        </div>
    </div>

    <!-- Cảnh báo khi học sinh rời khỏi màn hình thi -->
    <div id="proctorAlertBanner" class="hidden mb-5 p-4 rounded-2xl bg-rose-50 border-2 border-rose-300 text-rose-800 text-sm font-bold flex items-center justify-between gap-3 shadow-sm">
        <div class="flex items-center gap-3">
            <i class="fa-solid fa-triangle-exclamation text-rose-600 text-lg"></i>
            <span id="proctorAlertText">Cảnh báo: Hệ thống ghi nhận bạn vừa rời khỏi màn hình làm bài!</span>
        </div>
        <button type="button" onclick="this.parentElement.classList.add('hidden')" class="text-rose-500 hover:text-rose-700">
            <i class="fa-solid fa-xmark"></i>
        </button>
    </div>

    <form method="POST" action="take_exam.php?id=<?= $examId ?>" id="examForm">
        <input type="hidden" name="exam_id" value="<?= $examId ?>">
        <input type="hidden" name="submit_exam" value="1">
        <input type="hidden" name="exam_session_id" value="<?= $examSessionId ?>">
        <input type="hidden" name="time_spent_seconds" id="timeSpentInput" value="0">
        <input type="hidden" name="tab_switch_count" id="tabSwitchInput" value="0">

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            <!-- Cột trái: Danh sách câu hỏi theo 3 dạng Form 2026 (8 cột) -->
            <div class="lg:col-span-8 space-y-5">
                <?php
                $hasMultiType = false;
                foreach ($questions as $qCheck) {
                    if (($qCheck['question_type'] ?? 'mcq') !== 'mcq') {
                        $hasMultiType = true;
                        break;
                    }
                }
                $prevType = null;
                $prevDiff = null;
                foreach ($questions as $index => $q):
                    $qNum = $index + 1;
                    $qId = (int)$q['id'];
                    $qType = $q['question_type'] ?? 'mcq';
                    $typeInfo = getQuestionTypeInfo($qType);
                    $diff = $q['difficulty'] ?? 'Nhận biết';
                    $diffStyle = getDifficultyBadgeStyle($diff);

                    if ($hasMultiType && $qType !== $prevType):
                        $prevType = $qType;
                ?>
                    <!-- Tiêu đề phân phần theo dạng câu hỏi -->
                    <div class="rounded-3xl border p-5 shadow-sm <?= $typeInfo['pill'] ?>">
                        <div class="flex items-start gap-3.5">
                            <div class="w-10 h-10 rounded-xl text-white flex items-center justify-center shrink-0 shadow-sm <?= $typeInfo['bar'] ?>">
                                <i class="fa-solid <?= $typeInfo['icon'] ?>"></i>
                            </div>
                            <div>
                                <div class="text-sm sm:text-base font-extrabold">
                                    <?= htmlspecialchars($typeInfo['label']) ?>
                                </div>
                                <p class="text-xs mt-0.5 opacity-90 leading-relaxed">
                                    <?= htmlspecialchars($typeInfo['desc']) ?>
                                </p>
                            </div>
                        </div>
                    </div>
                <?php elseif (!$hasMultiType && $diff !== $prevDiff):
                        $prevDiff = $diff;
                ?>
                    <!-- Tiêu đề phân phần theo mức độ THPT Quốc Gia -->
                    <div class="rounded-2xl border px-5 py-3.5 flex items-center gap-3 shadow-sm <?= $diffStyle['pill'] ?>">
                        <div class="w-9 h-9 rounded-xl text-white flex items-center justify-center shrink-0 <?= $diffStyle['bar'] ?>">
                            <i class="fa-solid <?= $diffStyle['icon'] ?>"></i>
                        </div>
                        <div class="text-xs sm:text-sm font-extrabold uppercase tracking-wide">
                            Mức độ: <?= htmlspecialchars($diff) ?> (<?= number_format((float)$q['points_value'], 2) ?> điểm/câu)
                        </div>
                    </div>
                <?php endif; ?>

                    <div id="question-block-<?= $qNum ?>" class="bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm scroll-mt-24 transition">
                        <div class="flex flex-wrap items-center justify-between gap-2 mb-4">
                            <div class="flex flex-wrap items-center gap-2">
                                <span class="w-9 h-9 rounded-xl bg-indigo-600 text-white font-extrabold text-sm flex items-center justify-center shadow-sm">
                                    <?= $qNum ?>
                                </span>
                                <span class="px-2.5 py-1 rounded-lg text-[11px] font-extrabold border <?= $typeInfo['pill'] ?>">
                                    <?= htmlspecialchars($typeInfo['short']) ?> • <?= number_format((float)$q['points_value'], 2) ?>đ
                                </span>
                                <span class="px-2.5 py-1 rounded-lg text-[11px] font-extrabold border <?= $diffStyle['pill'] ?>">
                                    <i class="fa-solid <?= $diffStyle['icon'] ?> mr-1"></i><?= htmlspecialchars($diff) ?>
                                </span>
                            </div>

                            <div class="flex items-center gap-2">
                                <button type="button"
                                        id="flag-btn-<?= $qNum ?>"
                                        onclick="toggleFlag(<?= $qNum ?>)"
                                        class="px-2.5 py-1 rounded-lg text-[11px] font-bold border border-slate-200 text-slate-500 hover:bg-amber-50 hover:text-amber-700 hover:border-amber-300 transition flex items-center gap-1">
                                    <i class="fa-regular fa-flag"></i> Xem lại
                                </button>
                                <span id="status-badge-<?= $qNum ?>" class="px-2.5 py-1 rounded-lg text-[11px] font-bold bg-slate-100 text-slate-500">
                                    Chưa làm
                                </span>
                            </div>
                        </div>

                        <!-- Nội dung đề dẫn câu hỏi -->
                        <div class="text-base font-bold text-slate-800 leading-relaxed mb-5">
                            <?= nl2br(htmlspecialchars($q['question_text'])) ?>
                        </div>

                        <?php if ($qType === 'mcq'): ?>
                            <!-- DẠNG 1: TRẮC NGHIỆM 4 PHƯƠNG ÁN A B C D -->
                            <?php
                            $options = [
                                'A' => $q['option_a'],
                                'B' => $q['option_b'],
                                'C' => $q['option_c'],
                                'D' => $q['option_d'],
                            ];
                            ?>
                            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                                <?php foreach ($options as $letter => $optText): ?>
                                    <label class="option-card cursor-pointer group relative flex items-center gap-3.5 p-4 rounded-2xl border-2 border-slate-200/80 hover:border-indigo-400 hover:bg-indigo-50/40 transition">
                                        <input type="radio"
                                               name="answers[<?= $qId ?>]"
                                               value="<?= $letter ?>"
                                               class="sr-only"
                                               onchange="handleSelectMcq(<?= $qNum ?>, '<?= $letter ?>', this)">
                                        <span class="option-letter w-9 h-9 rounded-xl bg-slate-100 text-slate-700 font-extrabold text-sm flex items-center justify-center shrink-0 group-hover:bg-indigo-100 group-hover:text-indigo-700 transition">
                                            <?= $letter ?>
                                        </span>
                                        <span class="text-sm font-semibold text-slate-700 leading-snug">
                                            <?= htmlspecialchars((string)$optText) ?>
                                        </span>
                                    </label>
                                <?php endforeach; ?>
                            </div>

                        <?php elseif ($qType === 'true_false'): ?>
                            <!-- DẠNG 2: TRẮC NGHIỆM ĐÚNG / SAI (4 Ý a, b, c, d) -->
                            <?php
                            $statements = [
                                'a' => $q['option_a'],
                                'b' => $q['option_b'],
                                'c' => $q['option_c'],
                                'd' => $q['option_d'],
                            ];
                            ?>
                            <div class="space-y-3">
                                <?php foreach ($statements as $subKey => $stmtText): ?>
                                    <div class="p-4 rounded-2xl bg-slate-50/80 border border-slate-200/80 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                                        <div class="text-sm font-semibold text-slate-800 leading-relaxed flex-1">
                                            <?= htmlspecialchars((string)$stmtText) ?>
                                        </div>
                                        <div class="flex items-center gap-2 shrink-0">
                                            <label class="tf-pill cursor-pointer">
                                                <input type="radio"
                                                       name="answers[<?= $qId ?>][<?= $subKey ?>]"
                                                       value="D"
                                                       class="sr-only"
                                                       onchange="handleSelectTrueFalse(<?= $qNum ?>, '<?= $subKey ?>', 'D', this)">
                                                <span class="tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-slate-200 bg-white text-slate-600 text-xs font-extrabold hover:border-emerald-400 transition">
                                                    <i class="fa-solid fa-check"></i> Đúng
                                                </span>
                                            </label>
                                            <label class="tf-pill cursor-pointer">
                                                <input type="radio"
                                                       name="answers[<?= $qId ?>][<?= $subKey ?>]"
                                                       value="S"
                                                       class="sr-only"
                                                       onchange="handleSelectTrueFalse(<?= $qNum ?>, '<?= $subKey ?>', 'S', this)">
                                                <span class="tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-slate-200 bg-white text-slate-600 text-xs font-extrabold hover:border-rose-400 transition">
                                                    <i class="fa-solid fa-xmark"></i> Sai
                                                </span>
                                            </label>
                                        </div>
                                    </div>
                                <?php endforeach; ?>
                            </div>

                        <?php else: ?>
                            <!-- DẠNG 3: TRẮC NGHIỆM TRẢ LỜI NGẮN -->
                            <div class="p-5 rounded-2xl bg-teal-50/50 border-2 border-teal-200/70">
                                <label class="block text-xs font-extrabold uppercase tracking-wider text-teal-800 mb-2">
                                    <i class="fa-solid fa-pen-nib mr-1"></i> Nhập đáp số của bạn (tối đa 4 ký tự số / dấu trừ / dấu chấm):
                                </label>
                                <input type="text"
                                       name="answers[<?= $qId ?>]"
                                       oninput="handleShortAnswer(<?= $qNum ?>, this.value)"
                                       placeholder="Nhập đáp số..."
                                       autocomplete="off"
                                       class="w-full sm:w-80 px-4 py-3.5 rounded-xl bg-white border-2 border-teal-300 focus:border-teal-600 focus:ring-4 focus:ring-teal-500/15 outline-none text-lg font-extrabold font-mono text-slate-900 transition">
                                <p class="text-[11px] text-teal-700 mt-2 font-medium">
                                    * Dùng dấu chấm (.) hoặc dấu phẩy (,) cho số thập phân. Không nhập kèm đơn vị đo.
                                </p>
                            </div>
                        <?php endif; ?>
                    </div>
                <?php endforeach; ?>
            </div>

            <!-- Cột phải: Đồng hồ & Phiếu trả lời nhanh (Sticky 4 cột) -->
            <div class="lg:col-span-4 lg:sticky lg:top-20 space-y-5">
                <div class="bg-white rounded-3xl border border-slate-200/80 p-5 shadow-sm">
                    <!-- Đồng hồ đếm ngược -->
                    <div class="text-center p-4 rounded-2xl bg-slate-900 text-white mb-4">
                        <div class="text-[11px] uppercase tracking-widest text-indigo-300 font-bold">Thời gian còn lại</div>
                        <div id="countdownTimer" class="text-3xl font-extrabold tracking-wider mt-1 font-mono text-amber-300">
                            <?= sprintf('%02d:00', (int)$exam['duration_minutes']) ?>
                        </div>
                    </div>

                    <!-- Thanh tiến độ -->
                    <div class="mb-4">
                        <div class="flex items-center justify-between text-xs font-bold text-slate-600 mb-1.5">
                            <span>Tiến độ hoàn thành</span>
                            <span><span id="answeredCount" class="text-indigo-600">0</span> / <?= count($questions) ?> câu</span>
                        </div>
                        <div class="w-full h-2.5 bg-slate-100 rounded-full overflow-hidden">
                            <div id="progressBar" class="h-full bg-gradient-to-r from-indigo-600 to-teal-500 transition-all duration-300" style="width: 0%"></div>
                        </div>
                    </div>

                    <!-- Bộ lọc nhanh phiếu trả lời -->
                    <div class="mb-3">
                        <div class="flex items-center justify-between text-xs font-bold text-slate-500 mb-2">
                            <span>Phiếu trả lời Form 2026</span>
                            <span id="flaggedCountBadge" class="text-amber-600 font-bold hidden">0 đánh dấu</span>
                        </div>
                        <div class="grid grid-cols-3 gap-1.5 bg-slate-100 p-1 rounded-xl text-[11px] font-bold mb-2.5">
                            <button type="button" onclick="filterPalette('all')" id="filter-btn-all" class="py-1.5 rounded-lg bg-white text-indigo-700 shadow-sm transition">
                                Tất cả (<?= count($questions) ?>)
                            </button>
                            <button type="button" onclick="filterPalette('unanswered')" id="filter-btn-unanswered" class="py-1.5 rounded-lg text-slate-600 hover:text-slate-900 transition">
                                Chưa làm
                            </button>
                            <button type="button" onclick="filterPalette('flagged')" id="filter-btn-flagged" class="py-1.5 rounded-lg text-slate-600 hover:text-slate-900 transition">
                                Đánh dấu
                            </button>
                        </div>
                        <div class="flex items-center justify-between text-[10px] font-semibold text-slate-500 px-1">
                            <span class="flex items-center gap-1"><span class="w-2.5 h-2.5 rounded bg-slate-200 inline-block"></span> Chưa làm</span>
                            <span class="flex items-center gap-1"><span class="w-2.5 h-2.5 rounded bg-indigo-600 inline-block"></span> Đã làm</span>
                            <span class="flex items-center gap-1"><span class="w-2.5 h-2.5 rounded bg-amber-400 inline-block"></span> Đánh dấu</span>
                        </div>
                    </div>

                    <!-- Bảng ô phiếu trả lời cuộn gọn -->
                    <div class="max-h-[40vh] overflow-y-auto pr-1 mb-5">
                        <div class="grid grid-cols-5 gap-1.5" id="paletteGrid">
                            <?php foreach ($questions as $index => $q):
                                $qNum = $index + 1;
                                $qType = $q['question_type'] ?? 'mcq';
                            ?>
                                <button type="button"
                                        id="palette-btn-<?= $qNum ?>"
                                        data-qnum="<?= $qNum ?>"
                                        data-qtype="<?= htmlspecialchars($qType) ?>"
                                        onclick="scrollToQuestion(<?= $qNum ?>)"
                                        class="palette-item h-9 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 font-extrabold text-[11px] hover:border-indigo-400 transition flex items-center justify-center">
                                    <?= $qNum ?>
                                </button>
                            <?php endforeach; ?>
                        </div>
                    </div>

                    <!-- Nút Nộp bài -->
                    <button type="button" onclick="confirmSubmitExam()"
                            class="w-full py-3.5 px-6 rounded-2xl bg-gradient-to-r from-indigo-600 to-blue-600 hover:from-indigo-700 hover:to-blue-700 text-white font-extrabold text-sm shadow-lg shadow-indigo-500/25 transition flex items-center justify-center gap-2">
                        <i class="fa-solid fa-paper-plane"></i> NỘP BÀI & CHẤM ĐIỂM 2026
                    </button>
                </div>
            </div>
        </div>
    </form>
</div>

<script>
window.EXAM_CONFIG = {
    totalQuestions: <?= count($questions) ?>,
    totalSeconds: <?= (int)$exam['duration_minutes'] * 60 ?>,
    examSessionId: <?= $examSessionId ?>
};
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
