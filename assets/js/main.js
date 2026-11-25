/* EduSmart Luyện Đề - Main JavaScript */

// 1. Cấu hình Tailwind CSS (chạy ngay khi tải trong <head>)
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

// ==========================================================
// 2. CHỨC NĂNG TRANG QUẢN TRỊ (admin.php)
// ==========================================================
function toggleAdminQuestionFields() {
    const typeEl = document.getElementById('adminQType');
    if (!typeEl) return;
    const type = typeEl.value;
    const mcqBox = document.getElementById('adminMcqFields');
    const tfBox = document.getElementById('adminTfFields');
    const saBox = document.getElementById('adminSaFields');
    const ptsSel = document.getElementById('adminQPoints');

    mcqBox.classList.toggle('hidden', type !== 'mcq');
    tfBox.classList.toggle('hidden', type !== 'true_false');
    saBox.classList.toggle('hidden', type !== 'short_answer');

    document.querySelectorAll('.mcq-req').forEach(el => { el.required = (type === 'mcq'); });
    document.querySelectorAll('.tf-req').forEach(el => { el.required = (type === 'true_false'); });
    document.querySelectorAll('.sa-req').forEach(el => { el.required = (type === 'short_answer'); });

    if (type === 'true_false') ptsSel.value = '1.00';
    else if (type === 'mcq') ptsSel.value = '0.25';
    else ptsSel.value = '0.50';
}

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

// ==========================================================
// 3. CHỨC NĂNG TRANG XEM KẾT QUẢ (result.php)
// ==========================================================
function filterReview(type) {
    ['all', 'wrong', 'correct'].forEach(t => {
        const btn = document.getElementById('rev-filter-' + t);
        if (!btn) return;
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

// ==========================================================
// 4. CHỨC NĂNG PHÒNG THI & GIÁM SÁT (take_exam.php)
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

function renderPaletteButton(qNum) {
    const btn = document.getElementById('palette-btn-' + qNum);
    if (!btn) return;
    const st = answeredState[qNum];
    const isDone = st && st.done;
    const isPartial = st && !st.done && st.label;
    const isFlagged = !!flaggedMap[qNum];

    btn.textContent = (st && st.label) ? (qNum + '.' + st.label) : String(qNum);

    if (isFlagged && isDone) {
        btn.className = 'palette-item h-9 rounded-xl border-2 border-amber-400 bg-indigo-600 text-white font-extrabold text-[11px] transition flex items-center justify-center shadow-sm ring-2 ring-amber-300/60';
    } else if (isFlagged) {
        btn.className = 'palette-item h-9 rounded-xl border-2 border-amber-400 bg-amber-100 text-amber-900 font-extrabold text-[11px] transition flex items-center justify-center';
    } else if (isDone) {
        btn.className = 'palette-item h-9 rounded-xl border-2 border-indigo-600 bg-indigo-600 text-white font-extrabold text-[11px] transition flex items-center justify-center shadow-sm';
    } else if (isPartial) {
        btn.className = 'palette-item h-9 rounded-xl border-2 border-violet-400 bg-violet-50 text-violet-800 font-extrabold text-[11px] transition flex items-center justify-center';
    } else {
        btn.className = 'palette-item h-9 rounded-xl border border-slate-200 bg-slate-50 text-slate-700 font-extrabold text-[11px] hover:border-indigo-400 transition flex items-center justify-center';
    }
}

function getDoneCount() {
    let doneCount = 0;
    Object.values(answeredState).forEach(st => {
        if (st && st.done) doneCount++;
    });
    return doneCount;
}

function updateOverallProgress() {
    const doneCount = getDoneCount();
    const countEl = document.getElementById('answeredCount');
    const barEl = document.getElementById('progressBar');
    if (countEl) countEl.textContent = doneCount;
    if (barEl && totalQuestions > 0) {
        const percent = Math.round((doneCount / totalQuestions) * 100);
        barEl.style.width = percent + '%';
    }
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
        if (!b) return;
        if (t === type) {
            b.className = 'py-1.5 rounded-lg bg-white text-indigo-700 shadow-sm transition';
        } else {
            b.className = 'py-1.5 rounded-lg text-slate-600 hover:text-slate-900 transition';
        }
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
        if (flaggedTotal > 0) {
            badge.textContent = flaggedTotal + ' đánh dấu';
            badge.classList.remove('hidden');
        } else {
            badge.classList.add('hidden');
        }
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
            if (badge) {
                badge.classList.remove('bg-indigo-600', 'text-white');
                badge.classList.add('bg-slate-100', 'text-slate-700');
            }
        });
    }

    const activeCard = radioInput.closest('.option-card');
    if (activeCard) {
        activeCard.classList.remove('border-slate-200/80');
        activeCard.classList.add('border-indigo-600', 'bg-indigo-50/80', 'ring-2', 'ring-indigo-500/20');
        const activeBadge = activeCard.querySelector('.option-letter');
        if (activeBadge) {
            activeBadge.classList.remove('bg-slate-100', 'text-slate-700');
            activeBadge.classList.add('bg-indigo-600', 'text-white');
        }
    }

    const statusBadge = document.getElementById('status-badge-' + qNum);
    if (statusBadge) {
        statusBadge.textContent = 'Đã chọn ' + letter;
        statusBadge.className = 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-emerald-100 text-emerald-700';
    }

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
        if (val === 'D') {
            activeLbl.className = 'tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-emerald-600 bg-emerald-600 text-white text-xs font-extrabold shadow-sm transition';
        } else {
            activeLbl.className = 'tf-label inline-flex items-center gap-1.5 px-4 py-2 rounded-xl border-2 border-rose-600 bg-rose-600 text-white text-xs font-extrabold shadow-sm transition';
        }
    }

    const countDone = Object.keys(tfSubAnswers[qNum]).length;
    const isFull = (countDone === 4);
    answeredState[qNum] = { label: countDone + '/4', done: isFull };

    const statusBadge = document.getElementById('status-badge-' + qNum);
    if (statusBadge) {
        if (isFull) {
            statusBadge.textContent = 'Đủ 4/4 ý';
            statusBadge.className = 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-emerald-100 text-emerald-700';
        } else {
            statusBadge.textContent = 'Đã chọn ' + countDone + '/4 ý';
            statusBadge.className = 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-violet-100 text-violet-700';
        }
    }

    renderPaletteButton(qNum);
    applyPaletteFilter();
    updateOverallProgress();
}

