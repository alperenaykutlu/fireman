// State
let currentCoins = 500;
let currentGems = 10;
let waterLevel = 100;
let fireIntensity = 100;
let activeMatchId = null;
let signalRConnection = null;
let currentTab = 'tab-gameplay';

// Canvas & Particle Simulation
const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

let firefighter = { x: 80, y: 140, size: 24 };
let fireParticles = [];
let waterParticles = [];

function initParticles() {
  fireParticles = [];
  for (let i = 0; i < 35; i++) {
    fireParticles.push({
      x: 420 + Math.random() * 80,
      y: 120 + Math.random() * 60,
      vx: (Math.random() - 0.5) * 1.5,
      vy: -1 - Math.random() * 2,
      size: 6 + Math.random() * 10,
      life: Math.random() * 1
    });
  }
}

function updateSimulation() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  // Zemin çizgisi
  ctx.strokeStyle = '#223042';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(0, 220);
  ctx.lineTo(canvas.width, 220);
  ctx.stroke();

  // İtfaiyeci çizimi
  ctx.fillStyle = '#3b82f6';
  ctx.fillRect(firefighter.x - 12, 190, 24, 30);
  ctx.fillStyle = '#ef4444'; // Kask
  ctx.beginPath();
  ctx.arc(firefighter.x, 185, 10, 0, Math.PI * 2);
  ctx.fill();

  // Nozul / Hortum
  ctx.strokeStyle = '#94a3b8';
  ctx.lineWidth = 4;
  ctx.beginPath();
  ctx.moveTo(firefighter.x + 8, 200);
  ctx.lineTo(firefighter.x + 22, 195);
  ctx.stroke();

  // Yangın Kaynağı / Bina
  if (fireIntensity > 0) {
    ctx.fillStyle = '#1e293b';
    ctx.fillRect(400, 90, 120, 130);
    ctx.fillStyle = '#f59e0b';
    ctx.fillRect(420, 110, 20, 30);
    ctx.fillRect(470, 110, 20, 30);

    // Yangın parçacıkları
    fireParticles.forEach(p => {
      p.x += p.vx;
      p.y += p.vy;
      p.size = Math.max(0, p.size - 0.15);
      p.life -= 0.02;

      if (p.life <= 0 || p.size <= 0) {
        p.x = 420 + Math.random() * 80;
        p.y = 190 + Math.random() * 20;
        p.size = (fireIntensity / 10) + Math.random() * 6;
        p.life = 1;
      }

      ctx.fillStyle = p.life > 0.5 ? 'rgba(255, 60, 0, 0.8)' : 'rgba(255, 165, 0, 0.7)';
      ctx.beginPath();
      ctx.arc(p.x, p.y, p.size, 0, Math.PI * 2);
      ctx.fill();
    });
  } else {
    ctx.fillStyle = '#10b981';
    ctx.font = '16px sans-serif';
    ctx.fillText('✅ YANGIN SÖNDÜRÜLDÜ!', 390, 150);
  }

  // Su jet parçacıkları
  for (let i = waterParticles.length - 1; i >= 0; i--) {
    let wp = waterParticles[i];
    wp.x += wp.vx;
    wp.y += wp.vy;
    wp.vy += 0.2; // yerçekimi

    ctx.fillStyle = 'rgba(56, 189, 248, 0.8)';
    ctx.beginPath();
    ctx.arc(wp.x, wp.y, 4, 0, Math.PI * 2);
    ctx.fill();

    // Çarpışma kontrolü
    if (wp.x >= 410 && wp.x <= 520 && wp.y >= 100 && wp.y <= 220) {
      fireIntensity = Math.max(0, fireIntensity - 0.8);
      updateMeters();
      waterParticles.splice(i, 1);
    } else if (wp.y > 220) {
      waterParticles.splice(i, 1);
    }
  }

  requestAnimationFrame(updateSimulation);
}

// Su Püskürtme
function triggerSprayWater() {
  if (waterLevel <= 0) {
    addGameLog('⚠️ Su tankı boş! Yeniden doldurmalısınız.', 'danger');
    return;
  }

  waterLevel = Math.max(0, waterLevel - 2);
  updateMeters();

  for (let i = 0; i < 6; i++) {
    waterParticles.push({
      x: firefighter.x + 22,
      y: 195,
      vx: 9 + Math.random() * 2,
      vy: -2 - Math.random() * 2
    });
  }

  if (signalRConnection && signalRConnection.state === 'Connected' && activeMatchId) {
    signalRConnection.invoke('SendFireSuppression', activeMatchId, {
      userId: '00000000-0000-0000-0000-000000000001',
      fireInstanceId: '00000000-0000-0000-0000-000000000002',
      waterVolume: 2.0,
      extinguished: fireIntensity <= 0
    }).catch(err => console.error(err));
  }
}

