<?php
require_once __DIR__ . '/config/db.php';
requireLogin();

$uid = currentUser()['id'];

// Thống kê điểm trung bình theo từng môn của học sinh
$subjectStatsStmt = $pdo->prepare("
    SELECT s.code, s.name, s.icon, s.gradient,
           COUNT(ea.id) AS attempts_count,
           COALESCE(AVG(ea.score), 0) AS avg_score,
           COALESCE(MAX(ea.score), 0) AS max_score
    FROM subjects s
    LEFT JOIN exams e ON e.subject_id = s.id
    LEFT JOIN exam_attempts ea ON ea.exam_id = e.id AND ea.user_id = ?
    GROUP BY s.id
    ORDER BY s.id ASC
");
$subjectStatsStmt->execute([$uid]);
$subjectStats = $subjectStatsStmt->fetchAll();

// Danh sách lịch sử các lần thi của học sinh
$historyStmt = $pdo->prepare("
    SELECT ea.*, e.title AS exam_title, e.level AS exam_level,
           s.code AS subject_code, s.name AS subject_name
    FROM exam_attempts ea
    JOIN exams e ON ea.exam_id = e.id
    JOIN subjects s ON e.subject_id = s.id
    WHERE ea.user_id = ?
    ORDER BY ea.completed_at DESC
");
$historyStmt->execute([$uid]);
$attempts = $historyStmt->fetchAll();

$pageTitle = 'Kết quả & Lịch sử luyện đề của tôi';
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
            <h1 class="text-2xl font-extrabold text-slate-900">Bảng Vàng Thành Tích Cá Nhân</h1>
            <p class="text-sm text-slate-500 mt-0.5">Theo dõi sự tiến bộ qua từng môn Toán • Tiếng Anh • Vật Lý • Hóa Học</p>
        </div>
        <a href="index.php" class="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold shadow-sm transition self-start sm:self-center">
            <i class="fa-solid fa-plus mr-1"></i> Luyện đề mới
        </a>
    </div>

    <!-- Thống kê theo 4 môn -->
    <div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <?php foreach ($subjectStats as $st): ?>
            <div class="bg-white rounded-3xl border border-slate-200/80 p-5 shadow-sm">
                <div class="flex items-center justify-between mb-3">
                    <div class="w-11 h-11 rounded-2xl bg-gradient-to-br <?= htmlspecialchars($st['gradient']) ?> text-white flex items-center justify-center text-lg shadow-sm">
                        <i class="fa-solid <?= htmlspecialchars($st['icon']) ?>"></i>
                    </div>
                    <span class="px-2.5 py-1 rounded-xl text-xs font-bold bg-slate-100 text-slate-600">
                        <?= (int)$st['attempts_count'] ?> lần làm
                    </span>
                </div>
                <h3 class="font-extrabold text-slate-800 text-base">Môn <?= htmlspecialchars($st['name']) ?></h3>
                <div class="mt-3 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                    <div>
                        <span class="text-slate-400 block">Điểm TB</span>
                        <span class="text-base font-extrabold text-slate-800"><?= number_format((float)$st['avg_score'], 1) ?></span>
                    </div>
                    <div class="text-right">
                        <span class="text-slate-400 block">Cao nhất</span>
                        <span class="text-base font-extrabold text-emerald-600"><?= number_format((float)$st['max_score'], 1) ?> / 10</span>
                    </div>
                </div>
            </div>
        <?php endforeach; ?>
    </div>

    <!-- Bảng lịch sử chi tiết -->
    <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
        <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between">
            <h2 class="font-extrabold text-slate-800 text-base">Nhật ký các đề đã hoàn thành (<?= count($attempts) ?> lượt)</h2>
        </div>

        <?php if (empty($attempts)): ?>
            <div class="p-12 text-center">
                <p class="text-sm text-slate-500">Bạn chưa hoàn thành bài thi nào. Hãy chọn một đề để bắt đầu nhé!</p>
                <a href="index.php" class="inline-block mt-4 px-5 py-2.5 rounded-xl bg-indigo-600 text-white text-xs font-bold">Khám phá kho đề</a>
            </div>
        <?php else: ?>
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-slate-50 text-[11px] font-extrabold uppercase tracking-wider text-slate-500 border-b border-slate-200/70">
                            <th class="py-3.5 px-6">Môn học</th>
                            <th class="py-3.5 px-4">Tên đề luyện tập</th>
                            <th class="py-3.5 px-4 text-center">Số câu đúng</th>
                            <th class="py-3.5 px-4 text-center">Điểm số</th>
                            <th class="py-3.5 px-4">Thời gian làm</th>
                            <th class="py-3.5 px-4">Ngày nộp</th>
                            <th class="py-3.5 px-6 text-right">Thao tác</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 text-sm">
                        <?php foreach ($attempts as $row):
                            $style = getSubjectBadgeStyle($row['subject_code']);
                        ?>
                            <tr class="hover:bg-slate-50/80 transition">
                                <td class="py-4 px-6">
                                    <span class="px-3 py-1 rounded-xl text-xs font-extrabold <?= $style['badge'] ?>">
                                        <?= htmlspecialchars($row['subject_name']) ?>
                                    </span>
                                </td>
                                <td class="py-4 px-4">
                                    <div class="font-bold text-slate-800"><?= htmlspecialchars($row['exam_title']) ?></div>
                                    <div class="text-xs text-slate-400"><?= htmlspecialchars($row['exam_level']) ?></div>
                                </td>
                                <td class="py-4 px-4 text-center font-bold text-slate-700">
                                    <?= (int)$row['correct_count'] ?> / <?= (int)$row['total_questions'] ?>
                                </td>
                                <td class="py-4 px-4 text-center">
                                    <span class="px-3 py-1 rounded-xl font-extrabold text-xs <?= (float)$row['score'] >= 8 ? 'bg-emerald-100 text-emerald-800' : ((float)$row['score'] >= 5 ? 'bg-blue-100 text-blue-800' : 'bg-rose-100 text-rose-800') ?>">
                                        <?= number_format((float)$row['score'], 1) ?> đ
                                    </span>
                                </td>
                                <td class="py-4 px-4 text-xs font-medium text-slate-500">
                                    <?= formatDuration((int)$row['time_spent_seconds']) ?>
                                </td>
                                <td class="py-4 px-4 text-xs text-slate-500">
                                    <?= date('H:i - d/m/Y', strtotime($row['completed_at'])) ?>
                                </td>
                                <td class="py-4 px-6 text-right">
                                    <a href="result.php?attempt_id=<?= (int)$row['id'] ?>" class="px-3.5 py-1.5 rounded-xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold text-xs transition">
                                        Xem giải chi tiết
                                    </a>
                                </td>
                            </tr>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            </div>
        <?php endif; ?>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
