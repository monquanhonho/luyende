<?php
require_once __DIR__ . '/config/db.php';

if (isLoggedIn()) {
    header('Location: index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $username = trim($_POST['username'] ?? '');
    $password = trim($_POST['password'] ?? '');

    if ($username === '' || $password === '') {
        $error = 'Vui lòng nhập đầy đủ Tên đăng nhập và Mật khẩu!';
    } else {
        $stmt = $pdo->prepare('SELECT * FROM users WHERE username = ? LIMIT 1');
        $stmt->execute([$username]);
        $foundUser = $stmt->fetch();

        if ($foundUser) {
            // Hỗ trợ cả mật khẩu mặc định '123456' cho tài khoản mẫu, hoặc password_verify chuẩn
            $validPassword = password_verify($password, $foundUser['password'])
                || ($password === '123456' && in_array($foundUser['username'], ['admin', 'hocsinh', 'linhchi'], true))
                || ($password === $foundUser['password']);

            if ($validPassword) {
                $_SESSION['user'] = [
                    'id' => (int)$foundUser['id'],
                    'username' => $foundUser['username'],
                    'fullname' => $foundUser['fullname'],
                    'email' => $foundUser['email'],
                    'class_name' => $foundUser['class_name'],
                    'role' => $foundUser['role'],
                ];
                $_SESSION['flash_success'] = 'Chào mừng ' . $foundUser['fullname'] . ' đã quay trở lại!';
                if ($foundUser['role'] === 'admin') {
                    header('Location: admin.php');
                } else {
                    header('Location: index.php');
                }
                exit;
            }
        }
        $error = 'Tên đăng nhập hoặc mật khẩu không chính xác!';
    }
}

$pageTitle = 'Đăng nhập hệ thống';
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-5xl mx-auto px-4 sm:px-6 lg:px-8 py-12">
    <div class="grid grid-cols-1 lg:grid-cols-12 bg-white rounded-3xl shadow-xl shadow-slate-200/60 border border-slate-100 overflow-hidden">
        <!-- Cột trái: Giới thiệu & Chọn nhanh tài khoản Demo -->
        <div class="lg:col-span-6 bg-gradient-to-br from-indigo-600 via-blue-600 to-teal-500 p-8 sm:p-10 text-white flex flex-col justify-between">
            <div>
                <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-white/15 backdrop-blur-sm text-xs font-semibold tracking-wide uppercase">
                    <i class="fa-solid fa-sparkles"></i> Hệ thống phân quyền rõ ràng
                </span>
                <h1 class="text-2xl sm:text-3xl font-extrabold mt-4 leading-tight">
                    Chinh phục điểm 9+ các môn Toán • Anh • Lý • Hóa
                </h1>
                <p class="text-indigo-100 text-sm mt-3 leading-relaxed">
                    Giao diện làm bài trực quan, đồng hồ đếm ngược thông minh, chấm điểm tự động và giải thích chi tiết từng câu hỏi ngay sau khi nộp bài.
                </p>
            </div>

            <!-- Điểm nổi bật của hệ thống -->
            <div class="mt-8 space-y-3">
                <div class="flex items-center gap-3 text-xs sm:text-sm text-indigo-50 bg-white/10 px-4 py-3 rounded-xl border border-white/15">
                    <i class="fa-solid fa-check-circle text-teal-300 text-base"></i>
                    <span>Đề thi chuẩn cấu trúc THPT Quốc Gia (Toán, Anh, Lý, Hóa)</span>
                </div>
                <div class="flex items-center gap-3 text-xs sm:text-sm text-indigo-50 bg-white/10 px-4 py-3 rounded-xl border border-white/15">
                    <i class="fa-solid fa-stopwatch text-amber-300 text-base"></i>
                    <span>Bấm giờ tự động, chấm điểm &amp; xem lời giải chi tiết</span>
                </div>
            </div>
        </div>

        <!-- Cột phải: Form đăng nhập -->
        <div class="lg:col-span-6 p-8 sm:p-10 flex flex-col justify-center">
            <div class="mb-6">
                <h2 class="text-2xl font-extrabold text-slate-800">Đăng nhập tài khoản</h2>
                <p class="text-sm text-slate-500 mt-1">Đăng nhập bằng tài khoản Học sinh hoặc Quản trị viên của bạn</p>
            </div>

            <?php if ($error): ?>
                <div class="mb-5 p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 text-sm font-medium flex items-center gap-3">
                    <i class="fa-solid fa-circle-exclamation text-rose-600"></i>
                    <span><?= htmlspecialchars($error) ?></span>
                </div>
            <?php endif; ?>

            <form method="POST" action="login.php" class="space-y-5" id="loginForm">
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-2">Tên đăng nhập</label>
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 pl-4 flex items-center text-slate-400">
                            <i class="fa-solid fa-user"></i>
                        </span>
                        <input type="text" name="username" id="usernameInput" required
                               value="<?= htmlspecialchars($_POST['username'] ?? '') ?>"
                               placeholder="Nhập tên đăng nhập..."
                               class="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 outline-none text-sm font-medium transition">
                    </div>
                </div>

                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-2">Mật khẩu</label>
                    <div class="relative">
                        <span class="absolute inset-y-0 left-0 pl-4 flex items-center text-slate-400">
                            <i class="fa-solid fa-lock"></i>
                        </span>
                        <input type="password" name="password" id="passwordInput" required
                               placeholder="Nhập mật khẩu..."
                               class="w-full pl-11 pr-4 py-3 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 outline-none text-sm font-medium transition">
                    </div>
                </div>

                <button type="submit" class="w-full py-3.5 px-6 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-lg shadow-indigo-500/25 transition flex items-center justify-center gap-2">
                    <i class="fa-solid fa-right-to-bracket"></i> Đăng nhập ngay
                </button>
            </form>

            <div class="mt-6 pt-6 border-t border-slate-100 text-center text-sm text-slate-500">
                Bạn là học sinh mới chưa có tài khoản?
                <a href="register.php" class="font-bold text-indigo-600 hover:text-indigo-700 ml-1">Đăng ký miễn phí &rarr;</a>
            </div>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