function refillWaterTank() {
  waterLevel = 100;
  updateMeters();
  addGameLog('🚰 Su tankı %100 dolduruldu.', 'success');
}

function spawnNewFire() {
  fireIntensity = 100;
  updateMeters();
  initParticles();
  addGameLog('🔥 Yeni yangın ihbarı alındı!', 'danger');
}

function updateMeters() {
  document.getElementById('waterProgressBar').style.width = waterLevel + '%';
  document.getElementById('waterPercentLabel').innerText = Math.round(waterLevel) + '%';
  document.getElementById('fireProgressBar').style.width = fireIntensity + '%';
  document.getElementById('firePercentLabel').innerText = Math.round(fireIntensity) + '%';
}

function switchTab(tabId) {
  document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));

  event.currentTarget.classList.add('active');
  const target = document.getElementById(tabId);
  if (target) {
    target.classList.add('active');
  }
  currentTab = tabId;
}

function addGameLog(message, type = 'info') {
  const box = document.getElementById('gameLogs');
  const div = document.createElement('div');
  div.className = `log-entry log-${type}`;
  div.innerText = `[${new Date().toLocaleTimeString()}] ${message}`;
  box.prepend(div);
}

function addSecurityLog(message, type = 'info') {
  const box = document.getElementById('securityLogs');
  const div = document.createElement('div');
  div.className = `log-entry log-${type}`;
  div.innerText = `[${new Date().toLocaleTimeString()}] ${message}`;
  box.prepend(div);
}

// SignalR Bağlantısı
async function connectSignalR() {
  try {
    signalRConnection = new signalR.HubConnectionBuilder()
      .withUrl('/hubs/match')
      .withAutomaticReconnect()
      .build();

    signalRConnection.on('PlayerMoved', (move) => {
      addGameLog(`Diğer oyuncu hareket etti: (${move.posX.toFixed(1)}, ${move.posY.toFixed(1)})`, 'info');
    });

    signalRConnection.on('FireSuppressionUpdated', (action) => {
      addGameLog(`Takım arkadaşı su sıktı: ${action.waterVolume}L`, 'info');
    });

    signalRConnection.on('CheatViolationAlert', (reason) => {
      addSecurityLog(`🚨 ANTI-CHEAT UYARISI: ${reason}`, 'danger');
      alert('AntiCheat Güvenlik Uyarısı: ' + reason);
    });

    await signalRConnection.start();
    document.getElementById('signalrStatusText').innerText = 'SignalR: Connected';
    document.getElementById('signalrStatusBadge').querySelector('.status-dot').style.background = '#30d158';
    addGameLog('SignalR MatchHub bağlantısı kuruldu.', 'success');
  } catch (err) {
    console.error(err);
    addGameLog('SignalR bağlantı hatası: ' + err.message, 'danger');
  }
}

// Eşleşme (Match)
async function createMatch() {
  try {
    const res = await fetch('/api/v1/matches', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ type: 'CoopRescue', maxPlayers: 4 })
    });
    const json = await res.json();
    if (json.success && json.data) {
      activeMatchId = json.data.id;
      document.getElementById('matchIdInput').value = activeMatchId;
      document.getElementById('matchRoomLabel').innerText = `Oda: ${activeMatchId.substring(0, 8)}...`;
      document.getElementById('matchStateBadge').innerText = 'Lobi Aktif';
      addGameLog(`Yeni maç açıldı: ${activeMatchId}`, 'success');

      if (signalRConnection && signalRConnection.state === 'Connected') {
        await signalRConnection.invoke('JoinMatchRoom', activeMatchId);
      }
    } else {
      addGameLog('Maç oluşturulamadı (Giriş yapılmış olmalıdır). Demo modunda oda simüle edildi.', 'info');
      activeMatchId = '00000000-0000-0000-0000-000000000001';
      document.getElementById('matchIdInput').value = activeMatchId;
      document.getElementById('matchRoomLabel').innerText = 'Oda: Demo-Coop-01';
    }
  } catch (ex) {
    addGameLog('Maç isteği hatası: ' + ex.message, 'danger');
  }
}

