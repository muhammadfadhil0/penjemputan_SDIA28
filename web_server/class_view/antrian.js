/**
 * Antrian Queue Management Module for Class View
 * This module handles queue functionality similar to index.html but filtered by class
 */

// Queue state variables
let queue = [];
let queueStudents = [];
let queueCalledCount = 0;
let selectedStudent = null;
let isEmergencyActive = false;
let emergencyPollInterval = null;

// Authority from shared setting (index | kelas)
if (!window.callAuthority) {
    window.callAuthority = 'index';
}

function isClassAuthorityActive() {
    return window.callAuthority === 'kelas';
}

// Auto-calling state
let isAutoCallingActive = false;
let isPaused = false;
let isSpeaking = false;
let countdownValue = 5;
let countdownInterval = null;
const COUNTDOWN_START = 5;

// VoiceRSS API Configuration
const VOICERSS_API_KEY = '9895e2680ecf4ffa922e55df81cf271e';
let currentAudio = null;

// Bell sound
let bellSound = null;
try {
    bellSound = new Audio('../assets/bell, in.MP3');
} catch (e) {
    console.warn('Bell sound not available');
}

// Default announcement structure
const defaultAnnouncementBlocks = [
    { type: 'nama_siswa', label: 'Nama Siswa' },
    { type: 'text', value: ', ' },
    { type: 'kelas', label: 'Kelas' },
    { type: 'text', value: ', silakan menuju lobby, ditunggu oleh ' },
    { type: 'dijemput_oleh', label: 'Dijemput Oleh' }
];

function formatEmergencyTime(ts) {
    if (!ts) return '';
    try {
        const dt = new Date(ts.replace(' ', 'T'));
        const days = ['Minggu', 'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu'];
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        const h = dt.getHours().toString().padStart(2, '0');
        const m = dt.getMinutes().toString().padStart(2, '0');
        return `${days[dt.getDay()]}, ${dt.getDate()} ${months[dt.getMonth()]} ${dt.getFullYear()}, ${h}:${m}`;
    } catch (e) {
        return ts;
    }
}

function applyEmergencyState(active, details = {}) {
    const overlay = document.getElementById('emergencyOverlay');
    const byEl = document.getElementById('emergencyActivatedBy');
    const atEl = document.getElementById('emergencyActivatedAt');

    isEmergencyActive = !!active;

    if (!overlay) return;

    if (isEmergencyActive) {
        document.body.classList.add('emergency-blur');
        overlay.classList.remove('hidden');

        if (byEl) {
            const by = details.activated_by || 'Guru';
            byEl.textContent = `${by} telah mengaktifkan mode ini.`;
        }
        if (atEl) {
            const ts = formatEmergencyTime(details.activated_at);
            atEl.textContent = ts || '';
        }

        stopAutoCalling();
        if (countdownInterval) {
            clearInterval(countdownInterval);
            countdownInterval = null;
        }
    } else {
        document.body.classList.remove('emergency-blur');
        overlay.classList.add('hidden');
    }
}

async function pollEmergencyMode() {
    try {
        const res = await fetch('../service/config/emergency_mode.php');
        const data = await res.json();
        const status = data?.data || {};
        applyEmergencyState(status.active === true, status);
    } catch (e) {
        console.error('Emergency mode check failed', e);
    }
}

function startEmergencyPolling() {
    pollEmergencyMode();
    if (emergencyPollInterval) clearInterval(emergencyPollInterval);
    emergencyPollInterval = setInterval(pollEmergencyMode, 5000);
}

// Fetch queue from API (filtered by class)
async function fetchQueue(withAnimation = true) {
    if (!kelasId) return;

    const previousQueueLength = queue.length;

    try {
        const response = await fetch(`${API_BASE}/get_class_pickup_queue.php?kelas_id=${kelasId}`);
        const data = await response.json();

        if (data.emergency_mode) {
            applyEmergencyState(data.emergency_mode.active === true, data.emergency_mode);
        }

        if (isEmergencyActive) {
            queue = [];
            queueCalledCount = 0;
            updateQueueList(false);
            updateQueueStats();
            return;
        }

        if (data.success) {
            queue = data.queue.map(item => ({
                id: item.id,
                name: item.nama_siswa,
                class: item.nama_kelas,
                pickupBy: item.penjemput,
                status: item.status,
                fotoUrl: item.foto_url
            }));

            queueCalledCount = data.stats.called;
            queueStudents = data.students || [];

            updateQueueList(withAnimation);
            updateQueueStats();
            populateStudentDropdown();

            if (isAutoCallingActive && !isPaused && !isSpeaking) {
                if (previousQueueLength === 0 && queue.length > 0) {
                    countdownValue = COUNTDOWN_START;
                    startCountdown();
                    showToast('Siswa baru masuk - memulai countdown!');
                }
                updateCountdownUI();
            }
        }
    } catch (error) {
        console.error('Error fetching queue:', error);
    }
}

