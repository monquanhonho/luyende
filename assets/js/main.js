/* ==========================================================
   EDUSMART LUYỆN ĐỀ 2026 - GITHUB PAGES + SUPABASE EDITION
   ========================================================== */

// BƯỚC CẤU HÌNH: Dán Project URL và anon public key từ Supabase -> Project Settings -> API
const SUPABASE_URL = 'https://mxpgyhwvjubddiuzwpgc.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_mEn7avraHGAKeGKJ3Ek5Pw_RJXgRXi3';

if (typeof tailwind !== 'undefined') {
    tailwind.config = {
        theme: {
            extend: {
                fontFamily: {
                    sans: ['"Be Vietnam Pro"', 'sans-serif'],
                }
            }
        }
    };
}

let sb = null;
function isSupabaseConfigured() {
    return SUPABASE_URL.startsWith('http') && SUPABASE_ANON_KEY.length > 20;
}
function getSb() {
    if (!sb && isSupabaseConfigured() && window.supabase) {
        sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
    }
    return sb;
}

// ==========================================================
// TIỆN ÍCH CHUNG & AUTH
// ==========================================================
function esc(str) {
    if (str === null || str === undefined) return '';
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;')
        .replace(/'/g, '&#039;');
}

function getQueryParam(name) {
    return new URLSearchParams(window.location.search).get(name) || '';
}

async function sha256(text) {
    const data = new TextEncoder().encode(text);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    return Array.from(new Uint8Array(hashBuffer)).map(b => b.toString(16).padStart(2, '0')).join('');
}

function getCurrentUser() {
    try {
        const raw = localStorage.getItem('edusmart_user');
        return raw ? JSON.parse(raw) : null;
    } catch {
        return null;
    }
}

function setCurrentUser(user) {
    if (user) localStorage.setItem('edusmart_user', JSON.stringify(user));
    else localStorage.removeItem('edusmart_user');
}

function logoutUser() {
    setCurrentUser(null);
    setFlash('success', 'Bạn đã đăng xuất khỏi hệ thống.');
    window.location.href = 'login.html';
}

function setFlash(type, message) {
    sessionStorage.setItem('edusmart_flash', JSON.stringify({ type, message }));
}

function consumeFlash() {
    try {
        const raw = sessionStorage.getItem('edusmart_flash');
        sessionStorage.removeItem('edusmart_flash');
        return raw ? JSON.parse(raw) : null;
    } catch {
        return null;
    }
}

function getSubjectBadgeStyle(code) {
    const map = {
        TOAN: { bg: 'bg-blue-50', text: 'text-blue-700', border: 'border-blue-200', badge: 'bg-blue-100 text-blue-800', btn: 'bg-blue-600 hover:bg-blue-700', gradient: 'from-blue-600 to-indigo-600', soft_icon: 'bg-blue-100 text-blue-600' },
        ANH: { bg: 'bg-emerald-50', text: 'text-emerald-700', border: 'border-emerald-200', badge: 'bg-emerald-100 text-emerald-800', btn: 'bg-emerald-600 hover:bg-emerald-700', gradient: 'from-emerald-500 to-teal-600', soft_icon: 'bg-emerald-100 text-emerald-600' },
        LY: { bg: 'bg-amber-50', text: 'text-amber-700', border: 'border-amber-200', badge: 'bg-amber-100 text-amber-800', btn: 'bg-amber-500 hover:bg-amber-600', gradient: 'from-amber-500 to-orange-600', soft_icon: 'bg-amber-100 text-amber-600' },
        HOA: { bg: 'bg-rose-50', text: 'text-rose-700', border: 'border-rose-200', badge: 'bg-rose-100 text-rose-800', btn: 'bg-rose-600 hover:bg-rose-700', gradient: 'from-rose-500 to-pink-600', soft_icon: 'bg-rose-100 text-rose-600' }
    };
    return map[code] || map.TOAN;
}

function getDifficultyBadgeStyle(diff) {
    const map = {
        'Nhận biết': 'bg-emerald-50 text-emerald-700 border-emerald-200',
        'Thông hiểu': 'bg-sky-50 text-sky-700 border-sky-200',
        'Vận dụng': 'bg-amber-50 text-amber-700 border-amber-200',
        'Vận dụng cao': 'bg-rose-50 text-rose-700 border-rose-200'
    };
    return map[diff] || 'bg-slate-50 text-slate-700 border-slate-200';
}

function getQuestionTypeInfo(type) {
    if (type === 'true_false') {
        return { part: 'Phần II', label: 'Đúng / Sai (4 ý)', short: 'Đ/S', badge: 'bg-violet-50 text-violet-700 border-violet-200', desc: 'Thang điểm lũy tiến: Đúng 1 ý được 0.10đ • 2 ý: 0.25đ • 3 ý: 0.50đ • cả 4 ý: 1.00đ.' };
    }
    if (type === 'short_answer') {
        return { part: 'Phần III', label: 'Trả lời ngắn', short: 'TLN', badge: 'bg-teal-50 text-teal-700 border-teal-200', desc: 'Điền giá trị số chính xác (chấp nhận dấu chấm hoặc phẩy thập phân).' };
    }
    return { part: 'Phần I', label: 'Trắc nghiệm 4 lựa chọn', short: 'TN', badge: 'bg-blue-50 text-blue-700 border-blue-200', desc: 'Chọn 1 phương án đúng nhất trong 4 lựa chọn A, B, C, D.' };
}

function gradeQuestion(q, rawAnswer) {
    const type = q.question_type || 'mcq';
    const maxPoints = parseFloat(q.points_value || 0.25);

    if (type === 'true_false') {
        const expectedParts = String(q.correct_option || '').toUpperCase().split(',').map(s => s.trim());
        const selectedObj = (rawAnswer && typeof rawAnswer === 'object') ? rawAnswer : {};
        const userParts = [];
        let correctItems = 0;

        ['a', 'b', 'c', 'd'].forEach((k, idx) => {
            let val = (selectedObj[k] || '').toString().trim().toUpperCase();
            if (val !== 'D' && val !== 'S') val = '';
            userParts.push(val);
            if (val && expectedParts[idx] && val === expectedParts[idx]) {
                correctItems++;
            }
        });

        const scoreTable = { 0: 0.00, 1: 0.10, 2: 0.25, 3: 0.50, 4: 1.00 };
        const earned = scoreTable[correctItems] ?? 0.00;
        const joined = userParts.join(',');
        return {
            selected_option: joined === ',,,' ? null : joined,
            is_correct: correctItems === 4 ? 1 : 0,
            earned_points: earned,
            correct_items: correctItems
        };
    }

    if (type === 'short_answer') {
        const rawStr = typeof rawAnswer === 'string' ? rawAnswer.trim() : '';
        if (!rawStr) {
            return { selected_option: null, is_correct: 0, earned_points: 0.00, correct_items: 0 };
        }
        const normUser = rawStr.replace(/,/g, '.').replace(/\s+/g, '');
        const normExp = String(q.correct_option || '').trim().replace(/,/g, '.').replace(/\s+/g, '');
        let isRight = normUser.toLowerCase() === normExp.toLowerCase();
        if (!isRight && !isNaN(normUser) && !isNaN(normExp)) {
            isRight = Math.abs(parseFloat(normUser) - parseFloat(normExp)) < 0.0001;
        }
        return {
            selected_option: rawStr,
            is_correct: isRight ? 1 : 0,
            earned_points: isRight ? maxPoints : 0.00,
            correct_items: isRight ? 1 : 0
        };
    }

    let sel = typeof rawAnswer === 'string' ? rawAnswer.trim().toUpperCase() : '';
    if (!['A', 'B', 'C', 'D'].includes(sel)) sel = '';
    const isRight = sel !== '' && sel === String(q.correct_option || '').toUpperCase();
    return {
        selected_option: sel || null,
        is_correct: isRight ? 1 : 0,
        earned_points: isRight ? maxPoints : 0.00,
        correct_items: isRight ? 1 : 0
    };
}

function formatDateTimeVN(isoStr) {
    if (!isoStr) return '—';
    const d = new Date(isoStr);
    return d.toLocaleString('vi-VN', { hour: '2-digit', minute: '2-digit', day: '2-digit', month: '2-digit', year: 'numeric' });
}

// ==========================================================
// HEADER, FOOTER & FLASH RENDERER
// ==========================================================
function renderHeader() {
    const el = document.getElementById('appHeader');
    if (!el) return;
    const user = getCurrentUser();
    const page = document.body.getAttribute('data-page') || 'index';
    const subParam = getQueryParam('subject');

    const navLink = (href, active, html) =>
        `<a href="${href}" class="px-3.5 py-2 rounded-xl text-sm font-semibold transition flex items-center gap-1.5 ${active ? 'bg-indigo-50 text-indigo-700' : 'text-slate-600 hover:bg-slate-100'}">${html}</a>`;

    el.innerHTML = `
    <header class="sticky top-0 z-50 glass-nav border-b border-slate-200/80 shadow-sm">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
            <div class="flex items-center justify-between h-16">
                <a href="index.html" class="flex items-center gap-3 group">
                    <div class="w-10 h-10 rounded-xl bg-gradient-to-br from-indigo-600 to-blue-600 flex items-center justify-center text-white shadow-md shadow-indigo-500/20 group-hover:scale-105 transition">
                        <i class="fa-solid fa-graduation-cap text-lg"></i>
                    </div>
                    <div>
                        <span class="text-xl font-extrabold bg-gradient-to-r from-indigo-700 via-blue-600 to-teal-500 bg-clip-text text-transparent">EduSmart</span>
                        <span class="block text-[11px] font-medium text-slate-400 -mt-1">Luyện Đề Toán • Anh • Lý • Hóa</span>
                    </div>
                </a>

                <nav class="hidden md:flex items-center gap-1">
                    ${navLink('index.html', page === 'index' && !subParam, '<i class="fa-solid fa-compass"></i> Kho Đề Thi')}
                    ${navLink('index.html?subject=TOAN', subParam === 'TOAN', '<span class="w-2 h-2 rounded-full bg-blue-600"></span> Toán')}
                    ${navLink('index.html?subject=ANH', subParam === 'ANH', '<span class="w-2 h-2 rounded-full bg-emerald-500"></span> Tiếng Anh')}
                    ${navLink('index.html?subject=LY', subParam === 'LY', '<span class="w-2 h-2 rounded-full bg-amber-500"></span> Vật Lý')}
                    ${navLink('index.html?subject=HOA', subParam === 'HOA', '<span class="w-2 h-2 rounded-full bg-rose-500"></span> Hóa Học')}
                    ${user ? navLink('history.html', page === 'history', '<i class="fa-solid fa-chart-line"></i> Kết Quả Của Tôi') : ''}
                    ${user && user.role === 'admin' ? `
                        <a href="admin.html" class="ml-1 px-4 py-2 rounded-xl text-sm font-bold transition flex items-center gap-2 ${page === 'admin' ? 'bg-amber-500 text-white shadow-sm' : 'bg-amber-50 text-amber-700 border border-amber-200 hover:bg-amber-100'}">
                            <i class="fa-solid fa-user-shield"></i> Quản Trị Admin
                        </a>` : ''}
                </nav>

                <div class="flex items-center gap-3">
                    ${user ? `
                        <div class="flex items-center gap-3 pl-2 pr-3 py-1.5 rounded-2xl bg-slate-100/80 border border-slate-200/70">
                            <div class="w-8 h-8 rounded-xl flex items-center justify-center font-bold text-sm ${user.role === 'admin' ? 'bg-amber-500 text-white' : 'bg-indigo-600 text-white'}">
                                ${esc((user.fullname || 'U').charAt(0).toUpperCase())}
                            </div>
                            <div class="hidden sm:block text-left">
                                <div class="text-xs font-bold text-slate-800 leading-tight flex items-center gap-1.5">
                                    ${esc(user.fullname)}
                                    ${user.role === 'admin'
                                        ? '<span class="px-1.5 py-0.5 text-[10px] rounded-md bg-amber-100 text-amber-800 font-extrabold">ADMIN</span>'
                                        : '<span class="px-1.5 py-0.5 text-[10px] rounded-md bg-indigo-100 text-indigo-700 font-bold">HỌC SINH</span>'}
                                </div>
                                <div class="text-[11px] text-slate-500">${esc(user.class_name || 'Học sinh')}</div>
                            </div>
                        </div>
                        <button onclick="logoutUser()" title="Đăng xuất" class="p-2.5 rounded-xl text-slate-500 hover:text-rose-600 hover:bg-rose-50 transition">
                            <i class="fa-solid fa-right-from-bracket"></i>
                        </button>
                    ` : `
                        <a href="login.html" class="px-4 py-2 rounded-xl text-sm font-semibold text-slate-700 hover:bg-slate-100 transition">Đăng nhập</a>
                        <a href="register.html" class="px-4 py-2 rounded-xl text-sm font-bold bg-indigo-600 text-white hover:bg-indigo-700 shadow-sm shadow-indigo-500/20 transition">Đăng ký Học sinh</a>
                    `}
                </div>
            </div>
        </div>
    </header>`;
}

function renderFlash() {
    const el = document.getElementById('appFlash');
    if (!el) return;
    let html = '';

    if (!isSupabaseConfigured()) {
        html += `
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4 w-full">
            <div class="p-4 rounded-2xl bg-amber-50 border border-amber-300 text-amber-900 text-xs sm:text-sm font-medium shadow-sm">
                <i class="fa-solid fa-database text-amber-600 mr-2"></i>
                <strong>Chưa kết nối Supabase Database:</strong> Hãy tạo project tại <strong>supabase.com</strong>, chạy file <code>supabase_schema.sql</code> trong SQL Editor, rồi điền <code>SUPABASE_URL</code> và <code>SUPABASE_ANON_KEY</code> vào đầu file <code>assets/js/main.js</code>.
            </div>
        </div>`;
    }

    const flash = consumeFlash();
    if (flash) {
        const isOk = flash.type === 'success';
        html += `
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4 w-full">
            <div class="flex items-center justify-between p-4 rounded-2xl ${isOk ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-rose-50 border-rose-200 text-rose-800'} border text-sm font-medium shadow-sm">
                <div class="flex items-center gap-3">
                    <i class="fa-solid ${isOk ? 'fa-circle-check text-emerald-600' : 'fa-triangle-exclamation text-rose-600'} text-lg"></i>
                    <span>${esc(flash.message)}</span>
                </div>
                <button onclick="this.parentElement.remove()" class="opacity-60 hover:opacity-100"><i class="fa-solid fa-xmark"></i></button>
            </div>
        </div>`;
    }
    el.innerHTML = html;
}

function renderFooter() {
    const el = document.getElementById('appFooter');
    if (!el) return;
    el.innerHTML = `
    <footer class="bg-white border-t border-slate-200/80 mt-16">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
            <div class="flex flex-col md:flex-row items-center justify-between gap-4">
                <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded-lg bg-indigo-600 flex items-center justify-center text-white text-sm">
                        <i class="fa-solid fa-graduation-cap"></i>
                    </div>
                    <div>
                        <span class="font-bold text-slate-800">EduSmart Luyện Đề THPT</span>
                        <p class="text-xs text-slate-500">Nền tảng ôn luyện trắc nghiệm Toán • Tiếng Anh • Vật Lý • Hóa Học</p>
                    </div>
                </div>
                <div class="flex flex-wrap items-center gap-4 text-xs font-medium text-slate-500">
                    <a href="index.html?subject=TOAN" class="hover:text-blue-600">Đề Toán Học</a>
                    <span>•</span>
                    <a href="index.html?subject=ANH" class="hover:text-emerald-600">Đề Tiếng Anh</a>
                    <span>•</span>
                    <a href="index.html?subject=LY" class="hover:text-amber-600">Đề Vật Lý</a>
                    <span>•</span>
                    <a href="index.html?subject=HOA" class="hover:text-rose-600">Đề Hóa Học</a>
                </div>
                <div class="text-xs text-slate-400">
                    &copy; ${new Date().getFullYear()} EduSmart. Thiết kế thân thiện cho Học sinh &amp; Giáo viên.
                </div>
            </div>
        </div>
    </footer>`;
}

// ==========================================================
// TRANG CHỦ (index.html)
// ==========================================================
async function initIndexPage() {
    const client = getSb();
    const user = getCurrentUser();
    const selectedSubject = getQueryParam('subject').trim();
    const searchQuery = getQueryParam('q').trim();
    const selectedLevel = getQueryParam('level').trim();

    document.getElementById('searchInput').value = searchQuery;
    document.getElementById('levelSelect').value = selectedLevel;
    if (searchQuery || selectedLevel || selectedSubject) {
        document.getElementById('clearFilterBtn').classList.remove('hidden');
    }

    document.getElementById('filterForm').addEventListener('submit', e => {
        e.preventDefault();
        const params = new URLSearchParams();
        if (selectedSubject) params.set('subject', selectedSubject);
        const q = document.getElementById('searchInput').value.trim();
        const lvl = document.getElementById('levelSelect').value.trim();
        if (q) params.set('q', q);
        if (lvl) params.set('level', lvl);
        window.location.href = 'index.html' + (params.toString() ? '?' + params.toString() : '');
    });
    document.getElementById('levelSelect').addEventListener('change', () => {
        document.getElementById('filterForm').dispatchEvent(new Event('submit'));
    });

    if (!user) {
        document.getElementById('heroAuthButtons').innerHTML = `
        <div class="mt-6 flex flex-wrap items-center gap-3">
            <a href="login.html" class="px-5 py-3 rounded-xl bg-indigo-500 hover:bg-indigo-600 text-white font-bold text-sm shadow-lg shadow-indigo-500/30 transition flex items-center gap-2">
                <i class="fa-solid fa-play"></i> Đăng nhập làm bài ngay
            </a>
            <a href="register.html" class="px-5 py-3 rounded-xl bg-white/10 hover:bg-white/20 text-white font-bold text-sm border border-white/20 transition flex items-center gap-2">
                <i class="fa-solid fa-user-plus"></i> Đăng ký Học sinh
            </a>
        </div>`;
    }

    if (!client) {
        document.getElementById('examsContainer').innerHTML = '';
        return;
    }

    const [{ data: subjects }, { data: exams }, { data: qMeta }, { data: attempts }] = await Promise.all([
        client.from('subjects').select('*').order('id'),
        client.from('exams').select('*').eq('is_active', 1).order('subject_id').order('id'),
        client.from('questions').select('exam_id, question_type, points_value'),
        client.from('exam_attempts').select('exam_id, user_id, score')
    ]);

    const subList = subjects || [];
    const examList = exams || [];
    const qList = qMeta || [];
    const attList = attempts || [];

    // Đếm câu hỏi & lượt thi
    const qStats = {};
    qList.forEach(q => {
        const eid = q.exam_id;
        if (!qStats[eid]) qStats[eid] = { total: 0, mcq: 0, tf: 0, sa: 0, minPt: 99 };
        qStats[eid].total++;
        if (q.question_type === 'true_false') qStats[eid].tf++;
        else if (q.question_type === 'short_answer') qStats[eid].sa++;
        else qStats[eid].mcq++;
        const pt = parseFloat(q.points_value || 0.25);
        if (pt < qStats[eid].minPt) qStats[eid].minPt = pt;
    });

    const attCountByExam = {};
    const myBestByExam = {};
    let myTotal = 0, mySum = 0, myMax = 0;
    attList.forEach(a => {
        attCountByExam[a.exam_id] = (attCountByExam[a.exam_id] || 0) + 1;
        if (user && Number(a.user_id) === Number(user.id)) {
            myTotal++;
            const sc = parseFloat(a.score || 0);
            mySum += sc;
            if (sc > myMax) myMax = sc;
            if (!myBestByExam[a.exam_id] || sc > myBestByExam[a.exam_id]) {
                myBestByExam[a.exam_id] = sc;
            }
        }
    });

    const examCountBySub = {};
    examList.forEach(e => {
        examCountBySub[e.subject_id] = (examCountBySub[e.subject_id] || 0) + 1;
    });

    // Hero right box
    const heroRight = document.getElementById('heroRightBox');
    if (user) {
        const avg = myTotal > 0 ? (mySum / myTotal).toFixed(1) : '0.0';
        heroRight.innerHTML = `
        <div class="bg-white/10 backdrop-blur-md border border-white/15 rounded-3xl p-6">
            <div class="flex items-center justify-between mb-4">
                <div>
                    <span class="text-xs uppercase tracking-wider text-indigo-200 font-bold">Tiến độ học tập của bạn</span>
                    <h3 class="text-lg font-extrabold text-white">${esc(user.fullname)}</h3>
                </div>
                <a href="history.html" class="text-xs font-bold px-3 py-1.5 rounded-xl bg-white/15 hover:bg-white/25 transition">Xem lịch sử &rarr;</a>
            </div>
            <div class="grid grid-cols-3 gap-3 text-center">
                <div class="bg-slate-900/50 rounded-2xl p-3.5 border border-white/10">
                    <div class="text-2xl font-extrabold text-blue-300">${myTotal}</div>
                    <div class="text-[11px] text-slate-300 mt-0.5">Đề đã luyện</div>
                </div>
                <div class="bg-slate-900/50 rounded-2xl p-3.5 border border-white/10">
                    <div class="text-2xl font-extrabold text-emerald-300">${avg}</div>
                    <div class="text-[11px] text-slate-300 mt-0.5">Điểm TB</div>
                </div>
                <div class="bg-slate-900/50 rounded-2xl p-3.5 border border-white/10">
                    <div class="text-2xl font-extrabold text-amber-300">${myMax.toFixed(1)}</div>
                    <div class="text-[11px] text-slate-300 mt-0.5">Điểm cao nhất</div>
                </div>
            </div>
        </div>`;
    } else {
        heroRight.innerHTML = `<div class="grid grid-cols-2 gap-3">` + subList.map(sub => `
            <a href="index.html?subject=${encodeURIComponent(sub.code)}" class="p-4 rounded-2xl bg-white/10 hover:bg-white/15 border border-white/15 transition flex items-center gap-3.5">
                <div class="w-11 h-11 rounded-xl bg-gradient-to-br ${esc(sub.gradient)} flex items-center justify-center text-white text-lg shadow">
                    <i class="fa-solid ${esc(sub.icon)}"></i>
                </div>
                <div>
                    <div class="font-bold text-sm text-white">${esc(sub.name)}</div>
                    <div class="text-xs text-slate-300">${examCountBySub[sub.id] || 0} đề luyện tập</div>
                </div>
            </a>`).join('') + `</div>`;
    }

    // Cards chọn môn
    const subCards = document.getElementById('subjectCardsGrid');
    subCards.innerHTML = `
        <a href="index.html" class="card-hover p-4 rounded-2xl border transition flex items-center gap-3.5 ${selectedSubject === '' ? 'bg-indigo-600 text-white border-indigo-600 shadow-lg shadow-indigo-500/25' : 'bg-white text-slate-700 border-slate-200/80 shadow-sm'}">
            <div class="w-11 h-11 rounded-xl flex items-center justify-center text-lg ${selectedSubject === '' ? 'bg-white/20 text-white' : 'bg-indigo-50 text-indigo-600'}">
                <i class="fa-solid fa-layer-group"></i>
            </div>
            <div>
                <div class="font-extrabold text-sm">Tất Cả Môn</div>
                <div class="text-xs ${selectedSubject === '' ? 'text-indigo-100' : 'text-slate-400'}">4 môn học</div>
            </div>
        </a>` + subList.map(sub => {
            const active = selectedSubject === sub.code;
            const st = getSubjectBadgeStyle(sub.code);
            return `
            <a href="index.html?subject=${encodeURIComponent(sub.code)}" class="card-hover p-4 rounded-2xl border transition flex items-center gap-3.5 ${active ? 'bg-gradient-to-r ' + st.gradient + ' text-white border-transparent shadow-lg' : 'bg-white text-slate-800 border-slate-200/80 shadow-sm'}">
                <div class="w-11 h-11 rounded-xl flex items-center justify-center text-lg shrink-0 ${active ? 'bg-white/20 text-white' : st.soft_icon}">
                    <i class="fa-solid ${esc(sub.icon)}"></i>
                </div>
                <div class="min-w-0">
                    <div class="font-extrabold text-sm truncate">${esc(sub.name)}</div>
                    <div class="text-xs ${active ? 'text-white/85' : 'text-slate-500'}">${examCountBySub[sub.id] || 0} đề thi chuẩn</div>
                </div>
            </a>`;
        }).join('');

    // Lọc đề
    const subById = Object.fromEntries(subList.map(s => [s.id, s]));
    const filteredExams = examList.filter(e => {
        const s = subById[e.subject_id];
        if (!s) return false;
        if (selectedSubject && s.code !== selectedSubject) return false;
        if (selectedLevel && e.level !== selectedLevel) return false;
        if (searchQuery) {
            const qLow = searchQuery.toLowerCase();
            const hay = `${e.title} ${e.description} ${s.name}`.toLowerCase();
            if (!hay.includes(qLow)) return false;
        }
        return true;
    });

    const container = document.getElementById('examsContainer');
    if (filteredExams.length === 0) {
        container.innerHTML = `
        <div class="bg-white rounded-3xl border border-slate-200/80 p-12 text-center">
            <div class="w-16 h-16 rounded-2xl bg-slate-100 text-slate-400 flex items-center justify-center mx-auto text-2xl mb-4">
                <i class="fa-solid fa-folder-open"></i>
            </div>
            <h3 class="text-lg font-extrabold text-slate-800">Không tìm thấy đề thi phù hợp</h3>
            <p class="text-sm text-slate-500 mt-1">Hãy thử đổi từ khóa tìm kiếm hoặc chọn môn học khác.</p>
            <a href="index.html" class="inline-flex items-center gap-2 mt-4 px-5 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-bold">Xem tất cả đề thi</a>
        </div>`;
        return;
    }

    const grouped = {};
    filteredExams.forEach(e => {
        const s = subById[e.subject_id];
        (grouped[s.code] = grouped[s.code] || []).push(e);
    });

    container.innerHTML = subList.filter(s => grouped[s.code]).map(sub => {
        const st = getSubjectBadgeStyle(sub.code);
        const list = grouped[sub.code];
        return `
        <div>
            <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-4 mb-5 border-b border-slate-200">
                <div class="flex items-center gap-3.5">
                    <div class="w-11 h-11 rounded-2xl bg-gradient-to-br ${esc(sub.gradient)} text-white flex items-center justify-center text-lg shadow-sm">
                        <i class="fa-solid ${esc(sub.icon)}"></i>
                    </div>
                    <div>
                        <div class="flex items-center gap-2.5">
                            <h2 class="text-xl font-extrabold text-slate-900">Bộ Đề Môn ${esc(sub.name)}</h2>
                            <span class="px-2.5 py-0.5 rounded-full text-xs font-bold ${st.bg} ${st.text} border ${st.border}">${list.length} đề</span>
                        </div>
                        <p class="text-xs text-slate-500 mt-0.5">${esc(sub.description)}</p>
                    </div>
                </div>
                ${!selectedSubject ? `<a href="index.html?subject=${encodeURIComponent(sub.code)}" class="text-xs font-bold ${st.text} hover:underline flex items-center gap-1">Xem riêng môn ${esc(sub.name)} <i class="fa-solid fa-arrow-right"></i></a>` : ''}
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-5">
                ${list.map(exam => {
                    const qs = qStats[exam.id] || { total: 0, mcq: 0, tf: 0, sa: 0, minPt: 0.25 };
                    const myBest = myBestByExam[exam.id];
                    const hasMixed = qs.tf > 0 || qs.sa > 0;
                    return `
                    <div class="card-hover bg-white rounded-3xl border border-slate-200/80 p-6 flex flex-col justify-between shadow-sm">
                        <div>
                            <div class="flex flex-wrap items-center justify-between gap-2 mb-3">
                                <div class="flex items-center gap-2">
                                    <span class="px-3 py-1 rounded-xl text-xs font-extrabold ${st.badge}">${esc(sub.name)}</span>
                                    <span class="px-2.5 py-1 rounded-xl text-xs font-bold bg-slate-100 text-slate-700">${esc(exam.level)}</span>
                                </div>
                                ${myBest !== undefined ? `
                                    <span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-xl text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                                        <i class="fa-solid fa-trophy text-amber-500"></i> Cao nhất: ${myBest.toFixed(1)}/10
                                    </span>` : ''}
                            </div>
                            <h3 class="text-lg font-extrabold text-slate-900 leading-snug">${esc(exam.title)}</h3>
                            <p class="text-xs text-slate-500 mt-2 line-clamp-2 leading-relaxed">${esc(exam.description)}</p>
                            ${exam.level === 'Chuẩn THPT QG' ? `
                                <div class="mt-3 flex flex-wrap items-center gap-1.5 text-[11px] font-bold">
                                    ${hasMixed
                                        ? `<span class="px-2 py-0.5 rounded-lg bg-violet-50 text-violet-700 border border-violet-200">${qs.mcq} TN • ${qs.tf} Đ/S • ${qs.sa} TLN</span>`
                                        : `<span class="px-2 py-0.5 rounded-lg bg-emerald-50 text-emerald-700 border border-emerald-200">${qs.minPt.toFixed(2)}đ/câu • Thang 10.00</span>`}
                                </div>` : ''}
                        </div>

                        <div class="mt-5 pt-4 border-t border-slate-100 flex flex-wrap items-center justify-between gap-3">
                            <div class="flex items-center gap-4 text-xs font-semibold text-slate-500">
                                <span class="flex items-center gap-1.5 font-bold text-slate-700"><i class="fa-regular fa-clock text-indigo-500"></i> ${exam.duration_minutes} phút</span>
                                <span class="flex items-center gap-1.5 font-bold text-slate-700"><i class="fa-regular fa-circle-question text-indigo-500"></i> ${qs.total} câu</span>
                                <span class="flex items-center gap-1.5"><i class="fa-solid fa-star text-amber-500"></i> ${hasMixed ? 'Thang 10.00' : qs.minPt.toFixed(2) + 'đ/câu'}</span>
                                <span class="flex items-center gap-1.5"><i class="fa-solid fa-users text-indigo-500"></i> ${attCountByExam[exam.id] || 0} lượt thi</span>
                            </div>
                            <a href="take_exam.html?id=${exam.id}" class="px-4 py-2.5 rounded-xl text-white font-bold text-xs shadow-sm transition flex items-center gap-2 ${st.btn}">
                                <i class="fa-solid fa-pen-to-square"></i> ${myBest !== undefined ? 'Luyện lại đề này' : 'Bắt đầu làm bài'}
                            </a>
                        </div>
                    </div>`;
                }).join('')}
            </div>
        </div>`;
    }).join('');
}

// ==========================================================
// ĐĂNG NHẬP & ĐĂNG KÝ (login.html, register.html)
// ==========================================================
function initLoginPage() {
    if (getCurrentUser()) {
        window.location.href = 'index.html';
        return;
    }
    const form = document.getElementById('loginForm');
    form.addEventListener('submit', async e => {
        e.preventDefault();
        const client = getSb();
        const errBox = document.getElementById('loginErrorBox');
        const errText = document.getElementById('loginErrorText');
        errBox.classList.add('hidden');

        if (!client) {
            errText.textContent = 'Chưa cấu hình Supabase URL / Anon Key trong assets/js/main.js.';
            errBox.classList.remove('hidden');
            return;
        }

        const username = document.getElementById('loginUsername').value.trim();
        const password = document.getElementById('loginPassword').value;
        const hash = await sha256(password);

        const { data: user, error } = await client
            .from('users')
            .select('*')
            .eq('username', username)
            .maybeSingle();

        if (error || !user || user.password_hash !== hash) {
            errText.textContent = 'Tên đăng nhập hoặc mật khẩu không chính xác!';
            errBox.classList.remove('hidden');
            return;
        }

        await client.from('users').update({ last_active_at: new Date().toISOString() }).eq('id', user.id);
        setCurrentUser({
            id: user.id,
            username: user.username,
            fullname: user.fullname,
            email: user.email,
            class_name: user.class_name,
            role: user.role
        });
        setFlash('success', `Chào mừng ${user.fullname} đã quay trở lại!`);
        window.location.href = user.role === 'admin' ? 'admin.html' : 'index.html';
    });
}

function initRegisterPage() {
    if (getCurrentUser()) {
        window.location.href = 'index.html';
        return;
    }
    const form = document.getElementById('registerForm');
    form.addEventListener('submit', async e => {
        e.preventDefault();
        const client = getSb();
        const errBox = document.getElementById('regErrorBox');
        const errText = document.getElementById('regErrorText');
        errBox.classList.add('hidden');

        const fullname = document.getElementById('regFullname').value.trim();
        const username = document.getElementById('regUsername').value.trim();
        const email = document.getElementById('regEmail').value.trim();
        const password = document.getElementById('regPassword').value;
        const confirm = document.getElementById('regConfirm').value;

        if (!fullname || !username || !password) {
            errText.textContent = 'Vui lòng điền đầy đủ Họ tên, Tên đăng nhập và Mật khẩu.';
            errBox.classList.remove('hidden');
            return;
        }
        if (!/^[a-zA-Z0-9_]{3,30}$/.test(username)) {
            errText.textContent = 'Tên đăng nhập chỉ gồm chữ cái, số, dấu gạch dưới (3-30 ký tự).';
            errBox.classList.remove('hidden');
            return;
        }
        if (password.length < 6) {
            errText.textContent = 'Mật khẩu phải có ít nhất 6 ký tự.';
            errBox.classList.remove('hidden');
            return;
        }
        if (password !== confirm) {
            errText.textContent = 'Mật khẩu nhập lại không khớp.';
            errBox.classList.remove('hidden');
            return;
        }
        if (!client) {
            errText.textContent = 'Chưa cấu hình Supabase URL / Anon Key.';
            errBox.classList.remove('hidden');
            return;
        }

        const { data: existing } = await client.from('users').select('id').eq('username', username).maybeSingle();
        if (existing) {
            errText.textContent = 'Tên đăng nhập này đã có người sử dụng. Vui lòng chọn tên khác.';
            errBox.classList.remove('hidden');
            return;
        }

        const password_hash = await sha256(password);
        const { data: newUser, error } = await client
            .from('users')
            .insert({ username, password_hash, fullname, email: email || null, class_name: 'Học sinh', role: 'student', last_active_at: new Date().toISOString() })
            .select()
            .single();

        if (error || !newUser) {
            errText.textContent = 'Không thể tạo tài khoản: ' + (error?.message || 'Lỗi máy chủ');
            errBox.classList.remove('hidden');
            return;
        }

        setCurrentUser({
            id: newUser.id,
            username: newUser.username,
            fullname: newUser.fullname,
            email: newUser.email,
            class_name: newUser.class_name,
            role: newUser.role
        });
        setFlash('success', 'Đăng ký tài khoản thành công! Chúc bạn ôn luyện hiệu quả.');
        window.location.href = 'index.html';
    });
}

// ==========================================================
// PHÒNG THI & GIÁM SÁT (take_exam.html)
// ==========================================================
const answeredState = {};
const tfSubAnswers = {};
const flaggedMap = {};
let currentPaletteFilter = 'all';
let totalQuestions = 0;
let totalSeconds = 0;
let remainingSeconds = 0;
let elapsedSeconds = 0;
let examSessionId = 0;
let tabSwitchCount = 0;
let lastExitTimestamp = 0;
let isConfirmingDialog = false;
let isSubmittingExam = false;
let timerInterval = null;
let currentExamData = null;
let currentQuestions = [];

function renderPaletteButton(qNum) {
    const btn = document.getElementById('palette-btn-' + qNum);
    if (!btn) return;
    const st = answeredState[qNum];
    const isDone = st && st.done;
    const isPartial = st && !st.done && st.label;
    const isFlagged = !!flaggedMap[qNum];

    btn.textContent = (st && st.label) ? (qNum + '.' + st.label) : String(qNum);
    if (isFlagged && isDone) btn.className = 'palette-item h-9 rounded-xl border-2 border-amber-400 bg-indigo-600 text-white font-extrabold text-[11px] transition flex items-center justify-center shadow-sm ring-2 ring-amber-300/60';
    else if (isFlagged) btn.className = 'palette-item h-9 rounded-xl border-2 border-amber-400 bg-amber-100 text-amber-900 font-extrabold text-[11px] transition flex items-center justify-center';
    else if (isDone) btn.className = 'palette-item h-9 rounded-xl border-2 border-indigo-600 bg-indigo-600 text-white font-extrabold text-[11px] transition flex items-center justify-center shadow-sm';
    else if (isPartial) btn.className = 'palette-item h-9 rounded-xl border-2 border-violet-400 bg-violet-50 text-violet-800 font-extrabold text-[11px] transition flex items-center justify-center';
    else btn.className = 'palette-item h-9 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 font-extrabold text-[11px] hover:border-indigo-400 transition flex items-center justify-center';
}

function getDoneCount() {
    return Object.values(answeredState).filter(st => st && st.done).length;
}

function updateOverallProgress() {
    const done = getDoneCount();
    const countEl = document.getElementById('answeredCount');
    const barEl = document.getElementById('progressBar');
    if (countEl) countEl.textContent = done;
    if (barEl && totalQuestions > 0) barEl.style.width = Math.round((done / totalQuestions) * 100) + '%';
}

function applyPaletteFilter() {
    document.querySelectorAll('.palette-item').forEach(btn => {
        const qNum = btn.getAttribute('data-qnum');
        const st = answeredState[qNum];
        const isDone = st && st.done;
        const isFlagged = !!flaggedMap[qNum];
        let show = true;
        if (currentPaletteFilter === 'unanswered') show = !isDone;
        if (currentPaletteFilter === 'flagged') show = isFlagged;
        btn.style.display = show ? 'flex' : 'none';
    });
}

function filterPalette(type) {
    currentPaletteFilter = type;
    ['all', 'unanswered', 'flagged'].forEach(t => {
        const b = document.getElementById('filter-btn-' + t);
        if (b) b.className = t === type ? 'py-1.5 rounded-lg bg-white text-indigo-700 shadow-sm transition' : 'py-1.5 rounded-lg text-slate-600 hover:text-slate-900 transition';
    });
    applyPaletteFilter();
}

function toggleFlag(qNum) {
    flaggedMap[qNum] = !flaggedMap[qNum];
    const flagBtn = document.getElementById('flag-btn-' + qNum);
    if (flagBtn) {
        if (flaggedMap[qNum]) {
            flagBtn.className = 'px-2.5 py-1 rounded-lg text-[11px] font-extrabold border border-amber-400 bg-amber-100 text-amber-800 transition flex items-center gap-1';
            flagBtn.innerHTML = '<i class="fa-solid fa-flag"></i> Đã đánh dấu';
        } else {
            flagBtn.className = 'px-2.5 py-1 rounded-lg text-[11px] font-bold border border-slate-200 text-slate-500 hover:bg-amber-50 hover:text-amber-700 hover:border-amber-300 transition flex items-center gap-1';
            flagBtn.innerHTML = '<i class="fa-regular fa-flag"></i> Xem lại';
        }
    }
    const flaggedTotal = Object.values(flaggedMap).filter(Boolean).length;
    const badge = document.getElementById('flaggedCountBadge');
    if (badge) {
        badge.textContent = flaggedTotal + ' đánh dấu';
        badge.classList.toggle('hidden', flaggedTotal === 0);
    }
    renderPaletteButton(qNum);
    applyPaletteFilter();
}

function handleSelectMcq(qNum, letter, radioInput) {
    answeredState[qNum] = { label: letter, done: true };
    const block = document.getElementById('question-block-' + qNum);
    if (block) {
        block.querySelectorAll('.option-card').forEach(card => {
            card.classList.remove('border-indigo-600', 'bg-indigo-50/80', 'ring-2', 'ring-indigo-500/20');
            card.classList.add('border-slate-200/80');
            const badge = card.querySelector('.option-letter');
            if (badge) { badge.classList.remove('bg-indigo-600', 'text-white'); badge.classList.add('bg-slate-100', 'text-slate-700'); }
        });
    }
    const activeCard = radioInput.closest('.option-card');
    if (activeCard) {
        activeCard.classList.remove('border-slate-200/80');
        activeCard.classList.add('border-indigo-600', 'bg-indigo-50/80', 'ring-2', 'ring-indigo-500/20');
        const activeBadge = activeCard.querySelector('.option-letter');
        if (activeBadge) { activeBadge.classList.remove('bg-slate-100', 'text-slate-700'); activeBadge.classList.add('bg-indigo-600', 'text-white'); }
    }
    const sbBadge = document.getElementById('status-badge-' + qNum);
    if (sbBadge) { sbBadge.textContent = 'Đã chọn ' + letter; sbBadge.className = 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-emerald-100 text-emerald-700'; }
    renderPaletteButton(qNum);
    applyPaletteFilter();
    updateOverallProgress();
}

function handleSelectTrueFalse(qNum, subKey, val, radioInput) {
    if (!tfSubAnswers[qNum]) tfSubAnswers[qNum] = {};
    tfSubAnswers[qNum][subKey] = val;
    const row = radioInput.closest('.flex');
    if (row) {
        row.querySelectorAll('.tf-label').forEach(lbl => {
            lbl.className = 'tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-slate-200 bg-white text-slate-600 text-xs font-extrabold hover:border-slate-300 transition';
        });
    }
    const activeLbl = radioInput.closest('.tf-pill')?.querySelector('.tf-label');
    if (activeLbl) {
        activeLbl.className = val === 'D'
            ? 'tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-emerald-600 bg-emerald-600 text-white text-xs font-extrabold shadow-sm transition'
            : 'tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-rose-600 bg-rose-600 text-white text-xs font-extrabold shadow-sm transition';
    }
    const cnt = Object.keys(tfSubAnswers[qNum]).length;
    const isFull = cnt === 4;
    answeredState[qNum] = { label: cnt + '/4', done: isFull };
    const sbBadge = document.getElementById('status-badge-' + qNum);
    if (sbBadge) {
        sbBadge.textContent = isFull ? 'Đủ 4/4 ý' : 'Đã chọn ' + cnt + '/4 ý';
        sbBadge.className = isFull ? 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-emerald-100 text-emerald-700' : 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-violet-100 text-violet-700';
    }
    renderPaletteButton(qNum);
    applyPaletteFilter();
    updateOverallProgress();
}

function handleShortAnswer(qNum, value) {
    const trimmed = value.trim();
    const hasVal = trimmed.length > 0;
    answeredState[qNum] = hasVal ? { label: '✓', done: true } : { label: '', done: false };
    const sbBadge = document.getElementById('status-badge-' + qNum);
    if (sbBadge) {
        sbBadge.textContent = hasVal ? 'Đã điền: ' + trimmed : 'Chưa làm';
        sbBadge.className = hasVal ? 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-emerald-100 text-emerald-700' : 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-slate-100 text-slate-500';
    }
    renderPaletteButton(qNum);
    applyPaletteFilter();
    updateOverallProgress();
}

function scrollToQuestion(qNum) {
    document.getElementById('question-block-' + qNum)?.scrollIntoView({ behavior: 'smooth', block: 'start' });
}

async function sendExamHeartbeat() {
    const client = getSb();
    const user = getCurrentUser();
    if (!client || !user || isSubmittingExam || examSessionId <= 0) return;
    const nowIso = new Date().toISOString();
    await Promise.all([
        client.from('exam_sessions').update({
            last_heartbeat: nowIso,
            elapsed_seconds: elapsedSeconds,
            answered_count: getDoneCount(),
            tab_switch_count: tabSwitchCount
        }).eq('id', examSessionId).eq('user_id', user.id),
        client.from('users').update({ last_active_at: nowIso }).eq('id', user.id)
    ]);
}

function recordScreenExit() {
    if (isConfirmingDialog || isSubmittingExam || examSessionId <= 0) return;
    const now = Date.now();
    if (now - lastExitTimestamp < 1200) return;
    lastExitTimestamp = now;

    tabSwitchCount++;
    const badgeCount = document.getElementById('tabSwitchBadgeCount');
    const badge = document.getElementById('proctorBadge');
    const banner = document.getElementById('proctorAlertBanner');
    const alertText = document.getElementById('proctorAlertText');

    if (badgeCount) badgeCount.textContent = tabSwitchCount;
    if (badge) badge.className = 'px-3 py-2 rounded-xl bg-rose-50 text-rose-700 border border-rose-300 text-xs font-extrabold flex items-center gap-1.5 animate-pulse';
    if (banner && alertText) {
        alertText.textContent = `Cảnh báo giám sát: Bạn vừa thoát khỏi màn hình làm bài (Lần thứ ${tabSwitchCount}). Thông tin này đã được ghi nhận!`;
        banner.classList.remove('hidden');
    }
    sendExamHeartbeat();
}

function confirmExitExam() {
    isConfirmingDialog = true;
    const ok = confirm('Bạn có chắc muốn thoát khỏi phòng thi? Kết quả chưa nộp sẽ không được lưu.');
    setTimeout(() => { isConfirmingDialog = false; }, 300);
    return ok;
}

async function submitExamToSupabase() {
    const client = getSb();
    const user = getCurrentUser();
    if (!client || !user || !currentExamData) return;

    isSubmittingExam = true;
    clearInterval(timerInterval);

    const form = document.getElementById('examForm');
    const formData = new FormData(form);
    let totalScore = 0;
    let correctCount = 0;
    const answerRows = [];

    currentQuestions.forEach(q => {
        const qid = q.id;
        const type = q.question_type || 'mcq';
        let rawAns = null;
        if (type === 'true_false') {
            rawAns = {
                a: formData.get(`answers[${qid}][a]`) || '',
                b: formData.get(`answers[${qid}][b]`) || '',
                c: formData.get(`answers[${qid}][c]`) || '',
                d: formData.get(`answers[${qid}][d]`) || ''
            };
        } else {
            rawAns = formData.get(`answers[${qid}]`) || '';
        }
        const g = gradeQuestion(q, rawAns);
        totalScore += g.earned_points;
        if (g.is_correct) correctCount++;
        answerRows.push({ question_id: qid, selected_option: g.selected_option, is_correct: g.is_correct, earned_points: Number(g.earned_points.toFixed(2)) });
    });

    totalScore = Math.min(10, Math.round(totalScore * 100) / 100);
    const timeSpent = Math.max(1, elapsedSeconds);

    const { data: attempt, error } = await client
        .from('exam_attempts')
        .insert({
            user_id: user.id,
            exam_id: currentExamData.id,
            score: totalScore,
            correct_count: correctCount,
            total_questions: currentQuestions.length,
            time_spent_seconds: timeSpent,
            tab_switch_count: tabSwitchCount
        })
        .select()
        .single();

    if (error || !attempt) {
        alert('Có lỗi khi nộp bài: ' + (error?.message || 'Vui lòng thử lại.'));
        isSubmittingExam = false;
        return;
    }

    const payload = answerRows.map(r => ({ ...r, attempt_id: attempt.id }));
    await client.from('attempt_answers').insert(payload);

    if (examSessionId > 0) {
        await client.from('exam_sessions').update({
            status: 'submitted',
            elapsed_seconds: timeSpent,
            answered_count: getDoneCount(),
            tab_switch_count: tabSwitchCount,
            last_heartbeat: new Date().toISOString()
        }).eq('id', examSessionId);
    }

    window.location.href = `result.html?attempt_id=${attempt.id}`;
}

function confirmSubmitExam() {
    isConfirmingDialog = true;
    const unanswered = totalQuestions - getDoneCount();
    const msg = unanswered > 0
        ? `Bạn còn ${unanswered} câu hỏi chưa hoàn thành đầy đủ. Bạn vẫn muốn nộp bài chứ?`
        : 'Bạn có chắc chắn muốn nộp bài và chấm điểm ngay?';
    const ok = confirm(msg);
    setTimeout(() => { isConfirmingDialog = false; }, 300);
    if (ok) {
        submitExamToSupabase();
    }
}

async function initTakeExamPage() {
    const user = getCurrentUser();
    if (!user) {
        setFlash('error', 'Vui lòng đăng nhập để bắt đầu làm bài thi.');
        window.location.href = 'login.html';
        return;
    }
    const client = getSb();
    const examId = Number(getQueryParam('id'));
    if (!client || !examId) {
        window.location.href = 'index.html';
        return;
    }

    const { data: exam } = await client.from('exams').select('*, subjects(*)').eq('id', examId).maybeSingle();
    if (!exam) {
        setFlash('error', 'Đề thi không tồn tại!');
        window.location.href = 'index.html';
        return;
    }

    const { data: questions } = await client.from('questions').select('*').eq('exam_id', examId).order('sort_order').order('id');
    currentExamData = exam;
    currentQuestions = questions || [];
    totalQuestions = currentQuestions.length;
    totalSeconds = Number(exam.duration_minutes) * 60;
    remainingSeconds = totalSeconds;

    const { data: sessionRow } = await client
        .from('exam_sessions')
        .insert({ user_id: user.id, exam_id: examId, total_questions: totalQuestions, status: 'in_progress' })
        .select()
        .single();
    examSessionId = sessionRow ? sessionRow.id : 0;

    const st = getSubjectBadgeStyle(exam.subjects.code);
    const hasMixed = currentQuestions.some(q => q.question_type !== 'mcq');

    let currentPartShown = '';
    const questionsHtml = currentQuestions.map((q, idx) => {
        const qNum = idx + 1;
        const qType = q.question_type || 'mcq';
        const typeInfo = getQuestionTypeInfo(qType);
        const diffStyle = getDifficultyBadgeStyle(q.difficulty || 'Nhận biết');
        let banner = '';
        if (hasMixed && typeInfo.part !== currentPartShown) {
            currentPartShown = typeInfo.part;
            banner = `
            <div class="rounded-2xl bg-gradient-to-r from-slate-800 to-indigo-900 text-white px-5 py-3.5 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                <div class="font-extrabold text-sm flex items-center gap-2"><i class="fa-solid fa-layer-group text-amber-300"></i> ${typeInfo.part}: ${typeInfo.label}</div>
                <span class="text-[11px] text-indigo-200 font-medium">${typeInfo.desc}</span>
            </div>`;
        }

        let bodyHtml = '';
        if (qType === 'true_false') {
            const subs = { a: q.option_a, b: q.option_b, c: q.option_c, d: q.option_d };
            bodyHtml = `<div class="space-y-3">` + Object.entries(subs).map(([k, txt]) => `
                <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-3.5 rounded-2xl bg-slate-50 border border-slate-200/80">
                    <div class="text-sm font-medium text-slate-800 leading-relaxed flex-1">${esc(txt)}</div>
                    <div class="flex items-center gap-2 shrink-0">
                        <label class="cursor-pointer tf-pill">
                            <input type="radio" name="answers[${q.id}][${k}]" value="D" class="sr-only" onchange="handleSelectTrueFalse(${qNum}, '${k}', 'D', this)">
                            <span class="tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-slate-200 bg-white text-slate-600 text-xs font-extrabold hover:border-emerald-400 transition"><i class="fa-solid fa-check"></i> Đúng</span>
                        </label>
                        <label class="cursor-pointer tf-pill">
                            <input type="radio" name="answers[${q.id}][${k}]" value="S" class="sr-only" onchange="handleSelectTrueFalse(${qNum}, '${k}', 'S', this)">
                            <span class="tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-slate-200 bg-white text-slate-600 text-xs font-extrabold hover:border-rose-400 transition"><i class="fa-solid fa-xmark"></i> Sai</span>
                        </label>
                    </div>
                </div>`).join('') + `</div>`;
        } else if (qType === 'short_answer') {
            bodyHtml = `
            <div class="p-4 rounded-2xl bg-teal-50/60 border border-teal-200/80">
                <label class="block text-xs font-extrabold uppercase tracking-wider text-teal-800 mb-2"><i class="fa-solid fa-keyboard mr-1"></i> Nhập đáp án số của bạn:</label>
                <input type="text" name="answers[${q.id}]" autocomplete="off" placeholder="VD: 12 hoặc 3.5" oninput="handleShortAnswer(${qNum}, this.value)"
                       class="w-full sm:w-72 px-4 py-3 rounded-xl bg-white border-2 border-teal-300 focus:border-indigo-600 outline-none text-base font-extrabold text-slate-900 tracking-wide shadow-sm">
            </div>`;
        } else {
            const opts = { A: q.option_a, B: q.option_b, C: q.option_c, D: q.option_d };
            bodyHtml = `<div class="grid grid-cols-1 sm:grid-cols-2 gap-3">` + Object.entries(opts).map(([letter, text]) => `
                <label class="option-card relative flex items-start gap-3 p-4 rounded-2xl border-2 border-slate-200/80 cursor-pointer hover:border-indigo-300 hover:bg-indigo-50/30 transition">
                    <input type="radio" name="answers[${q.id}]" value="${letter}" class="sr-only" onchange="handleSelectMcq(${qNum}, '${letter}', this)">
                    <span class="option-letter w-8 h-8 rounded-xl bg-slate-100 text-slate-700 font-extrabold text-sm flex items-center justify-center shrink-0 transition">${letter}</span>
                    <span class="text-sm font-medium text-slate-700 leading-relaxed pt-1">${esc(text)}</span>
                </label>`).join('') + `</div>`;
        }

        return `
        ${banner}
        <div id="question-block-${qNum}" class="bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm scroll-mt-24">
            <div class="flex flex-wrap items-center justify-between gap-2 mb-4">
                <div class="flex flex-wrap items-center gap-2">
                    <span class="px-3 py-1 rounded-xl bg-indigo-600 text-white text-xs font-extrabold">Câu ${qNum}</span>
                    <span class="px-2.5 py-1 rounded-xl text-[11px] font-bold border ${typeInfo.badge}">${typeInfo.short}</span>
                    <span class="px-2.5 py-1 rounded-xl text-[11px] font-bold border ${diffStyle}">${esc(q.difficulty || 'Nhận biết')}</span>
                    <span class="text-[11px] font-semibold text-slate-400">(${Number(q.points_value).toFixed(2)}đ)</span>
                </div>
                <div class="flex items-center gap-2">
                    <button type="button" id="flag-btn-${qNum}" onclick="toggleFlag(${qNum})" class="px-2.5 py-1 rounded-lg text-[11px] font-bold border border-slate-200 text-slate-500 hover:bg-amber-50 hover:text-amber-700 hover:border-amber-300 transition flex items-center gap-1">
                        <i class="fa-regular fa-flag"></i> Xem lại
                    </button>
                    <span id="status-badge-${qNum}" class="px-2.5 py-1 rounded-lg text-[11px] font-bold bg-slate-100 text-slate-500">Chưa làm</span>
                </div>
            </div>
            <h3 class="text-base font-bold text-slate-900 leading-relaxed mb-4">${esc(q.question_text)}</h3>
            ${bodyHtml}
        </div>`;
    }).join('');

    const paletteHtml = currentQuestions.map((q, idx) => `
        <button type="button" id="palette-btn-${idx + 1}" data-qnum="${idx + 1}" onclick="scrollToQuestion(${idx + 1})"
                class="palette-item h-9 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 font-extrabold text-[11px] hover:border-indigo-400 transition flex items-center justify-center">
            ${idx + 1}
        </button>`).join('');

    document.getElementById('takeExamContainer').innerHTML = `
    <div id="proctorAlertBanner" class="hidden mb-4 p-4 rounded-2xl bg-rose-50 border-2 border-rose-300 text-rose-800 text-sm font-bold flex items-center justify-between gap-3 shadow-sm">
        <div class="flex items-center gap-2.5"><i class="fa-solid fa-triangle-exclamation text-rose-600 text-lg"></i><span id="proctorAlertText"></span></div>
        <button type="button" onclick="this.parentElement.classList.add('hidden')" class="text-rose-500 hover:text-rose-700"><i class="fa-solid fa-xmark"></i></button>
    </div>

    <div class="bg-white rounded-3xl border border-slate-200/80 p-5 mb-6 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
            <div class="flex items-center gap-2 mb-1">
                <span class="px-3 py-1 rounded-xl text-xs font-extrabold ${st.badge}">${esc(exam.subjects.name)}</span>
                <span class="text-xs font-semibold text-slate-400">${esc(exam.level)}</span>
            </div>
            <h1 class="text-xl font-extrabold text-slate-900">${esc(exam.title)}</h1>
        </div>
        <div class="flex flex-wrap items-center gap-3 shrink-0">
            <div id="proctorBadge" class="px-3 py-2 rounded-xl bg-emerald-50 text-emerald-700 border border-emerald-200 text-xs font-bold flex items-center gap-1.5">
                <i class="fa-solid fa-shield-halved"></i>
                <span>Thoát màn hình: <strong id="tabSwitchBadgeCount">0</strong> lần</span>
            </div>
            <div class="px-4 py-2.5 rounded-2xl bg-slate-900 text-white flex items-center gap-3 shadow-md">
                <i class="fa-regular fa-clock text-amber-400 text-lg"></i>
                <div>
                    <div class="text-[10px] uppercase tracking-wider text-slate-400 font-bold">Thời gian còn lại</div>
                    <div id="countdownTimer" class="text-xl font-black tracking-wider text-amber-300">${String(exam.duration_minutes).padStart(2, '0')}:00</div>
                </div>
            </div>
            <a href="index.html" onclick="return confirmExitExam()" class="px-4 py-3 rounded-2xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition">Thoát</a>
        </div>
    </div>

    <form id="examForm">
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            <div class="lg:col-span-8 space-y-5">${questionsHtml}</div>
            <div class="lg:col-span-4 lg:sticky lg:top-20">
                <div class="bg-white rounded-3xl border border-slate-200/80 p-5 shadow-sm">
                    <div class="flex items-center justify-between mb-3">
                        <h3 class="font-extrabold text-slate-900 text-sm flex items-center gap-2"><i class="fa-solid fa-grid-2 text-indigo-600"></i> <span>Phiếu trả lời Form 2026</span></h3>
                        <span class="text-xs font-bold text-indigo-600"><span id="answeredCount">0</span> / ${totalQuestions} câu</span>
                    </div>
                    <div class="w-full bg-slate-100 h-2 rounded-full overflow-hidden mb-3"><div id="progressBar" class="bg-indigo-600 h-full transition-all duration-300" style="width: 0%"></div></div>
                    <div class="grid grid-cols-3 gap-1.5 mb-3 p-1 bg-slate-100 rounded-xl text-[11px] font-bold">
                        <button type="button" onclick="filterPalette('all')" id="filter-btn-all" class="py-1.5 rounded-lg bg-white text-indigo-700 shadow-sm transition">Tất cả (${totalQuestions})</button>
                        <button type="button" onclick="filterPalette('unanswered')" id="filter-btn-unanswered" class="py-1.5 rounded-lg text-slate-600 hover:text-slate-900 transition">Chưa làm</button>
                        <button type="button" onclick="filterPalette('flagged')" id="filter-btn-flagged" class="py-1.5 rounded-lg text-slate-600 hover:text-slate-900 transition">Xem lại</button>
                    </div>
                    <div id="questionPalette" class="grid grid-cols-5 gap-2 mb-4 max-h-72 overflow-y-auto pr-1">${paletteHtml}</div>
                    <div class="flex flex-wrap items-center justify-between gap-2 text-[11px] text-slate-500 mb-4 pt-3 border-t border-slate-100">
                        <div class="flex items-center gap-3">
                            <span class="flex items-center gap-1"><span class="w-3 h-3 rounded bg-indigo-600 inline-block"></span> Đã làm</span>
                            <span class="flex items-center gap-1"><span class="w-3 h-3 rounded bg-amber-300 border border-amber-500 inline-block"></span> Xem lại</span>
                        </div>
                        <span id="flaggedCountBadge" class="font-bold text-amber-600 hidden">0 đánh dấu</span>
                    </div>
                    <button type="button" onclick="confirmSubmitExam()" class="w-full py-3.5 rounded-2xl bg-gradient-to-r from-indigo-600 to-blue-600 hover:from-indigo-700 hover:to-blue-700 text-white font-extrabold text-sm shadow-lg shadow-indigo-500/25 transition flex items-center justify-center gap-2">
                        <i class="fa-solid fa-paper-plane"></i> NỘP BÀI &amp; CHẤM ĐIỂM 2026
                    </button>
                </div>
            </div>
        </div>
    </form>`;

    document.addEventListener('visibilitychange', () => { if (document.hidden) recordScreenExit(); });
    window.addEventListener('blur', () => recordScreenExit());

    sendExamHeartbeat();
    setInterval(sendExamHeartbeat, 10000);

    const timerEl = document.getElementById('countdownTimer');
    timerInterval = setInterval(() => {
        elapsedSeconds++;
        remainingSeconds--;
        if (remainingSeconds <= 0) {
            clearInterval(timerInterval);
            isConfirmingDialog = true;
            alert('Đã hết thời gian làm bài! Hệ thống sẽ tự động nộp bài của bạn.');
            submitExamToSupabase();
            return;
        }
        const mins = Math.floor(remainingSeconds / 60);
        const secs = remainingSeconds % 60;
        if (timerEl) {
            timerEl.textContent = String(mins).padStart(2, '0') + ':' + String(secs).padStart(2, '0');
            if (remainingSeconds <= 300) {
                timerEl.classList.remove('text-amber-300');
                timerEl.classList.add('text-rose-400', 'animate-pulse');
            }
        }
    }, 1000);
}

// ==========================================================
// KẾT QUẢ BÀI THI (result.html)
// ==========================================================
function filterReview(type) {
    ['all', 'wrong', 'correct'].forEach(t => {
        const btn = document.getElementById('rev-filter-' + t);
        if (btn) btn.className = t === type ? 'px-3.5 py-2 rounded-lg bg-indigo-600 text-white transition' : 'px-3.5 py-2 rounded-lg text-slate-600 hover:text-indigo-600 transition';
    });
    document.querySelectorAll('.review-item').forEach(el => {
        const status = el.getAttribute('data-status');
        el.style.display = (type === 'all' || status === type) ? 'block' : 'none';
    });
}

async function initResultPage() {
    const user = getCurrentUser();
    if (!user) {
        window.location.href = 'login.html';
        return;
    }
    const client = getSb();
    const attemptId = Number(getQueryParam('attempt_id'));
    if (!client || !attemptId) {
        window.location.href = 'index.html';
        return;
    }

    const { data: attempt } = await client
        .from('exam_attempts')
        .select('*, users(fullname), exams(*, subjects(*))')
        .eq('id', attemptId)
        .maybeSingle();

    if (!attempt || (Number(attempt.user_id) !== Number(user.id) && user.role !== 'admin')) {
        setFlash('error', 'Không tìm thấy kết quả bài thi.');
        window.location.href = 'index.html';
        return;
    }

    const { data: details } = await client
        .from('attempt_answers')
        .select('*, questions(*)')
        .eq('attempt_id', attemptId);

    const rows = (details || []).sort((a, b) => (a.questions?.sort_order || 0) - (b.questions?.sort_order || 0));

    const typeStats = {
        mcq: { label: 'Phần I: Trắc nghiệm ABCD', count: 0, earned: 0, max: 0 },
        true_false: { label: 'Phần II: Đúng / Sai 4 ý', count: 0, earned: 0, max: 0 },
        short_answer: { label: 'Phần III: Trả lời ngắn', count: 0, earned: 0, max: 0 }
    };
    const diffStats = {};

    rows.forEach(r => {
        const q = r.questions;
        if (!q) return;
        const qt = q.question_type || 'mcq';
        if (typeStats[qt]) {
            typeStats[qt].count++;
            typeStats[qt].earned += parseFloat(r.earned_points || 0);
            typeStats[qt].max += parseFloat(q.points_value || 0.25);
        }
        const d = q.difficulty || 'Nhận biết';
        if (!diffStats[d]) diffStats[d] = { total: 0, correct: 0 };
        diffStats[d].total++;
        if (r.is_correct) diffStats[d].correct++;
    });

    const score = parseFloat(attempt.score);
    let rankText = 'Cần cố gắng thêm! Hãy đọc kỹ lời giải bên dưới nhé';
    let rankBadge = 'bg-rose-100 text-rose-800';
    if (score >= 8.5) { rankText = 'Xuất sắc! Rất sẵn sàng cho kỳ thi THPT 2026'; rankBadge = 'bg-emerald-100 text-emerald-800'; }
    else if (score >= 7.0) { rankText = 'Khá tốt! Ôn lại các câu sai để bứt phá điểm 9+'; rankBadge = 'bg-blue-100 text-blue-800'; }
    else if (score >= 5.0) { rankText = 'Đạt mức Trung bình. Cần củng cố thêm phần Vận dụng'; rankBadge = 'bg-amber-100 text-amber-800'; }

    const mins = Math.floor(attempt.time_spent_seconds / 60);
    const secs = attempt.time_spent_seconds % 60;
    const exits = Number(attempt.tab_switch_count || 0);

    const reviewHtml = rows.map((row, idx) => {
        const q = row.questions;
        const qType = q.question_type || 'mcq';
        const typeInfo = getQuestionTypeInfo(qType);
        const earned = parseFloat(row.earned_points || 0);
        const maxPt = parseFloat(q.points_value || 0.25);
        const isFull = Number(row.is_correct) === 1;
        const isPartial = !isFull && earned > 0;
        const statusAttr = isFull ? 'correct' : 'wrong';

        let cardBorder = 'border-rose-200/80';
        let badgeHtml = `<span class="px-2.5 py-1 rounded-lg bg-rose-100 text-rose-700 text-xs font-extrabold"><i class="fa-solid fa-xmark mr-1"></i> Sai (0đ)</span>`;
        if (isFull) {
            cardBorder = 'border-emerald-200/80';
            badgeHtml = `<span class="px-2.5 py-1 rounded-lg bg-emerald-100 text-emerald-700 text-xs font-extrabold"><i class="fa-solid fa-check mr-1"></i> Đúng (+${earned.toFixed(2)}đ)</span>`;
        } else if (isPartial) {
            cardBorder = 'border-amber-300/80';
            badgeHtml = `<span class="px-2.5 py-1 rounded-lg bg-amber-100 text-amber-800 text-xs font-extrabold"><i class="fa-solid fa-star-half-stroke mr-1"></i> Đạt ${earned.toFixed(2)} / ${maxPt.toFixed(2)}đ</span>`;
        }

        let ansDetailHtml = '';
        if (qType === 'true_false') {
            const expParts = String(q.correct_option).split(',');
            const usrParts = (row.selected_option || '').split(',');
            const subs = [q.option_a, q.option_b, q.option_c, q.option_d];
            ansDetailHtml = `<div class="space-y-2 mb-4">` + subs.map((txt, i) => {
                const exp = expParts[i] || '';
                const usr = usrParts[i] || '';
                const ok = usr !== '' && usr === exp;
                return `
                <div class="p-3 rounded-xl border text-xs flex flex-col sm:flex-row sm:items-center justify-between gap-2 ${ok ? 'bg-emerald-50/70 border-emerald-200' : 'bg-rose-50/70 border-rose-200'}">
                    <span class="font-medium text-slate-800">${esc(txt)}</span>
                    <div class="flex items-center gap-2 shrink-0 font-extrabold">
                        <span class="px-2 py-0.5 rounded bg-white border border-slate-200 text-slate-600">Chọn: ${usr === 'D' ? 'Đúng' : (usr === 'S' ? 'Sai' : '—')}</span>
                        <span class="px-2 py-0.5 rounded bg-emerald-600 text-white">Đáp án: ${exp === 'D' ? 'Đúng' : 'Sai'}</span>
                    </div>
                </div>`;
            }).join('') + `</div>`;
        } else if (qType === 'short_answer') {
            ansDetailHtml = `
            <div class="grid grid-cols-1 sm:grid-cols-2 gap-3 mb-4 text-xs">
                <div class="p-3.5 rounded-xl border ${isFull ? 'bg-emerald-50 border-emerald-200 text-emerald-800' : 'bg-rose-50 border-rose-200 text-rose-800'}">
                    <div class="font-bold uppercase text-[10px] opacity-70 mb-0.5">Câu trả lời của bạn</div>
                    <div class="text-base font-black">${esc(row.selected_option || '(Bỏ trống)')}</div>
                </div>
                <div class="p-3.5 rounded-xl border bg-emerald-50 border-emerald-300 text-emerald-900">
                    <div class="font-bold uppercase text-[10px] opacity-70 mb-0.5">Đáp án chính xác</div>
                    <div class="text-base font-black">${esc(q.correct_option)}</div>
                </div>
            </div>`;
        } else {
            const opts = { A: q.option_a, B: q.option_b, C: q.option_c, D: q.option_d };
            ansDetailHtml = `<div class="grid grid-cols-1 sm:grid-cols-2 gap-2.5 mb-4">` + Object.entries(opts).map(([l, t]) => {
                const isExp = l === q.correct_option;
                const isUsr = l === row.selected_option;
                let cls = 'border-slate-200 bg-slate-50/60 text-slate-600';
                if (isExp) cls = 'border-emerald-500 bg-emerald-50 text-emerald-900 font-bold';
                else if (isUsr && !isExp) cls = 'border-rose-400 bg-rose-50 text-rose-900 font-bold';
                return `
                <div class="flex items-start gap-2.5 p-3 rounded-xl border text-xs ${cls}">
                    <span class="w-6 h-6 rounded-lg flex items-center justify-center font-extrabold shrink-0 ${isExp ? 'bg-emerald-600 text-white' : (isUsr ? 'bg-rose-600 text-white' : 'bg-white border border-slate-200')}">${l}</span>
                    <span class="pt-0.5 leading-relaxed">${esc(t)}</span>
                </div>`;
            }).join('') + `</div>`;
        }

        return `
        <div class="review-item bg-white rounded-3xl border-2 p-6 shadow-sm ${cardBorder}" data-status="${statusAttr}">
            <div class="flex flex-wrap items-center justify-between gap-2 mb-3">
                <div class="flex flex-wrap items-center gap-2">
                    <span class="px-3 py-1 rounded-xl bg-slate-900 text-white text-xs font-extrabold">Câu ${idx + 1}</span>
                    <span class="px-2.5 py-1 rounded-xl text-[11px] font-bold border ${typeInfo.badge}">${typeInfo.short}</span>
                    <span class="px-2.5 py-1 rounded-xl text-[11px] font-bold border ${getDifficultyBadgeStyle(q.difficulty || 'Nhận biết')}">${esc(q.difficulty || 'Nhận biết')}</span>
                </div>
                ${badgeHtml}
            </div>
            <h3 class="text-sm sm:text-base font-bold text-slate-900 leading-relaxed mb-4">${esc(q.question_text)}</h3>
            ${ansDetailHtml}
            ${q.explanation ? `
                <div class="p-4 rounded-2xl bg-indigo-50/70 border border-indigo-100 text-xs text-slate-700 leading-relaxed">
                    <span class="font-extrabold text-indigo-700"><i class="fa-solid fa-lightbulb mr-1"></i> Hướng dẫn giải:</span>
                    <div class="mt-1 whitespace-pre-line">${esc(q.explanation)}</div>
                </div>` : ''}
        </div>`;
    }).join('');

    document.getElementById('resultContainer').innerHTML = `
    <div class="bg-white rounded-3xl border border-slate-200/80 shadow-xl shadow-slate-200/40 overflow-hidden mb-8">
        <div class="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 p-6 sm:p-8 text-white">
            <div class="flex flex-col md:flex-row md:items-center justify-between gap-6">
                <div>
                    <span class="px-3 py-1 rounded-xl text-xs font-extrabold bg-white/15 text-indigo-200">${esc(attempt.exams.subjects.name)} • ${esc(attempt.exams.level)}</span>
                    <h1 class="text-2xl font-extrabold mt-2">${esc(attempt.exams.title)}</h1>
                    <p class="text-xs text-slate-300 mt-1">Thí sinh: <strong>${esc(attempt.users?.fullname || user.fullname)}</strong> • Nộp lúc: ${formatDateTimeVN(attempt.completed_at)}</p>
                    <div class="mt-4 flex flex-wrap items-center gap-2">
                        <span class="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-xl text-xs font-extrabold ${rankBadge}"><i class="fa-solid fa-award"></i> ${rankText}</span>
                        <span class="inline-flex items-center gap-1.5 px-3.5 py-1.5 rounded-xl text-xs font-extrabold ${exits > 0 ? 'bg-rose-500/20 text-rose-200 border border-rose-400/40' : 'bg-emerald-500/20 text-emerald-200 border border-emerald-400/40'}">
                            <i class="fa-solid fa-shield-halved"></i> Thoát màn hình: ${exits} lần
                        </span>
                    </div>
                </div>
                <div class="bg-white/10 backdrop-blur-md border border-white/20 rounded-3xl px-8 py-5 text-center shrink-0">
                    <div class="text-[11px] font-extrabold uppercase tracking-wider text-slate-400">Tổng điểm (Form 2026)</div>
                    <div class="text-5xl font-black text-amber-300 mt-1">${score.toFixed(2)}<span class="text-lg text-slate-400 font-bold">/10</span></div>
                </div>
            </div>
        </div>

        <div class="grid grid-cols-2 sm:grid-cols-4 divide-y sm:divide-y-0 sm:divide-x divide-slate-100 text-center">
            <div class="p-5"><div class="text-2xl font-black text-emerald-600">${attempt.correct_count}</div><div class="text-xs font-semibold text-slate-500 mt-1">Câu đạt trọn điểm</div></div>
            <div class="p-5"><div class="text-2xl font-black text-rose-500">${attempt.total_questions - attempt.correct_count}</div><div class="text-xs font-semibold text-slate-500 mt-1">Câu sai / Chưa trọn</div></div>
            <div class="p-5"><div class="text-2xl font-black text-indigo-600">${attempt.total_questions}</div><div class="text-xs font-semibold text-slate-500 mt-1">Tổng số câu</div></div>
            <div class="p-5"><div class="text-2xl font-black text-slate-800">${String(mins).padStart(2,'0')}:${String(secs).padStart(2,'0')}</div><div class="text-xs font-semibold text-slate-500 mt-1">Thời gian làm bài</div></div>
        </div>

        <div class="p-6 bg-slate-50/70 border-t border-slate-100 space-y-5">
            <div>
                <h3 class="text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-3"><i class="fa-solid fa-layer-group text-indigo-600"></i> Phân tích điểm theo cấu trúc đề thi mới 2026</h3>
                <div class="grid grid-cols-1 sm:grid-cols-3 gap-3">
                    ${Object.values(typeStats).filter(ts => ts.count > 0).map(ts => `
                        <div class="bg-white rounded-2xl p-3.5 border border-slate-200/80 flex items-center justify-between">
                            <div><div class="text-xs font-bold text-slate-700">${ts.label}</div><div class="text-[11px] text-slate-400">${ts.count} câu</div></div>
                            <span class="text-sm font-black text-indigo-600">${ts.earned.toFixed(2)} / ${ts.max.toFixed(2)}đ</span>
                        </div>`).join('')}
                </div>
            </div>
            <div>
                <h3 class="text-xs font-extrabold uppercase tracking-wider text-slate-500 mb-3">Phân tích theo 4 mức độ nhận thức</h3>
                <div class="grid grid-cols-2 sm:grid-cols-4 gap-3">
                    ${Object.entries(diffStats).map(([d, st]) => {
                        const pct = st.total > 0 ? Math.round((st.correct / st.total) * 100) : 0;
                        return `
                        <div class="bg-white rounded-2xl p-3.5 border border-slate-200/80">
                            <div class="flex items-center justify-between mb-1.5">
                                <span class="text-xs font-bold text-slate-700">${esc(d)}</span>
                                <span class="text-xs font-extrabold text-indigo-600">${st.correct}/${st.total}</span>
                            </div>
                            <div class="w-full bg-slate-100 h-1.5 rounded-full overflow-hidden"><div class="bg-indigo-600 h-full" style="width: ${pct}%"></div></div>
                        </div>`;
                    }).join('')}
                </div>
            </div>
        </div>
    </div>

    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-5">
        <h2 class="text-xl font-extrabold text-slate-900 flex items-center gap-2"><i class="fa-solid fa-magnifying-glass-chart text-indigo-600"></i> Xem Lại Đáp Án &amp; Lời Giải Chi Tiết</h2>
        <div class="flex flex-wrap items-center gap-2">
            <div class="inline-flex rounded-xl bg-white border border-slate-200 p-1 text-xs font-bold">
                <button onclick="filterReview('all')" id="rev-filter-all" class="px-3.5 py-2 rounded-lg bg-indigo-600 text-white transition">Tất cả (${rows.length})</button>
                <button onclick="filterReview('wrong')" id="rev-filter-wrong" class="px-3.5 py-2 rounded-lg text-slate-600 hover:text-indigo-600 transition">Chưa trọn điểm</button>
                <button onclick="filterReview('correct')" id="rev-filter-correct" class="px-3.5 py-2 rounded-lg text-slate-600 hover:text-indigo-600 transition">Đúng hoàn toàn</button>
            </div>
            <a href="take_exam.html?id=${attempt.exam_id}" class="px-4 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold transition">Làm lại đề này</a>
            <a href="index.html" class="px-4 py-2.5 rounded-xl bg-slate-200 hover:bg-slate-300 text-slate-800 text-xs font-bold transition">Về kho đề</a>
        </div>
    </div>
    <div class="space-y-4">${reviewHtml}</div>`;
}

// ==========================================================
// LỊCH SỬ LÀM BÀI (history.html)
// ==========================================================
async function initHistoryPage() {
    const user = getCurrentUser();
    if (!user) {
        setFlash('error', 'Vui lòng đăng nhập để xem lịch sử.');
        window.location.href = 'login.html';
        return;
    }
    const client = getSb();
    if (!client) return;

    const { data: attempts } = await client
        .from('exam_attempts')
        .select('*, exams(title, level, subjects(code, name))')
        .eq('user_id', user.id)
        .order('completed_at', { ascending: false });

    const list = attempts || [];
    const total = list.length;
    const avg = total > 0 ? (list.reduce((s, a) => s + parseFloat(a.score), 0) / total).toFixed(2) : '0.00';
    const best = total > 0 ? Math.max(...list.map(a => parseFloat(a.score))).toFixed(2) : '0.00';

    document.getElementById('historyContainer').innerHTML = `
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div>
            <h1 class="text-2xl font-extrabold text-slate-900">Lịch Sử Luyện Đề Của Bạn</h1>
            <p class="text-sm text-slate-500 mt-1">Theo dõi tiến độ và xem lại lời giải chi tiết từng bài đã làm.</p>
        </div>
        <a href="index.html" class="px-5 py-2.5 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-bold shadow-sm transition inline-flex items-center gap-2"><i class="fa-solid fa-plus"></i> Làm thêm đề mới</a>
    </div>

    <div class="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8">
        <div class="bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm"><div class="text-xs font-bold uppercase text-slate-400">Tổng lượt thi</div><div class="text-3xl font-black text-indigo-600 mt-1">${total}</div></div>
        <div class="bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm"><div class="text-xs font-bold uppercase text-slate-400">Điểm trung bình</div><div class="text-3xl font-black text-emerald-600 mt-1">${avg}</div></div>
        <div class="bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm"><div class="text-xs font-bold uppercase text-slate-400">Điểm cao nhất</div><div class="text-3xl font-black text-amber-500 mt-1">${best}</div></div>
    </div>

    <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
        ${total === 0 ? `
            <div class="p-12 text-center">
                <p class="text-slate-500 text-sm mb-4">Bạn chưa hoàn thành đề thi nào.</p>
                <a href="index.html" class="px-5 py-2.5 rounded-xl bg-indigo-600 text-white text-sm font-bold">Bắt đầu làm bài ngay</a>
            </div>` : `
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead>
                        <tr class="bg-slate-50 border-b border-slate-200/70 text-[11px] font-extrabold uppercase tracking-wider text-slate-500">
                            <th class="py-4 px-6">Môn học</th><th class="py-4 px-4">Đề thi</th><th class="py-4 px-4 text-center">Đúng / Tổng</th><th class="py-4 px-4 text-center">Điểm số</th><th class="py-4 px-4 text-center">Thời gian làm</th><th class="py-4 px-4">Ngày nộp</th><th class="py-4 px-6 text-right">Hành động</th>
                        </tr>
                    </thead>
                    <tbody class="divide-y divide-slate-100 text-sm">
                        ${list.map(row => {
                            const st = getSubjectBadgeStyle(row.exams?.subjects?.code || 'TOAN');
                            const m = Math.floor(row.time_spent_seconds / 60);
                            const s = row.time_spent_seconds % 60;
                            const sc = parseFloat(row.score);
                            return `
                            <tr class="hover:bg-slate-50/80 transition">
                                <td class="py-4 px-6"><span class="px-3 py-1 rounded-xl text-xs font-extrabold ${st.badge}">${esc(row.exams?.subjects?.name || '')}</span></td>
                                <td class="py-4 px-4"><div class="font-bold text-slate-800">${esc(row.exams?.title || '')}</div><div class="text-xs text-slate-400">${esc(row.exams?.level || '')}</div></td>
                                <td class="py-4 px-4 text-center font-bold text-slate-700">${row.correct_count} / ${row.total_questions}</td>
                                <td class="py-4 px-4 text-center"><span class="px-3 py-1 rounded-xl text-sm font-black ${sc >= 8 ? 'bg-emerald-100 text-emerald-800' : (sc >= 5 ? 'bg-blue-100 text-blue-800' : 'bg-rose-100 text-rose-800')}">${sc.toFixed(2)}</span></td>
                                <td class="py-4 px-4 text-center text-slate-600 font-medium">${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}</td>
                                <td class="py-4 px-4 text-slate-500 text-xs">${formatDateTimeVN(row.completed_at)}</td>
                                <td class="py-4 px-6 text-right"><a href="result.html?attempt_id=${row.id}" class="inline-flex items-center gap-1.5 px-3.5 py-2 rounded-xl bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold text-xs transition"><i class="fa-solid fa-eye"></i> Xem chi tiết</a></td>
                            </tr>`;
                        }).join('')}
                    </tbody>
                </table>
            </div>`}
    </div>`;
}

// ==========================================================
// QUẢN TRỊ ADMIN (admin.html) - KHÔNG CÓ TAB PHÂN QUYỀN, KHÔNG 4 Ô HEADER
// ==========================================================
let monitorAutoRefresh = true;
function toggleMonitorAutoRefresh() {
    monitorAutoRefresh = !monitorAutoRefresh;
    const btn = document.getElementById('toggleAutoRefreshBtn');
    if (!btn) return;
    if (monitorAutoRefresh) {
        btn.innerHTML = '<i class="fa-solid fa-pause mr-1"></i> Tạm dừng tự động';
        btn.className = 'px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition';
    } else {
        btn.innerHTML = '<i class="fa-solid fa-play mr-1"></i> Tiếp tục tự động';
        btn.className = 'px-3.5 py-2 rounded-xl bg-emerald-100 hover:bg-emerald-200 text-emerald-800 text-xs font-bold transition';
    }
}

function toggleAdminQuestionFields() {
    const type = document.getElementById('adminQType')?.value;
    if (!type) return;
    document.getElementById('adminMcqFields').classList.toggle('hidden', type !== 'mcq');
    document.getElementById('adminTfFields').classList.toggle('hidden', type !== 'true_false');
    document.getElementById('adminSaFields').classList.toggle('hidden', type !== 'short_answer');
    const pts = document.getElementById('adminQPoints');
    if (type === 'true_false') pts.value = '1.00';
    else if (type === 'mcq') pts.value = '0.25';
    else pts.value = '0.50';
}

async function adminDeleteExam(examId) {
    if (!confirm('Xóa đề thi này sẽ xóa toàn bộ câu hỏi và lịch sử thi liên quan. Tiếp tục?')) return;
    await getSb().from('exams').delete().eq('id', examId);
    setFlash('success', 'Đã xóa đề thi.');
    window.location.reload();
}

async function adminDeleteQuestion(qId, examId) {
    if (!confirm('Bạn có chắc muốn xóa câu hỏi này?')) return;
    await getSb().from('questions').delete().eq('id', qId);
    setFlash('success', 'Đã xóa câu hỏi.');
    window.location.href = `admin.html?tab=questions&exam_id=${examId}`;
}

async function initAdminPage() {
    const user = getCurrentUser();
    if (!user || user.role !== 'admin') {
        setFlash('error', 'Bạn cần đăng nhập tài khoản Quản trị viên (Admin) để truy cập.');
        window.location.href = 'login.html';
        return;
    }
    const client = getSb();
    if (!client) return;

    const tab = getQueryParam('tab') || 'exams';
    const threeMinAgo = new Date(Date.now() - 3 * 60 * 1000).toISOString();

    const [{ data: subjects }, { data: exams }, { data: liveSessions }] = await Promise.all([
        client.from('subjects').select('*').order('id'),
        client.from('exams').select('*, subjects(code, name)').order('subject_id').order('id'),
        client.from('exam_sessions').select('*').eq('status', 'in_progress').gte('last_heartbeat', threeMinAgo)
    ]);

    const subList = subjects || [];
    const examList = exams || [];
    const liveCount = (liveSessions || []).length;
    const manageExamId = Number(getQueryParam('exam_id')) || (examList[0]?.id || 0);

    let tabBodyHtml = '';

    if (tab === 'exams') {
        const { data: qAll } = await client.from('questions').select('exam_id');
        const qCountByExam = {};
        (qAll || []).forEach(q => { qCountByExam[q.exam_id] = (qCountByExam[q.exam_id] || 0) + 1; });

        tabBodyHtml = `
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            <div class="lg:col-span-4 bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm">
                <h2 class="text-lg font-extrabold text-slate-900 mb-4 flex items-center gap-2"><i class="fa-solid fa-plus-circle text-indigo-600"></i> Thêm Đề Thi Mới</h2>
                <form id="adminAddExamForm" class="space-y-4">
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Bộ môn *</label>
                        <select id="newExamSub" required class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm font-semibold outline-none focus:border-indigo-500">
                            ${subList.map(s => `<option value="${s.id}">${esc(s.name)}</option>`).join('')}
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Tên đề thi *</label>
                        <input type="text" id="newExamTitle" required placeholder="VD: Đề Thi Thử THPT 2026 - Đề Số 06" class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500">
                    </div>
                    <div class="grid grid-cols-2 gap-3">
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Thời gian (phút)</label>
                            <input type="number" id="newExamDur" value="50" min="5" max="180" required class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm font-bold outline-none focus:border-indigo-500">
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Mức độ</label>
                            <select id="newExamLevel" class="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm font-semibold outline-none focus:border-indigo-500">
                                <option value="Chuẩn THPT QG">Chuẩn THPT QG</option>
                                <option value="Cơ bản">Cơ bản</option>
                                <option value="Thông hiểu">Thông hiểu</option>
                                <option value="Vận dụng cao">Vận dụng cao</option>
                            </select>
                        </div>
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Mô tả chuyên đề</label>
                        <textarea id="newExamDesc" rows="3" placeholder="Mô tả nội dung trọng tâm của đề thi..." class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500"></textarea>
                    </div>
                    <button type="submit" class="w-full py-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-sm transition"><i class="fa-solid fa-check mr-1"></i> Lưu Đề Thi Mới</button>
                </form>
            </div>

            <div class="lg:col-span-8 bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-100 flex items-center justify-between"><h2 class="font-extrabold text-slate-800">Danh Sách Toàn Bộ Đề Thi (${examList.length})</h2></div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <thead><tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70"><th class="py-3.5 px-5">Môn</th><th class="py-3.5 px-4">Tên đề thi</th><th class="py-3.5 px-3 text-center">Câu hỏi</th><th class="py-3.5 px-3 text-center">Phút</th><th class="py-3.5 px-5 text-right">Thao tác</th></tr></thead>
                        <tbody class="divide-y divide-slate-100 text-sm">
                            ${examList.map(ex => {
                                const st = getSubjectBadgeStyle(ex.subjects?.code || 'TOAN');
                                return `
                                <tr class="hover:bg-slate-50/80 transition">
                                    <td class="py-3.5 px-5"><span class="px-2.5 py-1 rounded-lg text-xs font-extrabold ${st.badge}">${esc(ex.subjects?.name || '')}</span></td>
                                    <td class="py-3.5 px-4"><div class="font-bold text-slate-800">${esc(ex.title)}</div><div class="text-xs text-slate-400">${esc(ex.level)}</div></td>
                                    <td class="py-3.5 px-3 text-center font-bold text-indigo-600">${qCountByExam[ex.id] || 0}</td>
                                    <td class="py-3.5 px-3 text-center font-semibold text-slate-600">${ex.duration_minutes}'</td>
                                    <td class="py-3.5 px-5 text-right whitespace-nowrap">
                                        <a href="admin.html?tab=questions&exam_id=${ex.id}" class="inline-flex items-center gap-1 px-3 py-1.5 rounded-lg bg-indigo-50 hover:bg-indigo-100 text-indigo-700 font-bold text-xs mr-1">Soạn câu hỏi</a>
                                        <button onclick="adminDeleteExam(${ex.id})" class="px-2.5 py-1.5 rounded-lg bg-rose-50 hover:bg-rose-100 text-rose-600 text-xs font-bold"><i class="fa-solid fa-trash"></i></button>
                                    </td>
                                </tr>`;
                            }).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>`;
    } else if (tab === 'questions') {
        const { data: qRows } = await client.from('questions').select('*').eq('exam_id', manageExamId).order('sort_order').order('id');
        const examQs = qRows || [];
        tabBodyHtml = `
        <div class="bg-white rounded-2xl border border-slate-200/80 p-4 mb-6 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div class="flex items-center gap-3 flex-1">
                <label class="text-xs font-extrabold uppercase text-slate-500 shrink-0">Đang chọn đề:</label>
                <select onchange="window.location.href='admin.html?tab=questions&exam_id=' + this.value" class="flex-1 max-w-xl px-4 py-2 rounded-xl bg-slate-50 border border-slate-200 text-sm font-bold text-slate-800 outline-none focus:border-indigo-500">
                    ${examList.map(ex => `<option value="${ex.id}" ${ex.id === manageExamId ? 'selected' : ''}>[${esc(ex.subjects?.name || '')}] ${esc(ex.title)}</option>`).join('')}
                </select>
            </div>
            <span class="text-xs font-bold text-indigo-600 bg-indigo-50 px-3 py-2 rounded-xl">Hiện có: ${examQs.length} câu hỏi</span>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
            <div class="lg:col-span-5 bg-white rounded-3xl border border-slate-200/80 p-6 shadow-sm">
                <h2 class="text-lg font-extrabold text-slate-900 mb-4 flex items-center gap-2"><i class="fa-solid fa-circle-plus text-indigo-600"></i> Thêm Câu Hỏi Vào Đề</h2>
                <form id="adminAddQForm" class="space-y-3.5">
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Dạng câu hỏi 2026 *</label>
                        <select id="adminQType" onchange="toggleAdminQuestionFields()" class="w-full px-3 py-2.5 rounded-xl border border-slate-200 text-sm font-bold text-indigo-700 bg-indigo-50/40 outline-none focus:border-indigo-500">
                            <option value="mcq">Phần I: Trắc nghiệm ABCD</option>
                            <option value="true_false">Phần II: Đúng / Sai (4 ý a, b, c, d)</option>
                            <option value="short_answer">Phần III: Trả lời ngắn (Điền số)</option>
                        </select>
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Nội dung câu hỏi *</label>
                        <textarea id="adminQText" rows="3" required placeholder="Nhập đề bài câu hỏi..." class="w-full px-4 py-2.5 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500"></textarea>
                    </div>
                    <div id="adminMcqFields" class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                        <input type="text" id="qOptA" placeholder="Đáp án A *" class="px-3.5 py-2 rounded-xl border border-slate-200 text-sm">
                        <input type="text" id="qOptB" placeholder="Đáp án B *" class="px-3.5 py-2 rounded-xl border border-slate-200 text-sm">
                        <input type="text" id="qOptC" placeholder="Đáp án C *" class="px-3.5 py-2 rounded-xl border border-slate-200 text-sm">
                        <input type="text" id="qOptD" placeholder="Đáp án D *" class="px-3.5 py-2 rounded-xl border border-slate-200 text-sm">
                        <div class="sm:col-span-2">
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Đáp án đúng *</label>
                            <select id="qMcqCorrect" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm font-bold text-emerald-700"><option value="A">A</option><option value="B">B</option><option value="C">C</option><option value="D">D</option></select>
                        </div>
                    </div>
                    <div id="adminTfFields" class="hidden space-y-2.5 p-3.5 rounded-2xl bg-violet-50/60 border border-violet-200">
                        <div class="text-xs font-extrabold text-violet-800">Nhập 4 mệnh đề &amp; chọn Đúng (D) / Sai (S):</div>
                        ${['a', 'b', 'c', 'd'].map(k => `
                        <div class="flex items-center gap-2">
                            <input type="text" id="tfText_${k}" placeholder="${k}) Nội dung mệnh đề..." class="flex-1 px-3 py-2 rounded-xl border border-slate-200 bg-white text-xs">
                            <select id="tfVal_${k}" class="px-2.5 py-2 rounded-xl border border-slate-200 bg-white text-xs font-extrabold"><option value="D">Đúng</option><option value="S">Sai</option></select>
                        </div>`).join('')}
                    </div>
                    <div id="adminSaFields" class="hidden p-3.5 rounded-2xl bg-teal-50/60 border border-teal-200">
                        <label class="block text-xs font-extrabold text-teal-800 mb-1">Đáp án số chính xác *</label>
                        <input type="text" id="qSaCorrect" placeholder="VD: 12 hoặc 3.5" class="w-full px-3.5 py-2 rounded-xl border border-teal-300 bg-white text-sm font-bold">
                    </div>
                    <div class="grid grid-cols-2 gap-3">
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Điểm câu</label>
                            <select id="adminQPoints" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm font-bold"><option value="0.25">0.25 điểm</option><option value="0.50">0.50 điểm</option><option value="1.00">1.00 điểm</option></select>
                        </div>
                        <div>
                            <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Mức độ</label>
                            <select id="adminQDiff" class="w-full px-3 py-2 rounded-xl border border-slate-200 text-sm font-bold"><option value="Nhận biết">Nhận biết</option><option value="Thông hiểu">Thông hiểu</option><option value="Vận dụng">Vận dụng</option><option value="Vận dụng cao">Vận dụng cao</option></select>
                        </div>
                    </div>
                    <div>
                        <label class="block text-xs font-bold uppercase text-slate-600 mb-1">Hướng dẫn giải</label>
                        <textarea id="adminQExpl" rows="2" placeholder="Giải thích chi tiết..." class="w-full px-4 py-2 rounded-xl border border-slate-200 text-sm outline-none focus:border-indigo-500"></textarea>
                    </div>
                    <button type="submit" class="w-full py-3 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white font-bold text-sm shadow-sm transition"><i class="fa-solid fa-plus mr-1"></i> Thêm câu hỏi vào đề</button>
                </form>
            </div>

            <div class="lg:col-span-7 space-y-4">
                ${examQs.length === 0 ? `<div class="bg-white rounded-3xl border border-slate-200 p-10 text-center text-slate-500 text-sm">Đề thi này chưa có câu hỏi nào.</div>` : examQs.map((q, idx) => {
                    const ti = getQuestionTypeInfo(q.question_type || 'mcq');
                    return `
                    <div class="bg-white rounded-3xl border border-slate-200/80 p-5 shadow-sm">
                        <div class="flex items-start justify-between gap-3 mb-2">
                            <div class="flex flex-wrap items-center gap-2">
                                <span class="px-2.5 py-1 rounded-lg bg-slate-900 text-white text-xs font-extrabold">Câu ${idx + 1}</span>
                                <span class="px-2 py-0.5 rounded-lg text-[11px] font-bold border ${ti.badge}">${ti.short}</span>
                                <span class="px-2 py-0.5 rounded-lg text-[11px] font-bold border ${getDifficultyBadgeStyle(q.difficulty)}">${esc(q.difficulty)}</span>
                                <span class="px-2 py-0.5 rounded-lg text-[11px] font-bold bg-emerald-100 text-emerald-800">Đáp án: ${esc(q.correct_option)} (${Number(q.points_value).toFixed(2)}đ)</span>
                            </div>
                            <button onclick="adminDeleteQuestion(${q.id}, ${manageExamId})" class="text-rose-500 hover:text-rose-700 text-xs font-bold"><i class="fa-solid fa-trash"></i> Xóa</button>
                        </div>
                        <p class="text-sm font-bold text-slate-800 mb-2">${esc(q.question_text)}</p>
                    </div>`;
                }).join('')}
            </div>
        </div>`;
    } else if (tab === 'results') {
        const { data: attempts } = await client
            .from('exam_attempts')
            .select('*, users(fullname, username), exams(title, subjects(code, name))')
            .order('completed_at', { ascending: false });
        const list = attempts || [];

        tabBodyHtml = `
        <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
            <div class="px-6 py-4 border-b border-slate-100"><h2 class="font-extrabold text-slate-800">Bảng Điểm Luyện Đề &amp; Giám Sát Toàn Trường</h2></div>
            <div class="overflow-x-auto">
                <table class="w-full text-left border-collapse">
                    <thead><tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70"><th class="py-3.5 px-6">Học sinh</th><th class="py-3.5 px-4">Môn &amp; Đề thi</th><th class="py-3.5 px-4 text-center">Kết quả</th><th class="py-3.5 px-4 text-center">Thời gian làm</th><th class="py-3.5 px-4 text-center">Thoát màn hình</th><th class="py-3.5 px-4 text-center">Điểm số</th><th class="py-3.5 px-4">Thời gian nộp</th><th class="py-3.5 px-6 text-right">Chi tiết</th></tr></thead>
                    <tbody class="divide-y divide-slate-100 text-sm">
                        ${list.map(row => {
                            const st = getSubjectBadgeStyle(row.exams?.subjects?.code || 'TOAN');
                            const m = Math.floor(row.time_spent_seconds / 60);
                            const s = row.time_spent_seconds % 60;
                            const exits = Number(row.tab_switch_count || 0);
                            return `
                            <tr class="hover:bg-slate-50/80 transition">
                                <td class="py-4 px-6"><div class="font-bold text-slate-800">${esc(row.users?.fullname || '')}</div><div class="text-xs text-slate-400">@${esc(row.users?.username || '')}</div></td>
                                <td class="py-4 px-4"><span class="px-2 py-0.5 rounded-md text-[11px] font-extrabold ${st.badge} mr-1.5">${esc(row.exams?.subjects?.name || '')}</span><span class="font-bold text-slate-700">${esc(row.exams?.title || '')}</span></td>
                                <td class="py-4 px-4 text-center font-bold text-slate-600">${row.correct_count}/${row.total_questions}</td>
                                <td class="py-4 px-4 text-center font-bold text-slate-700">${String(m).padStart(2,'0')} phút ${String(s).padStart(2,'0')}s</td>
                                <td class="py-4 px-4 text-center"><span class="px-2.5 py-1 rounded-xl text-xs font-extrabold ${exits > 0 ? 'bg-rose-100 text-rose-700' : 'bg-emerald-100 text-emerald-700'}">${exits} lần</span></td>
                                <td class="py-4 px-4 text-center"><span class="px-3 py-1 rounded-xl text-sm font-black bg-indigo-100 text-indigo-800">${parseFloat(row.score).toFixed(2)}</span></td>
                                <td class="py-4 px-4 text-xs text-slate-500">${formatDateTimeVN(row.completed_at)}</td>
                                <td class="py-4 px-6 text-right"><a href="result.html?attempt_id=${row.id}" class="text-xs font-bold text-indigo-600 hover:underline">Xem bài làm</a></td>
                            </tr>`;
                        }).join('')}
                    </tbody>
                </table>
            </div>
        </div>`;
    } else if (tab === 'monitor') {
        const [{ data: sessions }, { data: allStudents }, { data: allAttempts }] = await Promise.all([
            client.from('exam_sessions').select('*, users(fullname, username), exams(title, duration_minutes, subjects(code, name))').order('started_at', { ascending: false }).limit(50),
            client.from('users').select('*').eq('role', 'student').order('last_active_at', { ascending: false }),
            client.from('exam_attempts').select('user_id, exam_id, score, time_spent_seconds, tab_switch_count, completed_at, exams(title)').order('completed_at', { ascending: false })
        ]);

        const sessList = sessions || [];
        const stuList = allStudents || [];
        const attList = allAttempts || [];
        const nowMs = Date.now();

        const liveSess = sessList.filter(s => s.status === 'in_progress' && (nowMs - new Date(s.last_heartbeat).getTime()) <= 180000);
        const attByUser = {};
        attList.forEach(a => { (attByUser[a.user_id] = attByUser[a.user_id] || []).push(a); });

        tabBodyHtml = `
        <div class="space-y-6">
            <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div>
                        <h2 class="font-extrabold text-slate-900 flex items-center gap-2"><span class="w-2.5 h-2.5 rounded-full bg-rose-500 animate-ping"></span> Học sinh đang làm bài trực tiếp (${liveSess.length})</h2>
                        <p class="text-xs text-slate-500 mt-0.5">Tự động cập nhật mỗi 10 giây • Phát hiện chuyển tab / thoát màn hình theo thời gian thực.</p>
                    </div>
                    <div class="flex items-center gap-2">
                        <button onclick="toggleMonitorAutoRefresh()" id="toggleAutoRefreshBtn" class="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-bold transition"><i class="fa-solid fa-pause mr-1"></i> Tạm dừng tự động</button>
                        <button onclick="window.location.reload()" class="px-3.5 py-2 rounded-xl bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold transition"><i class="fa-solid fa-rotate mr-1"></i> Làm mới</button>
                    </div>
                </div>
                ${liveSess.length === 0 ? `<div class="p-8 text-center text-slate-500 text-sm">Hiện tại không có học sinh nào đang làm bài thi trực tuyến.</div>` : `
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <thead><tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70"><th class="py-3.5 px-6">Học sinh</th><th class="py-3.5 px-4">Đang làm đề</th><th class="py-3.5 px-4 text-center">Tiến độ</th><th class="py-3.5 px-4 text-center">Đã làm (phút)</th><th class="py-3.5 px-4 text-center">Thoát màn hình</th></tr></thead>
                        <tbody class="divide-y divide-slate-100 text-sm">
                            ${liveSess.map(ls => {
                                const st = getSubjectBadgeStyle(ls.exams?.subjects?.code || 'TOAN');
                                const m = Math.floor(ls.elapsed_seconds / 60);
                                const s = ls.elapsed_seconds % 60;
                                const ex = Number(ls.tab_switch_count || 0);
                                return `
                                <tr class="hover:bg-slate-50/80 transition">
                                    <td class="py-4 px-6"><div class="font-bold text-slate-800">${esc(ls.users?.fullname || '')}</div><div class="text-xs text-slate-400">@${esc(ls.users?.username || '')}</div></td>
                                    <td class="py-4 px-4"><span class="px-2 py-0.5 rounded-md text-[11px] font-extrabold ${st.badge} mr-1.5">${esc(ls.exams?.subjects?.name || '')}</span><span class="font-bold text-slate-700">${esc(ls.exams?.title || '')}</span></td>
                                    <td class="py-4 px-4 text-center font-extrabold text-indigo-600">${ls.answered_count} / ${ls.total_questions} câu</td>
                                    <td class="py-4 px-4 text-center font-bold text-slate-700">${String(m).padStart(2,'0')}p ${String(s).padStart(2,'0')}s</td>
                                    <td class="py-4 px-4 text-center"><span class="px-3 py-1 rounded-xl text-xs font-extrabold ${ex > 0 ? 'bg-rose-100 text-rose-700' : 'bg-emerald-100 text-emerald-700'}">${ex} lần</span></td>
                                </tr>`;
                            }).join('')}
                        </tbody>
                    </table>
                </div>`}
            </div>

            <div class="bg-white rounded-3xl border border-slate-200/80 shadow-sm overflow-hidden">
                <div class="px-6 py-4 border-b border-slate-100"><h2 class="font-extrabold text-slate-900 flex items-center gap-2"><i class="fa-solid fa-users-viewfinder text-indigo-600"></i> Tình trạng hoạt động &amp; Lịch sử đề đã làm của từng Học sinh (${stuList.length})</h2></div>
                <div class="overflow-x-auto">
                    <table class="w-full text-left border-collapse">
                        <thead><tr class="bg-slate-50 text-[11px] font-extrabold uppercase text-slate-500 border-b border-slate-200/70"><th class="py-3.5 px-6">Học sinh</th><th class="py-3.5 px-4 text-center">Trạng thái</th><th class="py-3.5 px-4">Các đề đã làm</th><th class="py-3.5 px-4 text-center">Tổng thoát màn hình</th></tr></thead>
                        <tbody class="divide-y divide-slate-100 text-sm">
                            ${stuList.map(stu => {
                                const isOnline = stu.last_active_at && (nowMs - new Date(stu.last_active_at).getTime()) <= 300000;
                                const isInExam = liveSess.some(l => Number(l.user_id) === Number(stu.id));
                                const myAtts = attByUser[stu.id] || [];
                                const totalExits = myAtts.reduce((sum, a) => sum + Number(a.tab_switch_count || 0), 0);
                                return `
                                <tr class="hover:bg-slate-50/80 transition align-top">
                                    <td class="py-4 px-6"><div class="font-bold text-slate-800">${esc(stu.fullname)}</div><div class="text-xs text-slate-400">@${esc(stu.username)}</div></td>
                                    <td class="py-4 px-4 text-center">
                                        ${isInExam ? '<span class="px-2.5 py-1 rounded-full text-[11px] font-extrabold bg-rose-100 text-rose-700">Đang làm đề</span>'
                                            : (isOnline ? '<span class="px-2.5 py-1 rounded-full text-[11px] font-extrabold bg-emerald-100 text-emerald-700">Đang hoạt động</span>'
                                            : '<span class="px-2.5 py-1 rounded-full text-[11px] font-bold bg-slate-100 text-slate-500">Ngoại tuyến</span>')}
                                    </td>
                                    <td class="py-4 px-4">
                                        ${myAtts.length === 0 ? '<span class="text-xs text-slate-400 italic">Chưa làm đề nào</span>' : `<div class="space-y-1.5">` + myAtts.slice(0, 3).map(a => {
                                            const m = Math.floor(a.time_spent_seconds / 60);
                                            return `<div class="text-xs bg-slate-50 border border-slate-200/70 rounded-xl px-3 py-1.5 flex items-center justify-between gap-2"><span class="font-bold text-slate-700 truncate max-w-xs">${esc(a.exams?.title || '')}</span><span class="font-extrabold text-indigo-700 shrink-0">${parseFloat(a.score).toFixed(2)}đ • ${m}p • ${a.tab_switch_count} lần thoát</span></div>`;
                                        }).join('') + `</div>`}
                                    </td>
                                    <td class="py-4 px-4 text-center"><span class="px-3 py-1 rounded-xl text-xs font-extrabold ${totalExits > 0 ? 'bg-rose-100 text-rose-700' : 'bg-emerald-100 text-emerald-700'}">${totalExits} lần</span></td>
                                </tr>`;
                            }).join('')}
                        </tbody>
                    </table>
                </div>
            </div>
        </div>`;
    }

    document.getElementById('adminContainer').innerHTML = `
    <div class="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 rounded-3xl p-6 sm:p-8 text-white mb-8 shadow-lg">
        <span class="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-amber-500/20 border border-amber-400/30 text-amber-300 text-xs font-extrabold uppercase"><i class="fa-solid fa-user-shield"></i> Khu Vực Quản Trị Viên (Admin)</span>
        <h1 class="text-2xl sm:text-3xl font-extrabold mt-2">Quản Lý Kho Đề Toán • Anh • Lý • Hóa</h1>
        <p class="text-slate-300 text-xs sm:text-sm mt-1">Thêm đề thi mới, biên soạn câu hỏi trắc nghiệm và theo dõi bảng điểm, giám sát học sinh làm bài.</p>
    </div>

    <div class="flex flex-wrap items-center gap-2 mb-6 border-b border-slate-200 pb-3">
        <a href="admin.html?tab=exams" class="px-4 py-2.5 rounded-xl text-sm font-extrabold transition flex items-center gap-2 ${tab === 'exams' ? 'bg-indigo-600 text-white shadow-sm' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'}"><i class="fa-solid fa-folder-plus"></i> 1. Quản lý Đề thi</a>
        <a href="admin.html?tab=questions&exam_id=${manageExamId}" class="px-4 py-2.5 rounded-xl text-sm font-extrabold transition flex items-center gap-2 ${tab === 'questions' ? 'bg-indigo-600 text-white shadow-sm' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'}"><i class="fa-solid fa-list-check"></i> 2. Câu hỏi &amp; Đáp án</a>
        <a href="admin.html?tab=results" class="px-4 py-2.5 rounded-xl text-sm font-extrabold transition flex items-center gap-2 ${tab === 'results' ? 'bg-indigo-600 text-white shadow-sm' : 'bg-white text-slate-600 border border-slate-200 hover:bg-slate-50'}"><i class="fa-solid fa-square-poll-vertical"></i> 3. Bảng điểm</a>
        <a href="admin.html?tab=monitor" class="px-4 py-2.5 rounded-xl text-sm font-extrabold transition flex items-center gap-2 ${tab === 'monitor' ? 'bg-rose-600 text-white shadow-sm' : 'bg-rose-50 text-rose-700 border border-rose-200 hover:bg-rose-100'}">
            <i class="fa-solid fa-desktop"></i> 4. Giám sát Học sinh
            ${liveCount > 0 ? `<span class="px-2 py-0.5 rounded-full text-[11px] bg-white text-rose-600 font-black animate-pulse">${liveCount}</span>` : ''}
        </a>
    </div>
    ${tabBodyHtml}`;

    if (tab === 'exams') {
        document.getElementById('adminAddExamForm').addEventListener('submit', async e => {
            e.preventDefault();
            await client.from('exams').insert({
                subject_id: Number(document.getElementById('newExamSub').value),
                title: document.getElementById('newExamTitle').value.trim(),
                duration_minutes: Number(document.getElementById('newExamDur').value),
                level: document.getElementById('newExamLevel').value,
                description: document.getElementById('newExamDesc').value.trim()
            });
            setFlash('success', 'Đã thêm đề thi mới thành công!');
            window.location.reload();
        });
    } else if (tab === 'questions') {
        document.getElementById('adminAddQForm').addEventListener('submit', async e => {
            e.preventDefault();
            const qType = document.getElementById('adminQType').value;
            const qText = document.getElementById('adminQText').value.trim();
            let oa = null, ob = null, oc = null, od = null, corr = '';
            if (qType === 'true_false') {
                oa = document.getElementById('tfText_a').value.trim();
                ob = document.getElementById('tfText_b').value.trim();
                oc = document.getElementById('tfText_c').value.trim();
                od = document.getElementById('tfText_d').value.trim();
                corr = ['a', 'b', 'c', 'd'].map(k => document.getElementById(`tfVal_${k}`).value).join(',');
            } else if (qType === 'short_answer') {
                corr = document.getElementById('qSaCorrect').value.trim();
            } else {
                oa = document.getElementById('qOptA').value.trim();
                ob = document.getElementById('qOptB').value.trim();
                oc = document.getElementById('qOptC').value.trim();
                od = document.getElementById('qOptD').value.trim();
                corr = document.getElementById('qMcqCorrect').value;
            }
            const { data: maxSort } = await client.from('questions').select('sort_order').eq('exam_id', manageExamId).order('sort_order', { ascending: false }).limit(1);
            const nextOrder = (maxSort && maxSort[0] ? maxSort[0].sort_order : 0) + 1;
            await client.from('questions').insert({
                exam_id: manageExamId,
                question_type: qType,
                question_text: qText,
                option_a: oa, option_b: ob, option_c: oc, option_d: od,
                correct_option: corr,
                explanation: document.getElementById('adminQExpl').value.trim(),
                points_value: parseFloat(document.getElementById('adminQPoints').value),
                difficulty: document.getElementById('adminQDiff').value,
                sort_order: nextOrder
            });
            setFlash('success', 'Đã thêm câu hỏi chuẩn 2026 mới vào đề thi!');
            window.location.href = `admin.html?tab=questions&exam_id=${manageExamId}`;
        });
    } else if (tab === 'monitor') {
        setInterval(() => { if (monitorAutoRefresh) window.location.reload(); }, 10000);
    }
}

// ==========================================================
// KHỞI CHẠY THEO TRANG
// ==========================================================
document.addEventListener('DOMContentLoaded', async () => {
    renderHeader();
    renderFlash();
    renderFooter();

    const user = getCurrentUser();
    const client = getSb();
    if (user && client) {
        client.from('users').update({ last_active_at: new Date().toISOString() }).eq('id', user.id).then(() => {});
    }

    const page = document.body.getAttribute('data-page');
    if (page === 'index') await initIndexPage();
    else if (page === 'login') initLoginPage();
    else if (page === 'register') initRegisterPage();
    else if (page === 'take_exam') await initTakeExamPage();
    else if (page === 'result') await initResultPage();
    else if (page === 'history') await initHistoryPage();
    else if (page === 'admin') await initAdminPage();
});