function joinRandomMatch() {
  addGameLog('Açık lobiye bağlanılıyor...', 'info');
  document.getElementById('playersList').innerHTML = `
    <div>🧑‍🚒 Oyuncu_1 (Kaptan - Hazır ✔)</div>
    <div>🧑‍🚒 İtfaiyeci Ahmet (Siz - Hazır ✔)</div>
  `;
  document.getElementById('matchStateBadge').innerText = 'Oyun Başladı';
}

// Anti-Cheat Simülasyonları
function simulateNormalMovement() {
  addSecurityLog('İstemci normal hareket paketi gönderiyor (Hız: 4.5 m/s)...', 'info');
  setTimeout(() => {
    addSecurityLog('Sunucu Doğruladı: [Allow] Hareket hız eşiği içinde.', 'success');
  }, 300);
}

function simulateSpeedHack() {
  addSecurityLog('⚠️ Anormal hız paketi fırlatılıyor (Hız: 28.5 m/s, Eşik: 16.0 m/s)...', 'danger');
  setTimeout(() => {
    addSecurityLog('🚨 VIOLATION: SpeedHackDetected! Hız 28.5 m/s eşiği aştı. Severity: High.', 'danger');
  }, 400);
}

function simulateTeleport() {
  addSecurityLog('⚡ Işınlanma koordinatı fırlatılıyor (Mesafe: 120 birim / 0.1s = 1200 m/s)...', 'danger');
  setTimeout(() => {
    addSecurityLog('⛔ CRITICAL ANOMALY: TeleportationDetected! Kullanıcı otomatik banlandı.', 'danger');
  }, 400);
}

// Görevler
function loadMissions() {
  const container = document.getElementById('missionsList');
  container.innerHTML = `
    <div style="background:#111822; padding:12px; border-radius:8px; border:1px solid var(--border-color); display:flex; justify-content:space-between; align-items:center;">
      <div>
        <strong>Sanayi Yangınını Söndür</strong>
        <div style="font-size:11px; color:var(--text-muted);">Ödül: 350 🪙 | 500 XP</div>
      </div>
      <button class="btn btn-blue" onclick="completeDemoMission('Sanayi Yangını', 350, 500)">Tamamla</button>
    </div>
    <div style="background:#111822; padding:12px; border-radius:8px; border:1px solid var(--border-color); display:flex; justify-content:space-between; align-items:center;">
      <div>
        <strong>Okul Binasından 3 Kişiyi Kurtar</strong>
        <div style="font-size:11px; color:var(--text-muted);">Ödül: 500 🪙 | 750 XP</div>
      </div>
      <button class="btn btn-blue" onclick="completeDemoMission('Okul Kurtarma', 500, 750)">Tamamla</button>
    </div>
  `;
}

function completeDemoMission(title, coins, exp) {
  currentCoins += coins;
  document.getElementById('headerCoins').innerText = currentCoins;
  let currentExp = parseInt(document.getElementById('charExpDisplay').innerText) + exp;
  document.getElementById('charExpDisplay').innerText = currentExp;
  alert(`Tebrikler! ${title} görevi tamamlandı. +${coins} Altın ve +${exp} XP kazanıldı!`);
}

function equipDemoItem(slot, itemName) {
  if (slot === 'Hat') document.getElementById('equippedHatSlot').innerText = itemName;
  if (slot === 'Suit') document.getElementById('equippedSuitSlot').innerText = itemName;
  if (slot === 'Boots') alert(itemName + ' kuşanıldı!');
  alert(`Başarılı: ${itemName} kuşanıldı!`);
}

function claimSeasonTier(tier) {
  alert(`Sezon Ödülü Alındı: Tier ${tier} ödülü envanterinize eklendi!`);
}

// Klavye kontrolleri
window.addEventListener('keydown', (e) => {
  if (e.code === 'Space') {
    triggerSprayWater();
  }
  if (e.code === 'ArrowRight' || e.code === 'KeyD') {
    firefighter.x = Math.min(360, firefighter.x + 8);
  }
  if (e.code === 'ArrowLeft' || e.code === 'KeyA') {
    firefighter.x = Math.max(30, firefighter.x - 8);
  }
});

// Başlangıç
initParticles();
updateSimulation();
loadMissions();