// Update queue list UI
function updateQueueList(withAnimation = true) {
    const queueList = document.getElementById('queueList');
    if (!queueList) return;

    queueList.innerHTML = queue.map((item, index) => `
        <div class="flex items-center gap-4 p-4 bg-bgMain rounded-xl border border-borderColor hover:border-primaryLight transition-all ${withAnimation ? 'slide-in' : ''}" ${withAnimation ? `style="animation-delay: ${index * 0.05}s"` : ''}>
            <div class="w-10 h-10 rounded-full bg-primaryLighter flex items-center justify-center overflow-hidden border-2 border-primaryLight">
                ${item.fotoUrl
            ? `<img src="${item.fotoUrl}" alt="${item.name}" class="w-full h-full object-cover" onerror="this.parentElement.innerHTML='<span class=\\'font-semibold text-primary\\'>${index + 1}</span>'">`
            : `<span class="font-semibold text-primary">${index + 1}</span>`
        }
            </div>
            <div class="flex-1">
                <p class="font-medium text-textPrimary">${item.name}</p>
                <p class="text-sm text-textMuted">${item.class} • Dijemput: ${item.pickupBy}</p>
            </div>
            <button onclick="removeFromQueue(${index})" class="p-2 text-textMuted hover:text-red-500 hover:bg-red-50 rounded-lg transition-colors">
                <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
                </svg>
            </button>
        </div>
    `).join('');

    const countEl = document.getElementById('queueListCount');
    if (countEl) countEl.textContent = `${queue.length} siswa menunggu`;

    // Update current queue display
    const currentPhotoEl = document.getElementById('currentStudentPhoto');
    const nameEl = document.getElementById('currentStudentName');
    const classEl = document.getElementById('currentStudentClass');
    const pickupEl = document.getElementById('currentPickupBy');

    if (queue.length > 0) {
        if (nameEl) nameEl.textContent = queue[0].name;
        if (classEl) classEl.textContent = queue[0].class;
        if (pickupEl) pickupEl.textContent = queue[0].pickupBy;
        if (currentPhotoEl) {
            if (queue[0].fotoUrl) {
                currentPhotoEl.innerHTML = `<img src="${queue[0].fotoUrl}" alt="${queue[0].name}" class="w-full h-full object-cover">`;
            } else {
                currentPhotoEl.innerHTML = `<svg class="w-10 h-10 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>`;
            }
        }
    } else {
        if (nameEl) nameEl.textContent = '-';
        if (classEl) classEl.textContent = '-';
        if (pickupEl) pickupEl.textContent = '-';
        if (currentPhotoEl) currentPhotoEl.innerHTML = `<svg class="w-10 h-10 text-primary" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" /></svg>`;
    }
}

// Update stats
function updateQueueStats() {
    const waitingEl = document.getElementById('waitingCount');
    const calledEl = document.getElementById('calledCount');
    const totalEl = document.getElementById('totalCount');

    if (waitingEl) waitingEl.textContent = queue.length;
    if (calledEl) calledEl.textContent = queueCalledCount;
    if (totalEl) totalEl.textContent = queue.length + queueCalledCount;
}

// Populate student dropdown (filtered by class)
function populateStudentDropdown() {
    const dropdown = document.getElementById('studentDropdown');
    if (!dropdown) return;

    dropdown.innerHTML = queueStudents.map(student => `
        <div class="px-4 py-3 hover:bg-primaryLighter cursor-pointer border-b border-borderColor last:border-0 transition-colors"
            onclick="selectStudent(${student.id}, '${student.name.replace(/'/g, "\\'")}', '${student.class.replace(/'/g, "\\'")}')">
            <p class="font-medium text-textPrimary">${student.name}</p>
            <p class="text-sm text-textMuted">${student.class}</p>
        </div>
    `).join('');
}

// Show student dropdown
function showStudentDropdown() {
    const dropdown = document.getElementById('studentDropdown');
    if (dropdown) dropdown.classList.remove('hidden');
}

// Select student from dropdown
function selectStudent(id, name, className) {
    const nameInput = document.getElementById('inputStudentName');
    const classInput = document.getElementById('inputClass');
    const dropdown = document.getElementById('studentDropdown');

    if (nameInput) nameInput.value = name;
    if (classInput) classInput.value = className;
    if (dropdown) dropdown.classList.add('hidden');
    selectedStudent = { id, name, class: className };
}

