// Playing with Fire 2 / Bomberman Engine for Web Canvas
const COLS = 11;
const ROWS = 9;

const CELL_EMPTY = 0;
const CELL_WALL = 1;     // Kırılmaz taş sütun
const CELL_BARREL = 2;   // Kırmızı kırılabilir varil

// PowerUp Tipleri
const PU_LIGHTNING = 1;  // ⚡ Şimşek (Menzil +1)
const PU_SHOE = 2;       // 👟 Ayakkabı (Hız)
const PU_EXTRA_BOMB = 3; // 💣 Bomba (+1 Bomba Hakkı)
const PU_HEAL = 4;       // 🔧 Tamir (Can +25)

let grid = [];
let bombs = [];
let explosions = [];
let powerUps = [];

// Oyuncu Durumu
let player = {
  x: 1,
  y: 1,
  health: 100,
  maxHealth: 100,
  maxBombs: 1,
  bombRange: 1,
  speed: 1.0,
  score: 0
};

let currentCoins = 500;
let currentGems = 10;
let signalRConnection = null;
let activeMatchId = null;

const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

function initGame() {
  bombs = [];
  explosions = [];
  powerUps = [];
  player.x = 1;
  player.y = 1;
  player.health = 100;
  player.maxBombs = 1;
  player.bombRange = 1;
  player.speed = 1.0;
  player.score = 0;

  // Izgarayı oluştur
  grid = [];
  for (let r = 0; r < ROWS; r++) {
    grid[r] = [];
    for (let c = 0; c < COLS; c++) {
      if (r === 0 || r === ROWS - 1 || c === 0 || c === COLS - 1) {
        grid[r][c] = CELL_WALL;
      } else if (r % 2 === 0 && c % 2 === 0) {
        grid[r][c] = CELL_WALL;
      } else if ((r <= 2 && c <= 2) || (r >= ROWS - 3 && c >= COLS - 3)) {
        grid[r][c] = CELL_EMPTY; // Köşeler temiz
      } else {
        grid[r][c] = Math.random() < 0.65 ? CELL_BARREL : CELL_EMPTY;
      }
    }
  }

  updateHud();
  addGameLog('💣 Playing with Fire 2 arenası hazır! Varilleri patlatın, güçlendiricileri toplayın.', 'success');
}

function updateHud() {
  const hpPercent = (player.health / player.maxHealth) * 100;
  document.getElementById('waterProgressBar').style.width = hpPercent + '%';
  document.getElementById('waterPercentLabel').innerText = `${player.health} HP`;

  const bombPercent = (bombs.length / player.maxBombs) * 100;
  document.getElementById('fireProgressBar').style.width = Math.min(100, bombPercent) + '%';
  document.getElementById('firePercentLabel').innerText = `${bombs.length} / ${player.maxBombs} Bomba`;

  document.getElementById('matchRoomLabel').innerText = `⚡ Menzil: ${player.bombRange} | 👟 Hız: ${player.speed.toFixed(1)}x`;
}

function movePlayer(dx, dy) {
  if (player.health <= 0) return;

  const tx = player.x + dx;
  const ty = player.y + dy;

  if (tx < 0 || tx >= COLS || ty < 0 || ty >= ROWS) return;
  if (grid[ty][tx] !== CELL_EMPTY) return;
  if (bombs.some(b => b.x === tx && b.y === ty)) return;

  player.x = tx;
  player.y = ty;

  // PowerUp toplama
  checkPickup(tx, ty);
}

function placeBomb() {
  if (player.health <= 0) return;
  if (bombs.length >= player.maxBombs) {
    addGameLog('Maksimum bomba sayısına ulaşıldı!', 'danger');
    return;
  }
  if (bombs.some(b => b.x === player.x && b.y === player.y)) return;

  bombs.push({
    x: player.x,
    y: player.y,
    range: player.bombRange,
    timeLeft: 2.2
  });

  updateHud();
}

function checkPickup(x, y) {
  const idx = powerUps.findIndex(p => p.x === x && p.y === y);
  if (idx !== -1) {
    const item = powerUps.splice(idx, 1)[0];
    player.score += 150;

    switch (item.type) {
      case PU_LIGHTNING:
        player.bombRange += 1;
        addGameLog('⚡ Şimşek Alındı! Patlama şiddeti/menzili arttı: ' + player.bombRange, 'info');
        break;
      case PU_SHOE:
        player.speed += 0.25;
        addGameLog('👟 Ayakkabı Alındı! Hareket hızı arttı: ' + player.speed.toFixed(2) + 'x', 'info');
        break;
      case PU_EXTRA_BOMB:
        player.maxBombs += 1;
        addGameLog('💣 Bomba Alındı! Maksimum bomba hakkı: ' + player.maxBombs, 'info');
        break;
      case PU_HEAL:
        player.health = Math.min(player.maxHealth, player.health + 25);
        addGameLog('🔧 Tamir Kiti! Can iyileşti: ' + player.health + ' HP', 'success');
        break;
    }
    updateHud();
  }
}