function handleShortAnswer(qNum, value) {
    const trimmed = value.trim();
    const hasVal = trimmed.length > 0;
    answeredState[qNum] = hasVal ? { label: '✓', done: true } : { label: '', done: false };

    const statusBadge = document.getElementById('status-badge-' + qNum);
    if (statusBadge) {
        if (hasVal) {
            statusBadge.textContent = 'Đã điền: ' + trimmed;
            statusBadge.className = 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-emerald-100 text-emerald-700';
        } else {
            statusBadge.textContent = 'Chưa làm';
            statusBadge.className = 'px-2.5 py-1 rounded-lg text-[11px] font-bold bg-slate-100 text-slate-500';
        }
    }

    renderPaletteButton(qNum);
    applyPaletteFilter();
    updateOverallProgress();
}

function scrollToQuestion(qNum) {
    const el = document.getElementById('question-block-' + qNum);
    if (el) {
        el.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }
}

function sendHeartbeat() {
    if (isSubmittingExam || examSessionId <= 0) return;
    fetch('exam_heartbeat.php', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
            session_id: examSessionId,
            elapsed_seconds: elapsedSeconds,
            answered_count: getDoneCount(),
            tab_switch_count: tabSwitchCount
        })
    }).catch(() => {});
}

function recordScreenExit() {
    if (isConfirmingDialog || isSubmittingExam || examSessionId <= 0) return;
    const now = Date.now();
    if (now - lastExitTimestamp < 1200) return;
    lastExitTimestamp = now;

    tabSwitchCount++;
    const tabInput = document.getElementById('tabSwitchInput');
    const badgeCount = document.getElementById('tabSwitchBadgeCount');
    const badge = document.getElementById('proctorBadge');
    const banner = document.getElementById('proctorAlertBanner');
    const alertText = document.getElementById('proctorAlertText');

    if (tabInput) tabInput.value = tabSwitchCount;
    if (badgeCount) badgeCount.textContent = tabSwitchCount;
    if (badge) {
        badge.className = 'px-3 py-2 rounded-xl bg-rose-50 text-rose-700 border border-rose-300 text-xs font-extrabold flex items-center gap-1.5 animate-pulse';
    }
    if (banner && alertText) {
        alertText.textContent =
            'Cảnh báo giám sát: Bạn vừa thoát khỏi màn hình làm bài (Lần thứ ' + tabSwitchCount + '). Thông tin này đã được ghi nhận!';
        banner.classList.remove('hidden');
    }

    sendHeartbeat();
}