// Add to queue via API
async function addToQueue() {
    const name = document.getElementById('inputStudentName')?.value;
    const className = document.getElementById('inputClass')?.value;
    const pickupBy = document.getElementById('inputPickupBy')?.value;

    if (!name || !className || !pickupBy) {
        showToast('Mohon lengkapi semua data!', 'error');
        return;
    }

    if (!selectedStudent || !selectedStudent.id) {
        showToast('Pilih siswa dari daftar!', 'error');
        return;
    }

    try {
        const response = await fetch('../service/pickup/add_pickup_request.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({
                siswa_id: selectedStudent.id,
                penjemput: pickupBy.toLowerCase(),
                estimasi_waktu: 'tiba'
            })
        });

        const data = await response.json();

        if (data.success) {
            document.getElementById('inputStudentName').value = '';
            document.getElementById('inputClass').value = '';
            document.getElementById('inputPickupBy').value = '';
            selectedStudent = null;

            showToast(`${name} ditambahkan ke antrean! Nomor: ${data.data.nomor_antrian}`);
            await fetchQueue();
        } else {
            showToast(data.message || 'Gagal menambahkan ke antrean', 'error');
        }
    } catch (error) {
        console.error('Error adding to queue:', error);
        showToast('Gagal terhubung ke server', 'error');
    }
}

// Remove from queue via API
async function removeFromQueue(index) {
    const item = queue[index];
    if (!item || !item.id) return;

    try {
        const response = await fetch('../service/pickup/update_pickup_status.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ request_id: item.id, status: 'dibatalkan' })
        });

        const data = await response.json();
        if (data.success) {
            showToast(`${item.name} dihapus dari antrean!`);
            await fetchQueue();
        } else {
            showToast(data.message || 'Gagal menghapus dari antrean', 'error');
        }
    } catch (error) {
        console.error('Error removing from queue:', error);
        showToast('Gagal terhubung ke server', 'error');
    }
}

// Auto-calling functions
function updateCountdownUI() {
    const countdownDisplay = document.getElementById('countdownDisplay');
    const pausedButtons = document.getElementById('pausedButtons');
    const stoppedState = document.getElementById('stoppedState');
    const statusText = document.getElementById('callingStatusText');
    const statusDiv = document.getElementById('callingStatus');

    if (!countdownDisplay || !pausedButtons || !stoppedState) return;

    countdownDisplay.classList.add('hidden');
    pausedButtons.classList.add('hidden');
    stoppedState.classList.add('hidden');

    if (!isClassAuthorityActive()) {
        stoppedState.classList.remove('hidden');
        stoppedState.classList.add('flex');
        if (statusDiv) statusDiv.className = 'mt-4 p-3 bg-blue-50 border border-blue-200 rounded-xl text-center';
        if (statusText) statusText.textContent = '🚦 Pemanggilan diterapkan di Komputer Kurikulum';
        return;
    }

    if (!isAutoCallingActive) {
        stoppedState.classList.remove('hidden');
        stoppedState.classList.add('flex');
        if (statusDiv) statusDiv.className = 'mt-4 p-3 bg-gray-50 border border-gray-200 rounded-xl text-center';
        if (statusText) statusText.textContent = 'Pemanggilan otomatis tidak aktif';
    } else if (isPaused) {
        pausedButtons.classList.remove('hidden');
        pausedButtons.classList.add('flex');
        if (statusDiv) statusDiv.className = 'mt-4 p-3 bg-yellow-50 border border-yellow-200 rounded-xl text-center';
        if (statusText) statusText.textContent = 'Pemanggilan dijeda';
    } else if (queue.length === 0) {
        stoppedState.classList.remove('hidden');
        stoppedState.classList.add('flex');
        if (statusDiv) statusDiv.className = 'mt-4 p-3 bg-blue-50 border border-blue-200 rounded-xl text-center';
        if (statusText) statusText.textContent = 'Menunggu siswa masuk antrean...';
    } else {
        countdownDisplay.classList.remove('hidden');
        const countdownNumber = document.getElementById('countdownNumber');
        if (countdownNumber) countdownNumber.textContent = countdownValue;
        if (statusDiv) statusDiv.className = 'mt-4 p-3 bg-green-50 border border-green-200 rounded-xl text-center';
        if (statusText) statusText.textContent = 'Pemanggilan otomatis aktif';
    }
}