// Oyun Döngüsü
let lastTime = performance.now();
function gameLoop(now) {
  const dt = (now - lastTime) / 1000;
  lastTime = now;

  // Patlama süreleri
  for (let i = explosions.length - 1; i >= 0; i--) {
    explosions[i].duration -= dt;
    if (explosions[i].duration <= 0) {
      explosions.splice(i, 1);
    }
  }

  // Bomba süreleri
  for (let i = bombs.length - 1; i >= 0; i--) {
    bombs[i].timeLeft -= dt;
    if (bombs[i].timeLeft <= 0) {
      const b = bombs.splice(i, 1)[0];
      detonate(b);
      updateHud();
    }
  }

  draw();
  requestAnimationFrame(gameLoop);
}

function detonate(bomb) {
  addExplosion(bomb.x, bomb.y);

  const dirs = [
    [0, -1], [0, 1], [-1, 0], [1, 0]
  ];

  for (const dir of dirs) {
    for (let dist = 1; dist <= bomb.range; dist++) {
      const tx = bomb.x + (dir[0] * dist);
      const ty = bomb.y + (dir[1] * dist);

      if (tx < 0 || tx >= COLS || ty < 0 || ty >= ROWS) break;
      if (grid[ty][tx] === CELL_WALL) break; // Duvara çarparsa dur

      if (grid[ty][tx] === CELL_BARREL) {
        grid[ty][tx] = CELL_EMPTY;
        addExplosion(tx, ty);
        player.score += 100;

        // Varilden %55 şansla power-up düşer
        if (Math.random() < 0.55) {
          const types = [PU_LIGHTNING, PU_SHOE, PU_EXTRA_BOMB, PU_HEAL];
          const chosen = types[Math.floor(Math.random() * types.length)];
          powerUps.push({ x: tx, y: ty, type: chosen });
        }
        break; // Varilden sonra o yönde dur
      }

      // Zincirleme bomba
      const other = bombs.find(b => b.x === tx && b.y === ty);
      if (other) other.timeLeft = 0.05;

      addExplosion(tx, ty);
    }
  }
}

function addExplosion(x, y) {
  explosions.push({ x, y, duration: 0.5 });
  if (player.x === x && player.y === y) {
    player.health = Math.max(0, player.health - 25);
    addGameLog('⚠️ Patlamada kaldın! Kalan Can: ' + player.health, 'danger');
    if (player.health <= 0) {
      addGameLog('💀 Oyuncu elendi! Yeniden başlatabilirsiniz.', 'danger');
    }
    updateHud();
  }
}

