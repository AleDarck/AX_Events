// ============================================================
//  AX_Looting - script.js
// ============================================================

'use strict';

// ============================================================
//  ESTADO
// ============================================================

let currentItems = [];
let imagePath    = '';
let revealDelay  = 180;
let isBag        = false;  // true cuando el panel es de un maletin de jugador

// ============================================================
//  DOM
// ============================================================

const overlay       = document.getElementById('overlay');
const lootPanel     = document.getElementById('lootPanel');
const lootGrid      = document.getElementById('lootGrid');
const emptyState    = document.getElementById('emptyState');
const btnClose      = document.getElementById('btnClose');
const btnCollectAll = document.getElementById('btnCollectAll');
const itemCountEl   = document.getElementById('itemCount');

// ============================================================
//  HELPERS
// ============================================================

function post(action, data = {}) {
    fetch(`https://AX_Looting/${action}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data),
    }).catch(() => {});
}

function formatItemName(name) {
    if (!name) return 'Desconocido';
    return name.replace(/[-_]/g, ' ').replace(/\b\w/g, c => c.toUpperCase());
}

function updateItemCount() {
    const total = currentItems.length;
    itemCountEl.textContent = total === 1 ? '1 item encontrado' : `${total} items encontrados`;
    btnCollectAll.disabled  = total === 0;
    if (total === 0) showEmptyState();
}

// ============================================================
//  ABRIR PANEL
// ============================================================

function openPanel(items, path, delay, title, bagMode) {
    currentItems = [...items];
    imagePath    = path    || '';
    revealDelay  = delay   || 180;
    isBag        = !!bagMode;

    // Titulo dinamico
    const titleEl = document.querySelector('.panel-title');
    if (titleEl) titleEl.textContent = title || 'BOTIN ENCONTRADO';

    lootGrid.innerHTML = '';
    emptyState.classList.add('hidden');
    lootGrid.style.display = 'flex';

    updateItemCount();

    overlay.classList.remove('hidden');
    lootPanel.classList.remove('hidden', 'closing');

    void overlay.offsetHeight;
    void lootPanel.offsetHeight;

    overlay.classList.add('visible');
    lootPanel.classList.add('visible');

    buildCardsSequential(currentItems);
}

// ============================================================
//  CERRAR PANEL
// ============================================================

function closePanel(notifyServer = true) {
    lootPanel.classList.remove('visible');
    lootPanel.classList.add('closing');
    overlay.classList.remove('visible');

    setTimeout(() => {
        lootPanel.classList.remove('closing');
        lootPanel.classList.add('hidden');
        overlay.classList.add('hidden');
        lootGrid.innerHTML = '';
        currentItems = [];
    }, 280);

    if (notifyServer) post(isBag ? 'closeBag' : 'closeUI');
}

// ============================================================
//  CONSTRUIR CARDS - UNA POR UNA
//  Flujo por card:
//  1. Card aparece con spinner (clase 'appeared')
//  2. Spinner gira durante spinnerDuration ms
//  3. Se intenta cargar la imagen de ox_inventory
//  4. Al cargar (o fallar) → spinner desaparece, imagen aparece, card = 'revealed'
//  5. Solo cuando esta card termina, empieza la siguiente
// ============================================================

const SPINNER_DURATION = 900; // ms que el spinner esta visible minimo

function buildCardsSequential(items) {
    lootGrid.innerHTML = '';

    // Pre-crear todas las cards en el DOM pero invisibles
    const cards = items.map(item => {
        const card = createCard(item);
        lootGrid.appendChild(card);
        return { card, item };
    });

    // Revelar una por una en cadena
    revealNext(cards, 0);
}

function revealNext(cards, index) {
    if (index >= cards.length) return;

    const { card, item } = cards[index];

    // Paso 1: card aparece con spinner
    card.classList.add('appeared');

    // Paso 2: despues del tiempo del spinner, cargar imagen
    // La siguiente card empieza cuando ESTA termina de revelarse
    setTimeout(() => {
        revealCardImage(card, item, () => {
            // Callback: esta card termino, iniciar la siguiente
            // con un pequeño gap visual entre cards
            setTimeout(() => revealNext(cards, index + 1), 80);
        });
    }, SPINNER_DURATION);
}

// ============================================================
//  CREAR CARD - estructura plana y centrada
//  [ badge ]
//  [ spinner | imagen ]   <- mismo espacio, se intercambian
//  [ nombre ]
//  [ cantidad ]
// ============================================================

function createCard(item) {
    const card = document.createElement('div');
    card.classList.add('item-card');
    card.dataset.name  = item.name;
    card.dataset.count = item.count;

    const badge = document.createElement('div');
    badge.classList.add('collect-badge');
    badge.textContent = 'RECOGER';
    card.appendChild(badge);

    const spinner = document.createElement('div');
    spinner.classList.add('item-spinner');
    const ring = document.createElement('div');
    ring.classList.add('spinner-ring');
    spinner.appendChild(ring);
    card.appendChild(spinner);

    const img = document.createElement('img');
    img.classList.add('item-img');
    img.alt = item.name;
    card.appendChild(img);

    const nameEl = document.createElement('div');
    nameEl.classList.add('item-name');
    const displayName = item.label ? item.label : formatItemName(item.name);
    nameEl.textContent = displayName;
    nameEl.title = displayName;
    card.appendChild(nameEl);

    const countEl = document.createElement('div');
    countEl.classList.add('item-count');
    countEl.innerHTML = `x<span>${item.count}</span>`;
    card.appendChild(countEl);

    card.addEventListener('click', () => collectSingleItem(card, item));
    return card;
}

// ============================================================
//  REVELAR IMAGEN
//  Oculta el spinner, muestra la imagen (o default.png si falla)
// ============================================================

function revealCardImage(card, item, onDone) {
    const spinner = card.querySelector('.item-spinner');
    const img     = card.querySelector('.item-img');

    function reveal() {
        spinner.classList.add('hidden');
        card.classList.add('revealed');
        if (onDone) onDone();
    }

    img.onload = () => {
        img.classList.add('loaded');
        reveal();
    };

    img.onerror = () => {
        // Si falla, intentar default.png del inventario
        if (!img.dataset.usedDefault) {
            img.dataset.usedDefault = '1';
            img.src = `${imagePath}default.png`;
        } else {
            // Si default.png tampoco existe, mostrar igual (imagen rota oculta)
            reveal();
        }
    };

    img.src = `${imagePath}${item.name}.png`;
}

// ============================================================
//  RECOGER ITEM INDIVIDUAL
// ============================================================

function collectSingleItem(card, item) {
    if (card.classList.contains('collected')) return;

    card.classList.add('collected');
    post(isBag ? 'collectBagItem' : 'collectItem', { name: item.name, count: item.count });

    currentItems = currentItems.filter(
        i => !(i.name === item.name && i.count === item.count)
    );

    setTimeout(() => {
        if (card.parentNode) card.parentNode.removeChild(card);
        updateItemCount();
    }, 240);
}

// ============================================================
//  RECOGER TODO
// ============================================================

function collectAll() {
    if (currentItems.length === 0) return;

    btnCollectAll.disabled = true;

    const cards = [...lootGrid.querySelectorAll('.item-card:not(.collected)')];
    cards.forEach((card, i) => {
        setTimeout(() => card.classList.add('collected'), i * 55);
    });

    post(isBag ? 'collectAllBag' : 'collectAll', { items: currentItems });
    currentItems = [];
}

// ============================================================
//  ESTADO VACIO
// ============================================================

function showEmptyState() {
    lootGrid.style.display = 'none';
    emptyState.classList.remove('hidden');
    btnCollectAll.disabled = true;
}

// ============================================================
//  BOTONES
// ============================================================

btnClose.addEventListener('click', () => closePanel(true));
btnCollectAll.addEventListener('click', collectAll);
overlay.addEventListener('click', () => closePanel(true));
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && !lootPanel.classList.contains('hidden')) {
        closePanel(true);
    }
});

// ============================================================
//  MENSAJES NUI
// ============================================================

lootGrid.addEventListener('wheel', function(e) {
    e.preventDefault();
    lootGrid.scrollLeft += e.deltaY;
}, { passive: false });

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    switch (data.action) {
        case 'openLoot':
            openPanel(
                data.items       || [],
                data.imagePath   || '',
                data.revealDelay || 180,
                data.title       || null,
                false
            );
            break;

        case 'openBagUI':
            openPanel(
                data.items       || [],
                data.imagePath   || '',
                data.revealDelay || 180,
                data.title       || 'MALETIN',
                true
            );
            break;

        case 'closeLoot':
            closePanel(false);
            break;
    }
});