function startAutoCalling() {
    if (!isClassAuthorityActive()) {
        showToast('Pemanggilan diterapkan di Komputer Kurikulum', 'error');
        return;
    }
    isAutoCallingActive = true;
    isPaused = false;

    if (queue.length > 0) {
        countdownValue = COUNTDOWN_START;
        startCountdown();
        showToast('Pemanggilan otomatis dimulai!');
    } else {
        showToast('Pemanggilan aktif - menunggu siswa masuk antrean...');
    }
    updateCountdownUI();
    updateToggleButton();
}

function stopAutoCalling() {
    isAutoCallingActive = false;
    isPaused = false;
    if (countdownInterval) {
        clearInterval(countdownInterval);
        countdownInterval = null;
    }
    updateCountdownUI();
    updateToggleButton();
    showToast('Pemanggilan otomatis dihentikan!');
}

function toggleAutoCalling() {
    if (!isClassAuthorityActive()) {
        showToast('Pemanggilan diterapkan di Komputer Kurikulum', 'error');
        return;
    }
    if (isAutoCallingActive) {
        stopAutoCalling();
    } else {
        startAutoCalling();
    }
}

function updateToggleButton() {
    const btn = document.getElementById('btnToggleCalling');
    const icon = document.getElementById('iconToggleCalling');
    const text = document.getElementById('textToggleCalling');

    if (!btn || !icon || !text) return;

    if (isAutoCallingActive) {
        btn.className = 'w-full bg-red-50 hover:bg-red-100 border-2 border-red-200 hover:border-red-400 text-red-600 py-3.5 rounded-xl font-semibold flex items-center justify-center gap-3 transition-all';
        icon.innerHTML = '<rect x="6" y="6" width="12" height="12" rx="2" />';
        icon.setAttribute('fill', 'currentColor');
        icon.removeAttribute('stroke');
        text.textContent = 'Hentikan Pemanggilan';
    } else {
        btn.className = 'w-full bg-success hover:bg-green-600 text-white py-3.5 rounded-xl font-semibold flex items-center justify-center gap-3 transition-all shadow-lg';
        icon.innerHTML = `<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" /><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />`;
        icon.removeAttribute('fill');
        icon.setAttribute('stroke', 'currentColor');
        text.textContent = 'Mulai Pemanggilan';
    }
}

function startCountdown() {
    if (!isClassAuthorityActive()) return;
    if (countdownInterval) clearInterval(countdownInterval);

    countdownInterval = setInterval(() => {
        if (!isAutoCallingActive || isPaused || isSpeaking) return;

        countdownValue--;
        const countdownNumber = document.getElementById('countdownNumber');
        if (countdownNumber) countdownNumber.textContent = countdownValue;

        if (countdownValue <= 0) {
            callStudent();
        }
    }, 1000);
}

function pauseCountdown() {
    isPaused = true;
    updateCountdownUI();
    showToast('Pemanggilan dijeda');
}

function resumeCountdown() {
    isPaused = false;
    updateCountdownUI();
    showToast('Melanjutkan pemanggilan...');
}

function skipStudent() {
    if (queue.length === 0) return;

    const skipped = queue[0];
    if (skipped && skipped.id) {
        fetch('../service/pickup/update_pickup_status.php', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ request_id: skipped.id, status: 'dibatalkan' })
        }).then(() => fetchQueue(false));
    }

    queue.shift();
    updateQueueList(false);
    updateQueueStats();
    showToast(`${skipped.name} dilewati!`);

    if (queue.length > 0) {
        isPaused = false;
        countdownValue = COUNTDOWN_START;
    }
    updateCountdownUI();
}

// Build announcement text based on saved settings
function buildAnnouncementText(student) {
    const savedBlocks = localStorage.getItem('announcementBlocks');
    const blocks = savedBlocks ? JSON.parse(savedBlocks) : defaultAnnouncementBlocks;

    let text = '';
    blocks.forEach(block => {
        if (block.type === 'text') text += block.value || '';
        else if (block.type === 'nama_siswa') text += student.name || '';
        else if (block.type === 'kelas') text += student.class || '';
        else if (block.type === 'dijemput_oleh') text += student.pickupBy || '';
    });

    return text || `${student.name}, ${student.class}, silakan menuju lobby, ditunggu oleh ${student.pickupBy}`;
}

