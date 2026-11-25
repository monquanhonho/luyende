<?php
require_once __DIR__ . '/config/db.php';

if (isLoggedIn()) {
    header('Location: index.php');
    exit;
}

$error = '';

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $fullname = trim($_POST['fullname'] ?? '');
    $username = trim($_POST['username'] ?? '');
    $class_name = 'Học sinh';
    $email = trim($_POST['email'] ?? '');
    $password = trim($_POST['password'] ?? '');
    $confirm_password = trim($_POST['confirm_password'] ?? '');

    if ($fullname === '' || $username === '' || $password === '') {
        $error = 'Vui lòng điền đầy đủ Họ tên, Tên đăng nhập và Mật khẩu!';
    } elseif (strlen($username) < 3) {
        $error = 'Tên đăng nhập phải có ít nhất 3 ký tự!';
    } elseif ($password !== $confirm_password) {
        $error = 'Mật khẩu xác nhận không khớp!';
    } else {
        $stmt = $pdo->prepare('SELECT id FROM users WHERE username = ? LIMIT 1');
        $stmt->execute([$username]);
        if ($stmt->fetch()) {
            $error = 'Tên đăng nhập này đã được sử dụng, vui lòng chọn tên khác!';
        } else {
            $hashed = password_hash($password, PASSWORD_DEFAULT);
            $insert = $pdo->prepare('INSERT INTO users (username, password, fullname, email, class_name, role) VALUES (?, ?, ?, ?, ?, "student")');
            $insert->execute([$username, $hashed, $fullname, $email, $class_name]);
            $newId = (int)$pdo->lastInsertId();

            $_SESSION['user'] = [
                'id' => $newId,
                'username' => $username,
                'fullname' => $fullname,
                'email' => $email,
                'class_name' => $class_name,
                'role' => 'student',
            ];
            $_SESSION['flash_success'] = 'Đăng ký tài khoản học sinh thành công! Chúc em ôn tập hiệu quả.';
            header('Location: index.php');
            exit;
        }
    }
}

$pageTitle = 'Đăng ký tài khoản Học sinh';
require_once __DIR__ . '/includes/header.php';
?>

<div class="max-w-xl mx-auto px-4 sm:px-6 lg:px-8 py-10">
    <div class="bg-white rounded-3xl shadow-xl shadow-slate-200/60 border border-slate-100 p-8 sm:p-10">
        <div class="text-center mb-6">
            <div class="w-12 h-12 rounded-2xl bg-indigo-100 text-indigo-600 flex items-center justify-center mx-auto text-xl mb-3">
                <i class="fa-solid fa-user-graduate"></i>
            </div>
            <h1 class="text-2xl font-extrabold text-slate-800">Tạo tài khoản Học sinh</h1>
            <p class="text-sm text-slate-500 mt-1">Lưu lịch sử điểm số và luyện đề không giới hạn 4 môn Toán - Anh - Lý - Hóa</p>
        </div>

        <?php if ($error): ?>
            <div class="mb-5 p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-700 text-sm font-medium flex items-center gap-3">
                <i class="fa-solid fa-circle-exclamation text-rose-600"></i>
                <span><?= htmlspecialchars($error) ?></span>
            </div>
        <?php endif; ?>

        <form method="POST" action="register.php" class="space-y-4">
            <div>
                <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">Họ và tên học sinh *</label>
                <input type="text" name="fullname" required
                       value="<?= htmlspecialchars($_POST['fullname'] ?? '') ?>"
                       placeholder="Nhập họ và tên..."
                       class="w-full px-4 py-2.5 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 outline-none text-sm font-medium">
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">Tên đăng nhập *</label>
                    <input type="text" name="username" required
                           value="<?= htmlspecialchars($_POST['username'] ?? '') ?>"
                           placeholder="Nhập tên đăng nhập..."
                           class="w-full px-4 py-2.5 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 outline-none text-sm font-medium">
                </div>
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">Email (Tùy chọn)</label>
                    <input type="email" name="email"
                           value="<?= htmlspecialchars($_POST['email'] ?? '') ?>"
                           placeholder="Nhập email..."
                           class="w-full px-4 py-2.5 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 outline-none text-sm font-medium">
                </div>
            </div>

            <div class="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">Mật khẩu *</label>
                    <input type="password" name="password" required
                           placeholder="Nhập mật khẩu"
                           class="w-full px-4 py-2.5 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 outline-none text-sm font-medium">
                </div>
                <div>
                    <label class="block text-xs font-bold uppercase tracking-wider text-slate-600 mb-1.5">Nhập lại mật khẩu *</label>
                    <input type="password" name="confirm_password" required
                           placeholder="Xác nhận mật khẩu"
                           class="w-full px-4 py-2.5 rounded-xl border border-slate-200 focus:border-indigo-500 focus:ring-4 focus:ring-indigo-500/10 outline-none text-sm font-medium">
                </div>
            </div>

            <button type="submit" class="w-full mt-2 py-3.5 px-6 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-lg shadow-indigo-500/25 transition">
                <i class="fa-solid fa-check-circle mr-1"></i> Hoàn tất đăng ký Học sinh
            </button>
        </form>

        <div class="mt-6 pt-5 border-t border-slate-100 text-center text-sm text-slate-500">
            Đã có tài khoản?
            <a href="login.php" class="font-bold text-indigo-600 hover:text-indigo-700 ml-1">Đăng nhập tại đây</a>
        </div>
    </div>
</div>

<?php require_once __DIR__ . '/includes/footer.php'; ?>
