/* ============================================================
   AX_Events | script.js
   Bridge NUI ↔ Lua (reservado para futuras funcionalidades)
   ============================================================ */

'use strict';

const root = document.getElementById('ax-events-root');

/* ----------------------------------------------------------
   Escucha mensajes enviados desde Lua con SendNUIMessage
   ---------------------------------------------------------- */
window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {

        /* Reservado: mostrar panel genérico */
        case 'showPanel':
            showPanel(data.payload);
            break;

        /* Reservado: ocultar NUI */
        case 'hidePanel':
            hideUI();
            break;

        default:
            break;
    }
});

/* ----------------------------------------------------------
   Cerrar NUI con ESC
   ---------------------------------------------------------- */
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        hideUI();
    }
});

/* ----------------------------------------------------------
   Helpers
   ---------------------------------------------------------- */

function showPanel(payload = {}) {
    root.innerHTML = `
        <div class="ax-panel">
            <div class="ax-panel__title">${escHtml(payload.title ?? 'AX Events')}</div>
            <div class="ax-panel__body">${escHtml(payload.body ?? '')}</div>
            ${payload.showClose ? '<button class="ax-btn" onclick="hideUI()">Cerrar</button>' : ''}
        </div>
    `;
    root.style.display = 'flex';
}

function hideUI() {
    root.style.display = 'none';
    root.innerHTML = '';
    postLua('closeUI', {});
}

function postLua(action, data = {}) {
    fetch(`https://AX_Events/${action}`, {
        method : 'POST',
        headers: { 'Content-Type': 'application/json' },
        body   : JSON.stringify(data),
    }).catch(() => {});
}

function escHtml(str) {
    return String(str)
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;')
        .replace(/"/g, '&quot;');
}