// Call student (used by auto-call)
async function callStudent() {
    if (!isClassAuthorityActive()) {
        showToast('Pemanggilan diterapkan di Komputer Kurikulum', 'error');
        return;
    }
    if (queue.length === 0) {
        showToast('Tidak ada siswa dalam antrean!', 'error');
        return;
    }

    const student = queue[0];

    if (student && student.id) {
        try {
            await fetch('../service/pickup/update_pickup_status.php', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ request_id: student.id, status: 'dipanggil' })
            });
        } catch (error) {
            console.error('Error updating status:', error);
        }
    }

    queue.shift();
    queueCalledCount++;
    updateQueueList();
    updateQueueStats();

    const text = buildAnnouncementText(student);
    speakText(text, true);
    showToast(`Memanggil ${student.name}!`);
}

// Test sound
function testSound() {
    if (!isClassAuthorityActive()) {
        showToast('Pemanggilan diterapkan di Komputer Kurikulum', 'error');
        return;
    }
    const text = "Test suara, satu dua tiga, ini adalah simulasi pemanggilan otomatis";
    speakText(text);
    showToast('🔊 Memutar test suara...');
}

// Speak text using VoiceRSS API
function speakText(text, isAutoCall = false) {
    if (!isClassAuthorityActive()) {
        showToast('Pemanggilan diterapkan di Komputer Kurikulum', 'error');
        return;
    }
    try {
        if (currentAudio) {
            currentAudio.pause();
            currentAudio.currentTime = 0;
            currentAudio = null;
        }

        if (isAutoCall) {
            isSpeaking = true;
            updateStatusWhileSpeaking();
        }

        const encodedText = encodeURIComponent(text);
        const audioUrl = `https://api.voicerss.org/?key=${VOICERSS_API_KEY}&hl=id-id&src=${encodedText}&c=MP3&f=44khz_16bit_stereo`;
        const ttsAudio = new Audio(audioUrl);

        const playTTS = () => {
            currentAudio = ttsAudio;
            ttsAudio.play().catch(error => {
                console.error('TTS Play error:', error);
                if (isAutoCall) {
                    isSpeaking = false;
                    if (queue.length > 0 && isAutoCallingActive) {
                        countdownValue = COUNTDOWN_START;
                    }
                    updateCountdownUI();
                }
            });
        };

        if (bellSound) {
            const bell = bellSound.cloneNode();
            bell.onended = () => setTimeout(playTTS, 500);
            bell.onerror = playTTS;
            bell.play().catch(playTTS);
            currentAudio = bell;
        } else {
            playTTS();
        }

        ttsAudio.onended = () => {
            currentAudio = null;
            if (isAutoCall) {
                isSpeaking = false;
                if (queue.length > 0 && isAutoCallingActive) {
                    countdownValue = COUNTDOWN_START;
                    const countdownNumber = document.getElementById('countdownNumber');
                    if (countdownNumber) countdownNumber.textContent = countdownValue;
                }
                updateCountdownUI();
            }
        };

        ttsAudio.onerror = () => {
            currentAudio = null;
            if (isAutoCall) {
                isSpeaking = false;
                if (queue.length > 0 && isAutoCallingActive) {
                    countdownValue = COUNTDOWN_START;
                }
                updateCountdownUI();
            }
        };

    } catch (error) {
        console.error('TTS Error:', error);
        if (isAutoCall) {
            isSpeaking = false;
            if (queue.length > 0 && isAutoCallingActive) {
                countdownValue = COUNTDOWN_START;
            }
            updateCountdownUI();
        }
    }
}

function updateStatusWhileSpeaking() {
    const statusText = document.getElementById('callingStatusText');
    const statusDiv = document.getElementById('callingStatus');
    if (statusDiv) statusDiv.className = 'mt-4 p-3 bg-blue-50 border border-blue-200 rounded-xl text-center';
    if (statusText) statusText.textContent = '🔊 Sedang memanggil siswa...';
}

// Toast notification
function showToast(message, type = 'success') {
    const toast = document.getElementById('toast');
    const toastMsg = document.getElementById('toastMessage');

    if (!toast || !toastMsg) {
        console.log('Toast:', message);
        return;
    }

    toastMsg.textContent = message;
    toast.classList.remove('hidden');

    const svg = toast.querySelector('svg');
    if (svg) {
        if (type === 'error') {
            svg.classList.remove('text-success');
            svg.classList.add('text-red-500');
        } else {
            svg.classList.remove('text-red-500');
            svg.classList.add('text-success');
        }
    }

    setTimeout(() => toast.classList.add('hidden'), 3000);
}

// Hide dropdown when clicking outside
document.addEventListener('click', (e) => {
    const dropdown = document.getElementById('studentDropdown');
    const input = document.getElementById('inputStudentName');
    if (dropdown && input && !dropdown.contains(e.target) && e.target !== input) {
        dropdown.classList.add('hidden');
    }
});
