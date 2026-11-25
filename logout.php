<?php
require_once __DIR__ . '/config/db.php';
unset($_SESSION['user']);
$_SESSION['flash_success'] = 'Đã đăng xuất khỏi hệ thống thành công!';
header('Location: login.php');
exit;
