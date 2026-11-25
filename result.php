<?php
require_once __DIR__ . '/config/db.php';
requireLogin();

$attemptId = (int)($_GET['attempt_id'] ?? 0);

$stmt = $pdo->prepare("
    SELECT ea.*, e.title AS exam_title, e.level AS exam_level, e.duration_minutes,
           s.code AS subject_code, s.name AS subject_name, s.icon AS subject_icon, s.gradient AS subject_gradient,
           u.fullname AS student_name, u.class_name
    FROM exam_attempts ea
    JOIN exams e ON ea.exam_id = e.id
    JOIN subjects s ON e.subject_id = s.id
    JOIN users u ON ea.user_id = u.id
    WHERE ea.id = ?
    LIMIT 1
");
$stmt->execute([$attemptId]);
$attempt = $stmt->fetch();

if (!$attempt) {
    $_SESSION['flash_error'] = 'Không tìm thấy kết quả bài thi này!';
    header('Location: index.php');
    exit;
}

if (!isAdmin() && (int)$attempt['user_id'] !== currentUser()['id']) {
    $_SESSION['flash_error'] = 'Bạn không có quyền xem kết quả bài làm của người khác!';
    header('Location: index.php');
    exit;
}

// Lấy chi tiết câu hỏi & đáp án đã chọn
$qStmt = $pdo->prepare("
    SELECT q.*, aa.selected_option, aa.is_correct, aa.earned_points
    FROM questions q
    LEFT JOIN attempt_answers aa ON aa.question_id = q.id AND aa.attempt_id = ?
    WHERE q.exam_id = ?
    ORDER BY q.sort_order ASC, q.id ASC
");
$qStmt->execute([$attemptId, $attempt['exam_id']]);
$reviewQuestions = $qStmt->fetchAll();

// Thống kê theo 3 Phần thi Form 2025 & theo 4 mức độ nhận thức
$partStats = [
    'mcq' => ['count' => 0, 'earned' => 0.0, 'max' => 0.0],
    'true_false' => ['count' => 0, 'earned' => 0.0, 'max' => 0.0],
    'short_answer' => ['count' => 0, 'earned' => 0.0, 'max' => 0.0],
];

$difficultyStats = [
    'Nhận biết' => ['total' => 0, 'correct' => 0],
    'Thông hiểu' => ['total' => 0, 'correct' => 0],
    'Vận dụng' => ['total' => 0, 'correct' => 0],
    'Vận dụng cao' => ['total' => 0, 'correct' => 0],
];

$notMaxCount = 0;
$fullCorrectCount = 0;

foreach ($reviewQuestions as $rq) {
    $qType = $rq['question_type'] ?? 'mcq';
    $maxPts = (float)($rq['points_value'] ?? 0.25);
    $earnedPts = isset($rq['earned_points']) ? (float)$rq['earned_points'] : 0.0;

    if (isset($partStats[$qType])) {
        $partStats[$qType]['count']++;
        $partStats[$qType]['max'] += $maxPts;
        $partStats[$qType]['earned'] += $earnedPts;
    }

    $diff = $rq['difficulty'] ?? 'Nhận biết';
    if (!isset($difficultyStats[$diff])) {
        $difficultyStats[$diff] = ['total' => 0, 'correct' => 0];
    }
    $difficultyStats[$diff]['total']++;

    if ((int)$rq['is_correct'] === 1) {
        $difficultyStats[$diff]['correct']++;
        $fullCorrectCount++;
    } else {
        $notMaxCount++;
    }
}

$score = (float)$attempt['score'];
if ($score >= 8.0) {
    $rankText = 'Xuất sắc! Rất sẵn sàng cho kỳ thi THPT 2025';
    $rankColor = 'text-emerald-600 bg-emerald-50 border-emerald-200';
} elseif ($score >= 6.5) {
    $rankText = 'Khá tốt! Hãy tối ưu thêm phần Đúng/Sai & Trả lời ngắn';
    $rankColor = 'text-blue-600 bg-blue-50 border-blue-200';
} elseif ($score >= 5.0) {
    $rankText = 'Đạt yêu cầu! Cần ôn chắc kiến thức nền tảng';
    $rankColor = 'text-amber-600 bg-amber-50 border-amber-200';
} else {
    $rankText = 'Cần cố gắng! Xem kỹ lời giải các câu chưa đạt điểm';
    $rankColor = 'text-rose-600 bg-rose-50 border-rose-200';
}

$pageTitle = 'Kết quả: ' . $attempt['exam_title'];
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <!-- Bảng Tổng Kết Điểm Số -->
    <div class="bg-white rounded-3xl border border-slate-200/80 shadow-lg shadow-slate-200/40 overflow-hidden mb-8">
        <div class="bg-gradient-to-r <?= htmlspecialchars($attempt['subject_gradient']) ?> p-6 sm:p-8 text-white">
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                    <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/20 text-xs font-bold">
                        <i class="fa-solid <?= htmlspecialchars($attempt['subject_icon']) ?>"></i>
                        Môn <?= htmlspecialchars($attempt['subject_name']) ?> • <?= htmlspecialchars($attempt['exam_level']) ?>
                    </span>
                    <h1 class="text-2xl sm:text-3xl font-extrabold mt-2"><?= htmlspecialchars($attempt['exam_title']) ?></h1>
                    <p class="text-white/85 text-xs sm:text-sm mt-1">
                        Học sinh: <b><?= htmlspecialchars($attempt['student_name']) ?></b> (<?= htmlspecialchars($attempt['class_name']) ?>)
                        • Hoàn thành lúc <?= date('H:i - d/m/Y', strtotime($attempt['completed_at'])) ?>
                    </p>
                </div>

                <!-- Vòng điểm nổi bật -->
                <div class="bg-white text-slate-900 rounded-3xl px-7 py-5 text-center shadow-lg shrink-0">
                    <div class="text-[11px] font-extrabold uppercase tracking-wider text-slate-400">Tổng điểm (Form 2025)</div>
                    <div class="text-4xl font-black text-indigo-600 mt-0.5">
                        <?= number_format($score, 2) ?><span class="text-lg text-slate-400 font-bold">/10</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="p-6 sm:p-8">
            <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
                <div class="p-4 rounded-2xl bg-emerald-50 border border-emerald-100 flex items-center gap-3.5">
                    <div class="w-11 h-11 rounded-xl bg-emerald-600 text-white flex items-center justify-center text-lg">
                        <i class="fa-solid fa-check-double"></i>
                    </div>
                    <div>
                        <div class="text-xs text-emerald-700 font-semibold">Câu đạt điểm tối đa</div>
                        <div class="text-xl font-extrabold text-emerald-900">
                            <?= (int)$attempt['correct_count'] ?> / <?= (int)$attempt['total_questions'] ?> câu
                        </div>
                    </div>
                </div>

                <div class="p-4 rounded-2xl bg-indigo-50 border border-indigo-100 flex items-center gap-3.5">
                    <div class="w-11 h-11 rounded-xl bg-indigo-600 text-white flex items-center justify-center text-lg">
                        <i class="fa-solid fa-stopwatch"></i>
                    </div>
                    <div>
                        <div class="text-xs text-indigo-700 font-semibold">Thời gian hoàn thành</div>
                        <div class="text-xl font-extrabold text-indigo-900">
                            <?= formatDuration((int)$attempt['time_spent_seconds']) ?>
                        </div>
                    </div>
                </div>

                <div class="p-4 rounded-2xl border flex items-center gap-3.5 <?= $rankColor ?>">
                    <div class="w-11 h-11 rounded-xl bg-white/80 flex items-center justify-center text-lg shrink-0">
                        <i class="fa-solid fa-award"></i>
                    </div>
                    <div>
                        <div class="text-xs font-bold uppercase">Đánh giá năng lực</div>
                        <div class="text-xs font-extrabold mt-0.5 leading-snug"><?= htmlspecialchars($rankText) ?></div>
                    </div>
                </div>
            </div>

            <!-- Phân tích điểm theo 3 Phần thi Form 2025 -->
            <div class="mb-6 pt-5 border-t border-slate-100">
                <h3 class="text-sm font-extrabold text-slate-800 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <i class="fa-solid fa-layer-group text-indigo-600"></i> Phân tích điểm theo cấu trúc đề thi mới 2025
                </h3>
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    <?php foreach ($partStats as $pType => $pData):
                        if ($pData['count'] === 0) continue;
                        $tInfo = getQuestionTypeInfo($pType);
                        $pPct = $pData['max'] > 0 ? round(($pData['earned'] / $pData['max']) * 100) : 0;
                    ?>
                        <div class="p-4 rounded-2xl border <?= $tInfo['pill'] ?>">
                            <div class="flex items-center justify-between text-xs font-extrabold mb-1">
                                <span><i class="fa-solid <?= $tInfo['icon'] ?> mr-1"></i><?= htmlspecialchars($tInfo['short']) ?> (<?= $pData['count'] ?> câu)</span>
                                <span><?= $pPct ?>%</span>
                            </div>
                            <div class="text-xl font-black mb-2">
                                <?= number_format($pData['earned'], 2) ?> / <?= number_format($pData['max'], 2) ?> đ
                            </div>
                            <div class="w-full h-2 rounded-full bg-white/80 overflow-hidden">
                                <div class="h-full <?= $tInfo['bar'] ?>" style="width: <?= $pPct ?>%"></div>
                            </div>
                        </div>
                    <?php endforeach; ?>
                </div>
            </div>

            <!-- Phân tích năng lực theo 4 mức độ -->
            <div class="mb-6 pt-5 border-t border-slate-100">
                <h3 class="text-sm font-extrabold text-slate-800 uppercase tracking-wider mb-3 flex items-center gap-2">
                    <i class="fa-solid fa-chart-pie text-indigo-600"></i> Phân tích theo 4 mức độ nhận thức
                </h3>
                <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
                    <?php foreach ($difficultyStats as $diffName => $stat):
                        if ($stat['total'] === 0) continue;
                        $dStyle = getDifficultyBadgeStyle($diffName);
                        $pct = round(($stat['correct'] / $stat['total']) * 100);
                    ?>
                        <div class="p-4 rounded-2xl border bg-slate-50/70 <?= $dStyle['pill'] ?>">
                            <div class="flex items-center justify-between text-xs font-extrabold mb-1.5">
                                <span><i class="fa-solid <?= $dStyle['icon'] ?> mr-1"></i><?= htmlspecialchars($diffName) ?></span>
                                <span><?= $pct ?>%</span>
                            </div>
                            <div class="text-lg font-black mb-2">
                                <?= $stat['correct'] ?> / <?= $stat['total'] ?> câu trọn điểm
                            </div>
                            <div class="w-full h-2 rounded-full bg-white/80 overflow-hidden">
                                <div class="h-full <?= $dStyle['bar'] ?>" style="width: <?= $pct ?>%"></div>
                            </div>
                        </div>
                    <?php endforeach; ?>
                </div>
            </div>

            <div class="flex flex-wrap items-center justify-between gap-3 pt-4 border-t border-slate-100">
                <a href="index.php?subject=<?= urlencode($attempt['subject_code']) ?>" class="px-5 py-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition">
                    <i class="fa-solid fa-arrow-left mr-1"></i> Về kho đề môn <?= htmlspecialchars($attempt['subject_name']) ?>
                </a>
                <div class="flex items-center gap-3">
                    <a href="history.php" class="px-5 py-2.5 rounded-xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 text-xs font-bold transition">
                        <i class="fa-solid fa-clock-rotate-left mr-1"></i> Lịch sử các đề đã làm
                    </a>
                    <a href="take_exam.php?id=<?= (int)$attempt['exam_id'] ?>" class="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold shadow-sm transition">
                        <i class="fa-solid fa-rotate-right mr-1"></i> Luyện lại đề này
                    </a>
                </div>
            </div>
        </div>
    </div>

    <!-- Chi tiết đáp án & Bộ lọc nhanh -->
    <div class="mb-5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <h2 class="text-xl font-extrabold text-slate-900 flex items-center gap-2">
            <i class="fa-solid fa-book-open-reader text-indigo-600"></i>
            Đáp án & Lời giải chi tiết (<?= count($reviewQuestions) ?> câu)
        </h2>

        <div class="inline-flex bg-white p-1 rounded-xl border border-slate-200 shadow-sm text-xs font-bold">
            <button type="button" onclick="filterReview('all')" id="rev-filter-all" class="px-3.5 py-2 rounded-lg bg-indigo-600 text-white transition">
                Tất cả (<?= count($reviewQuestions) ?>)
            </button>
            <button type="button" onclick="filterReview('wrong')" id="rev-filter-wrong" class="px-3.5 py-2 rounded-lg text-slate-600 hover:text-rose-600 transition">
                Chưa trọn điểm (<?= $notMaxCount ?>)
            </button>
            <button type="button" onclick="filterReview('correct')" id="rev-filter-correct" class="px-3.5 py-2 rounded-lg text-slate-600 hover:text-emerald-600 transition">
                Trọn điểm (<?= $fullCorrectCount ?>)
            </button>
        </div>
    </div>

    <div class="space-y-5" id="reviewList">
        <?php foreach ($reviewQuestions as $index => $q):
            $qNum = $index + 1;
            $qType = $q['question_type'] ?? 'mcq';
            $typeInfo = getQuestionTypeInfo($qType);
            $selected = $q['selected_option'];
            $correct = $q['correct_option'];
            $isCorrect = ((int)$q['is_correct'] === 1);
            $earnedPts = isset($q['earned_points']) ? (float)$q['earned_points'] : 0.0;
            $maxPts = (float)($q['points_value'] ?? 0.25);
            $diff = $q['difficulty'] ?? 'Nhận biết';
            $diffStyle = getDifficultyBadgeStyle($diff);
        ?>
            <div data-status="<?= $isCorrect ? 'correct' : 'wrong' ?>"
                 class="review-item bg-white rounded-3xl border <?= $isCorrect ? 'border-emerald-200' : ($earnedPts > 0 ? 'border-amber-200' : 'border-rose-200') ?> p-6 shadow-sm">
                <div class="flex flex-wrap items-center justify-between gap-2 mb-4">
                    <div class="flex flex-wrap items-center gap-2">
                        <span class="w-9 h-9 rounded-xl font-extrabold text-sm flex items-center justify-center text-white <?= $isCorrect ? 'bg-emerald-600' : ($earnedPts > 0 ? 'bg-amber-500' : 'bg-rose-600') ?>">
                            <?= $qNum ?>
                        </span>
                        <span class="px-2.5 py-1 rounded-lg text-[11px] font-extrabold border <?= $typeInfo['pill'] ?>">
                            <?= htmlspecialchars($typeInfo['short']) ?>
                        </span>
                        <span class="px-2.5 py-1 rounded-lg text-[11px] font-extrabold border <?= $diffStyle['pill'] ?>">
                            <i class="fa-solid <?= $diffStyle['icon'] ?> mr-1"></i><?= htmlspecialchars($diff) ?>
                        </span>
                    </div>

                    <span class="px-3 py-1 rounded-xl text-xs font-extrabold border <?= $isCorrect ? 'bg-emerald-50 text-emerald-700 border-emerald-200' : ($earnedPts > 0 ? 'bg-amber-50 text-amber-800 border-amber-200' : 'bg-rose-50 text-rose-700 border-rose-200') ?>">
                        +<?= number_format($earnedPts, 2) ?> / <?= number_format($maxPts, 2) ?> điểm
                    </span>
                </div>

                <div class="text-base font-bold text-slate-800 leading-relaxed mb-4">
                    <?= nl2br(htmlspecialchars($q['question_text'])) ?>
                </div>

                <?php if ($qType === 'mcq'): ?>
                    <?php
                    $options = [
                        'A' => $q['option_a'],
                        'B' => $q['option_b'],
                        'C' => $q['option_c'],
                        'D' => $q['option_d'],
                    ];
                    ?>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4">
                        <?php foreach ($options as $letter => $optText):
                            $isThisCorrect = ($letter === $correct);
                            $isThisSelected = ($letter === $selected);
                            if ($isThisCorrect) {
                                $boxStyle = 'border-emerald-500 bg-emerald-50/80 text-emerald-900';
                                $badgeStyle = 'bg-emerald-600 text-white';
                            } elseif ($isThisSelected && !$isThisCorrect) {
                                $boxStyle = 'border-rose-400 bg-rose-50/80 text-rose-900';
                                $badgeStyle = 'bg-rose-600 text-white';
                            } else {
                                $boxStyle = 'border-slate-200 bg-slate-50/50 text-slate-600';
                                $badgeStyle = 'bg-slate-200 text-slate-700';
                            }
                        ?>
                            <div class="flex items-center justify-between gap-3 p-3.5 rounded-2xl border-2 <?= $boxStyle ?>">
                                <div class="flex items-center gap-3">
                                    <span class="w-8 h-8 rounded-xl font-extrabold text-xs flex items-center justify-center shrink-0 <?= $badgeStyle ?>">
                                        <?= $letter ?>
                                    </span>
                                    <span class="text-sm font-semibold"><?= htmlspecialchars((string)$optText) ?></span>
                                </div>
                                <?php if ($isThisCorrect): ?>
                                    <i class="fa-solid fa-check text-emerald-600"></i>
                                <?php elseif ($isThisSelected): ?>
                                    <i class="fa-solid fa-xmark text-rose-600"></i>
                                <?php endif; ?>
                            </div>
                        <?php endforeach; ?>
                    </div>

                <?php elseif ($qType === 'true_false'): ?>
                    <?php
                    $statements = [$q['option_a'], $q['option_b'], $q['option_c'], $q['option_d']];
                    $expParts = array_map('trim', explode(',', strtoupper($correct)));
                    $userParts = $selected ? explode(',', strtoupper($selected)) : ['', '', '', ''];
                    ?>
                    <div class="space-y-2 mb-4">
                        <?php foreach ($statements as $sIdx => $sText):
                            $expVal = $expParts[$sIdx] ?? 'D';
                            $usrVal = $userParts[$sIdx] ?? '';
                            $subRight = ($usrVal !== '' && $usrVal === $expVal);
                            $expLabel = ($expVal === 'D') ? 'Đúng' : 'Sai';
                            $usrLabel = ($usrVal === 'D') ? 'Đúng' : (($usrVal === 'S') ? 'Sai' : 'Bỏ trống');
                        ?>
                            <div class="p-3.5 rounded-2xl border flex flex-col sm:flex-row sm:items-center justify-between gap-2 <?= $subRight ? 'bg-emerald-50/60 border-emerald-200' : 'bg-rose-50/60 border-rose-200' ?>">
                                <span class="text-sm font-semibold text-slate-800"><?= htmlspecialchars((string)$sText) ?></span>
                                <div class="flex items-center gap-2 text-xs font-extrabold shrink-0">
                                    <span class="px-2.5 py-1 rounded-lg bg-white border border-slate-200 text-slate-700">
                                        Chọn: <?= $usrLabel ?>
                                    </span>
                                    <span class="px-2.5 py-1 rounded-lg <?= $subRight ? 'bg-emerald-600 text-white' : 'bg-rose-600 text-white' ?>">
                                        Đáp án: <?= $expLabel ?>
                                    </span>
                                </div>
                            </div>
                        <?php endforeach; ?>
                    </div>

                <?php else: ?>
                    <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4">
                        <div class="p-4 rounded-2xl border-2 <?= $isCorrect ? 'border-emerald-400 bg-emerald-50' : 'border-rose-300 bg-rose-50' ?>">
                            <div class="text-[11px] font-bold uppercase text-slate-500">Đáp số của bạn</div>
                            <div class="text-lg font-extrabold font-mono mt-0.5 <?= $isCorrect ? 'text-emerald-800' : 'text-rose-800' ?>">
                                <?= $selected !== null && $selected !== '' ? htmlspecialchars($selected) : '(Bỏ trống)' ?>
                            </div>
                        </div>
                        <div class="p-4 rounded-2xl border-2 border-emerald-400 bg-emerald-50">
                            <div class="text-[11px] font-bold uppercase text-emerald-700">Đáp án chuẩn</div>
                            <div class="text-lg font-extrabold font-mono text-emerald-900 mt-0.5">
                                <?= htmlspecialchars($correct) ?>
                            </div>
                        </div>
                    </div>
                <?php endif; ?>

                <?php if (!empty($q['explanation'])): ?>
                    <div class="p-4 rounded-2xl bg-indigo-50/70 border border-indigo-100 text-xs sm:text-sm text-indigo-950 leading-relaxed">
                        <div class="font-extrabold text-indigo-700 mb-1 flex items-center gap-1.5">
                            <i class="fa-solid fa-lightbulb text-amber-500"></i> Giải thích chi tiết:
                        </div>
                        <?= nl2br(htmlspecialchars($q['explanation'])) ?>
                    </div>
                <?php endif; ?>
            </div>
        <?php endforeach; ?>
    </div>
</div>

<script>
function filterReview(type) {
    ['all', 'wrong', 'correct'].forEach(t => {
        const btn = document.getElementById('rev-filter-' + t);
        if (t === type) {
            btn.className = 'px-3.5 py-2 rounded-lg bg-indigo-600 text-white transition';
        } else {
            btn.className = 'px-3.5 py-2 rounded-lg text-slate-600 hover:text-indigo-600 transition';
        }
    });

    document.querySelectorAll('.review-item').forEach(el => {
        const status = el.getAttribute('data-status');
        el.style.display = (type === 'all' || status === type) ? 'block' : 'none';
    });
}
</script>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