// Çizim
function draw() {
  ctx.clearRect(0, 0, canvas.width, canvas.height);

  const cellW = canvas.width / COLS;
  const cellH = canvas.height / ROWS;

  // 1. Zemin ve Bloklar
  for (let r = 0; r < ROWS; r++) {
    for (let c = 0; c < COLS; c++) {
      const rx = c * cellW;
      const ry = r * cellH;

      if (grid[r][c] === CELL_WALL) {
        ctx.fillStyle = '#6b5e4b';
        ctx.fillRect(rx, ry, cellW, cellH);
        ctx.strokeStyle = '#3b3226';
        ctx.lineWidth = 2;
        ctx.strokeRect(rx, ry, cellW, cellH);
      } else if (grid[r][c] === CELL_BARREL) {
        // Kırmızı Varil
        ctx.fillStyle = '#b94a48';
        ctx.fillRect(rx + 2, ry + 2, cellW - 4, cellH - 4);
        ctx.strokeStyle = '#5d2423';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.moveTo(rx + 2, ry + cellH * 0.33);
        ctx.lineTo(rx + cellW - 2, ry + cellH * 0.33);
        ctx.moveTo(rx + 2, ry + cellH * 0.66);
        ctx.lineTo(rx + cellW - 2, ry + cellH * 0.66);
        ctx.stroke();
      } else {
        ctx.strokeStyle = '#3f3527';
        ctx.lineWidth = 0.5;
        ctx.strokeRect(rx, ry, cellW, cellH);
      }
    }
  }

  // 2. Power-Up Asset'leri
  for (const p of powerUps) {
    const px = p.x * cellW;
    const py = p.y * cellH;

    let icon = '⚡';
    let bg = '#1e40af';
    if (p.type === PU_SHOE) { icon = '👟'; bg = '#065f46'; }
    if (p.type === PU_EXTRA_BOMB) { icon = '💣'; bg = '#7f1d1d'; }
    if (p.type === PU_HEAL) { icon = '🔧'; bg = '#854d0e'; }

    ctx.fillStyle = bg;
    ctx.fillRect(px + 4, py + 4, cellW - 8, cellH - 8);
    ctx.font = `${cellH * 0.55}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'middle';
    ctx.fillText(icon, px + cellW / 2, py + cellH / 2);
  }

  // 3. Bombalar
  for (const b of bombs) {
    const cx = (b.x + 0.5) * cellW;
    const cy = (b.y + 0.5) * cellH;
    ctx.fillStyle = '#1e293b';
    ctx.beginPath();
    ctx.arc(cx, cy, cellW * 0.38, 0, Math.PI * 2);
    ctx.fill();

    // Fitil
    ctx.fillStyle = '#f59e0b';
    ctx.beginPath();
    ctx.arc(cx + 4, cy - cellW * 0.38, 3, 0, Math.PI * 2);
    ctx.fill();
  }

  // 4. Playing with Fire Mavi Patlamalar
  for (const exp of explosions) {
    const ex = exp.x * cellW;
    const ey = exp.y * cellH;

    ctx.fillStyle = 'rgba(56, 189, 248, 0.85)';
    ctx.fillRect(ex, ey, cellW, cellH);

    ctx.fillStyle = '#ffffff';
    ctx.fillRect(ex + 4, ey + 4, cellW - 8, cellH - 8);
  }

  // 5. Oyuncu (İtfaiyeci)
  if (player.health > 0) {
    const pcx = (player.x + 0.5) * cellW;
    const pcy = (player.y + 0.5) * cellH;

    ctx.fillStyle = '#0284c7';
    ctx.beginPath();
    ctx.arc(pcx, pcy, cellW * 0.38, 0, Math.PI * 2);
    ctx.fill();

    // Kask
    ctx.fillStyle = '#38bdf8';
    ctx.beginPath();
    ctx.arc(pcx, pcy - 2, cellW * 0.38, Math.PI, 0);
    ctx.fill();

    // Yüz
    ctx.fillStyle = '#ffd1a4';
    ctx.beginPath();
    ctx.arc(pcx, pcy + 3, cellW * 0.2, 0, Math.PI * 2);
    ctx.fill();
  }
}

// Buton Etkileşimleri
function triggerSprayWater() {
  placeBomb();
}

function refillWaterTank() {
  initGame();
}

function spawnNewFire() {
  initGame();
}

function switchTab(tabId) {
  document.querySelectorAll('.tab-btn').forEach(btn => btn.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(content => content.classList.remove('active'));

  event.currentTarget.classList.add('active');
  const target = document.getElementById(tabId);
  if (target) {
    target.classList.add('active');
  }
}

function addGameLog(message, type = 'info') {
  const box = document.getElementById('gameLogs');
  if (!box) return;
  const div = document.createElement('div');
  div.className = `log-entry log-${type}`;
  div.innerText = `[${new Date().toLocaleTimeString()}] ${message}`;
  box.prepend(div);
}

function addSecurityLog(message, type = 'info') {
  const box = document.getElementById('securityLogs');
  if (!box) return;
  const div = document.createElement('div');
  div.className = `log-entry log-${type}`;
  div.innerText = `[${new Date().toLocaleTimeString()}] ${message}`;
  box.prepend(div);
}

// Klavye Kontrolleri
window.addEventListener('keydown', (e) => {
  if (e.code === 'ArrowUp' || e.code === 'KeyW') movePlayer(0, -1);
  if (e.code === 'ArrowDown' || e.code === 'KeyS') movePlayer(0, 1);
  if (e.code === 'ArrowLeft' || e.code === 'KeyA') movePlayer(-1, 0);
  if (e.code === 'ArrowRight' || e.code === 'KeyD') movePlayer(1, 0);
  if (e.code === 'Space') placeBomb();
});

// Başlangıç
initGame();
requestAnimationFrame(gameLoop);
