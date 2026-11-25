<?php
require_once __DIR__ . '/../config/db.php';
$user = currentUser();
$currentPage = basename($_SERVER['PHP_SELF']);
?>
<!DOCTYPE html>
<html lang="vi">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title><?= isset($pageTitle) ? htmlspecialchars($pageTitle) . ' | EduSmart Luyện Đề' : 'EduSmart - Hệ Thống Luyện Đề Toán Anh Lý Hóa' ?></title>
    <!-- Tailwind CSS CDN -->
    <script src="https://cdn.tailwindcss.com"></script>
    <!-- Google Fonts: Plus Jakarta Sans / Be Vietnam Pro -->
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Be+Vietnam+Pro:ital,wght@0,400;0,500;0,600;0,700;0,800;1,400&display=swap" rel="stylesheet">
    <!-- Font Awesome 6 -->
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css">
    <!-- Custom CSS & JS (tách riêng 1 file CSS + 1 file JS) -->
    <link rel="stylesheet" href="assets/css/style.css">
    <script src="assets/js/main.js"></script>
</head>
<body class="min-h-screen flex flex-col text-slate-800">

    <!-- Thanh điều hướng chính -->
    <header class="sticky top-0 z-50 glass-nav border-b border-slate-200/80 shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
                <!-- Logo -->
                <a href="index.php" class="flex items-center gap-3 group">
                    <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-600 to-blue-600 flex items-center justify-center text-white shadow-md shadow-indigo-500/20 group-hover:scale-105 transition">
                        <i class="fa-solid fa-graduation-cap text-lg"></i>
                    </div>
                    <div>
                        <span class="text-xl font-extrabold bg-gradient-to-r from-indigo-700 via-blue-600 to-teal-500 bg-clip-text text-transparent">EduSmart</span>
                        <span class="block text-[11px] font-medium text-slate-400 -mt-1">Luyện Đề Toán • Anh • Lý • Hóa</span>
                    </div>
                </a>

                <!-- Menu chính -->
                <nav class="hidden md:flex items-center gap-1">
                    <a href="index.html" class="px-4 py-2 rounded-xl text-sm font-semibold transition flex items-center gap-2 <?= (in_array($currentPage, ['index.php', 'index.html'], true) && empty($_GET['subject'])) ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' ?>">
                        <i class="fa-solid fa-compass"></i> Kho Đề Thi
                    </a>
                    <a href="index.php?subject=TOAN" class="px-3.5 py-2 rounded-xl text-sm font-semibold transition flex items-center gap-1.5 <?= (($_GET['subject'] ?? '') === 'TOAN') ? 'bg-blue-50 text-blue-700' : 'text-slate-600 hover:bg-slate-100' ?>">
                        <span class="w-2 h-2 rounded-full bg-blue-600"></span> Toán
                    </a>
                    <a href="index.php?subject=ANH" class="px-3.5 py-2 rounded-xl text-sm font-semibold transition flex items-center gap-1.5 <?= (($_GET['subject'] ?? '') === 'ANH') ? 'bg-emerald-50 text-emerald-700' : 'text-slate-600 hover:bg-slate-100' ?>">
                        <span class="w-2 h-2 rounded-full bg-emerald-500"></span> Tiếng Anh
                    </a>
                    <a href="index.php?subject=LY" class="px-3.5 py-2 rounded-xl text-sm font-semibold transition flex items-center gap-1.5 <?= (($_GET['subject'] ?? '') === 'LY') ? 'bg-amber-50 text-amber-700' : 'text-slate-600 hover:bg-slate-100' ?>">
                        <span class="w-2 h-2 rounded-full bg-amber-500"></span> Vật Lý
                    </a>
                    <a href="index.php?subject=HOA" class="px-3.5 py-2 rounded-xl text-sm font-semibold transition flex items-center gap-1.5 <?= (($_GET['subject'] ?? '') === 'HOA') ? 'bg-rose-50 text-rose-700' : 'text-slate-600 hover:bg-slate-100' ?>">
                        <span class="w-2 h-2 rounded-full bg-rose-500"></span> Hóa Học
                    </a>

                    <?php if (isLoggedIn()): ?>
                        <a href="history.php" class="px-4 py-2 rounded-xl text-sm font-semibold transition flex items-center gap-2 <?= ($currentPage === 'history.php') ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-100' ?>">
                            <i class="fa-solid fa-chart-line"></i> Kết Quả Của Tôi
                        </a>
                    <?php endif; ?>

                    <?php if (isAdmin()): ?>
                        <a href="admin.php" class="ml-1 px-4 py-2 rounded-xl text-sm font-bold transition flex items-center gap-2 <?= ($currentPage === 'admin.php') ? 'bg-amber-500 text-white shadow-sm' : 'bg-amber-50 text-amber-700 border border-amber-200 hover:bg-amber-100' ?>">
                            <i class="fa-solid fa-user-shield"></i> Quản Trị Admin
                        </a>
                    <?php endif; ?>
                </nav>

                <!-- Thông tin tài khoản -->
                <div class="flex items-center gap-3">
                    <?php if ($user): ?>
                        <div class="flex items-center gap-3 pl-2 pr-3 py-1.5 rounded-2xl bg-slate-100/80 border border-slate-200/70">
                            <div class="w-8 h-8 rounded-xl flex items-center justify-center font-bold text-sm <?= $user['role'] === 'admin' ? 'bg-amber-500 text-white' : 'bg-indigo-600 text-white' ?>">
                                <?= mb_strtoupper(mb_substr($user['fullname'], 0, 1)) ?>
                            </div>
                            <div class="hidden sm:block text-left">
                                <div class="text-xs font-bold text-slate-800 leading-tight flex items-center gap-1.5">
                                    <?= htmlspecialchars($user['fullname']) ?>
                                    <?php if ($user['role'] === 'admin'): ?>
                                        <span class="px-1.5 py-0.5 text-[10px] rounded-md bg-amber-100 text-amber-800 font-extrabold">ADMIN</span>
                                    <?php else: ?>
                                        <span class="px-1.5 py-0.5 text-[10px] rounded-md bg-indigo-100 text-indigo-700 font-bold">HỌC SINH</span>
                                    <?php endif; ?>
                                </div>
                                <div class="text-[11px] text-slate-500"><?= htmlspecialchars($user['class_name'] ?? 'Thành viên') ?></div>
                            </div>
                        </div>
                        <a href="logout.php" title="Đăng xuất" class="p-2.5 rounded-xl text-slate-500 hover:text-rose-600 hover:bg-rose-50 transition">
                            <i class="fa-solid fa-right-from-bracket"></i>
                        </a>
                    <?php else: ?>
                        <a href="login.php" class="px-4 py-2 rounded-xl text-sm font-semibold text-slate-700 hover:bg-slate-100 transition">
                            Đăng nhập
                        </a>
                        <a href="register.php" class="px-4 py-2 rounded-xl text-sm font-bold bg-indigo-600 text-white hover:bg-indigo-700 shadow-sm shadow-indigo-500/20 transition">
                            Đăng ký Học sinh
                        </a>
                    <?php endif; ?>
                </div>
            </div>
        </div>
    </header>

    <!-- Thông báo Flash Message -->
    <?php if (!empty($_SESSION['flash_success']) || !empty($_SESSION['flash_error'])): ?>
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4 w-full">
            <?php if (!empty($_SESSION['flash_success'])): ?>
                <div class="flex items-center justify-between p-4 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-sm font-medium shadow-sm">
                    <div class="flex items-center gap-3">
                        <i class="fa-solid fa-circle-check text-emerald-600 text-lg"></i>
                        <span><?= htmlspecialchars($_SESSION['flash_success']) ?></span>
                    </div>
                    <button onclick="this.parentElement.remove()" class="text-emerald-500 hover:text-emerald-700"><i class="fa-solid fa-xmark"></i></button>
                </div>
                <?php unset($_SESSION['flash_success']); ?>
            <?php endif; ?>

            <?php if (!empty($_SESSION['flash_error'])): ?>
                <div class="flex items-center justify-between p-4 rounded-2xl bg-rose-50 border border-rose-200 text-rose-800 text-sm font-medium shadow-sm">
                    <div class="flex items-center gap-3">
                        <i class="fa-solid fa-triangle-exclamation text-rose-600 text-lg"></i>
                        <span><?= htmlspecialchars($_SESSION['flash_error']) ?></span>
                    </div>
                    <button onclick="this.parentElement.remove()" class="text-rose-500 hover:text-rose-700"><i class="fa-solid fa-xmark"></i></button>
                </div>
                <?php unset($_SESSION['flash_error']); ?>
            <?php endif; ?>
        </div>
    <?php endif; ?>

    <!-- Nội dung chính -->
    <main class="flex-1">