function confirmExitExam() {
    isConfirmingDialog = true;
    const ok = confirm('Bạn có chắc muốn thoát khỏi phòng thi? Kết quả chưa nộp sẽ không được lưu.');
    setTimeout(() => { isConfirmingDialog = false; }, 300);
    return ok;
}

function confirmSubmitExam() {
    isConfirmingDialog = true;
    const unanswered = totalQuestions - getDoneCount();
    let msg = 'Bạn có chắc chắn muốn nộp bài và chấm điểm ngay?';
    if (unanswered > 0) {
        msg = 'Bạn còn ' + unanswered + ' câu hỏi chưa hoàn thành đầy đủ. Bạn vẫn muốn nộp bài chứ?';
    }
    const ok = confirm(msg);
    setTimeout(() => { isConfirmingDialog = false; }, 300);
    if (ok) {
        isSubmittingExam = true;
        document.getElementById('timeSpentInput').value = Math.max(1, elapsedSeconds);
        document.getElementById('tabSwitchInput').value = tabSwitchCount;
        document.getElementById('examForm').submit();
    }
}

// Khởi tạo các bộ đếm sau khi DOM tải xong
document.addEventListener('DOMContentLoaded', () => {
    // Auto-refresh trang Giám sát Admin (nếu đang ở tab monitor)
    if (document.getElementById('toggleAutoRefreshBtn')) {
        setInterval(() => {
            if (monitorAutoRefresh) {
                window.location.reload();
            }
        }, 10000);
    }

    // Khởi tạo phòng thi (nếu đang ở take_exam.php)
    if (window.EXAM_CONFIG && document.getElementById('examForm')) {
        totalQuestions = window.EXAM_CONFIG.totalQuestions || 0;
        totalSeconds = window.EXAM_CONFIG.totalSeconds || 0;
        remainingSeconds = totalSeconds;
        examSessionId = window.EXAM_CONFIG.examSessionId || 0;

        document.addEventListener('visibilitychange', () => {
            if (document.hidden) {
                recordScreenExit();
            }
        });

        window.addEventListener('blur', () => {
            recordScreenExit();
        });

        sendHeartbeat();
        setInterval(sendHeartbeat, 10000);

        const timerEl = document.getElementById('countdownTimer');
        timerInterval = setInterval(() => {
            elapsedSeconds++;
            remainingSeconds--;
            const timeInput = document.getElementById('timeSpentInput');
            if (timeInput) timeInput.value = elapsedSeconds;

            if (remainingSeconds <= 0) {
                clearInterval(timerInterval);
                isConfirmingDialog = true;
                isSubmittingExam = true;
                alert('Đã hết thời gian làm bài! Hệ thống sẽ tự động nộp bài của bạn.');
                document.getElementById('examForm').submit();
                return;
            }

            if (timerEl) {
                const mins = Math.floor(remainingSeconds / 60);
                const secs = remainingSeconds % 60;
                timerEl.textContent = String(mins).padStart(2, '0') + ':' + String(secs).padStart(2, '0');

                if (remainingSeconds <= 300) {
                    timerEl.classList.remove('text-amber-300');
                    timerEl.classList.add('text-rose-400', 'animate-pulse');
                }
            }
        }, 1000);
    }
});
