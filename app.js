/**
 * Balance Connect-E — app.js
 *
 * Replicates the MIT App Inventor logic shown in the project screenshots:
 *  - Screen1.Initialize : load saved weight list from localStorage, set AES key
 *  - Bluetooth          : scan, connect, disconnect (Web Bluetooth API)
 *  - Timer              : poll for incoming data, parse #…# frame, AES-decrypt,
 *                         validate "ENC" prefix, timestamp and append to list
 *  - Liste.Click        : add current measure to persistent list
 *  - Vider_liste.Click  : clear the list in memory and localStorage
 */

'use strict';

/* ── Constants ────────────────────────────────────────────── */

// AES key matching the App Inventor block: AES1.SetKey "B7a6l5a4n3c2e1co"
const AES_KEY = 'B7a6l5a4n3c2e1co';

// TinyDB tag used to persist the weight list
const DB_TAG = 'donnees stocké';

// Nordic UART Service UUIDs (common BLE serial profile used by embedded scales)
const UART_SERVICE_UUID         = '6e400001-b5a3-f393-e0a9-e50e24dcca9e';
const UART_RX_CHARACTERISTIC    = '6e400003-b5a3-f393-e0a9-e50e24dcca9e'; // notifications

// Polling interval in ms (mirrors App Inventor's Clock timer interval)
const TIMER_INTERVAL_MS = 500;

/* ── State ────────────────────────────────────────────────── */

let bluetoothDevice     = null;
let rxCharacteristic    = null;
let timerHandle         = null;
let receivedBuffer      = '';       // accumulates raw bytes from BLE notifications

let listePoids          = [];       // [{weight, date}]  — global Liste_poids
let mesure              = 0;        // global mesure counter (mirrors App Inventor var)

/* ── DOM refs ─────────────────────────────────────────────── */

const labelConnexion    = document.getElementById('label-connexion');
const btnConnect        = document.getElementById('btn-connect');
const btnDisconnect     = document.getElementById('btn-disconnect');
const btnVider          = document.getElementById('btn-vider');
const zoneTexte         = document.getElementById('zone-texte');
const listePoidsDom     = document.getElementById('liste-poids');

// Debug labels
const labelReceived     = document.getElementById('label-received');
const labelMessageUtile = document.getElementById('label-message-utile');
const labelResultatAes  = document.getElementById('label-resultat-aes');

/* ══════════════════════════════════════════════════════════════
   SCREEN INITIALISATION
   Mirrors: when Screen1.Initialize
   ══════════════════════════════════════════════════════════════ */

function screenInitialize() {
  // TinyDB1.GetValue tag:"donnees stocké" valueIfTagNotThere: create empty list
  const stored = localStorage.getItem(DB_TAG);
  listePoids = stored ? JSON.parse(stored) : [];

  // AES1.SetKey
  // (Key is a constant here; CryptoJS uses it at decryption time.)

  renderList();
}

/* ══════════════════════════════════════════════════════════════
   TINYDB HELPERS  (localStorage replacement)
   ══════════════════════════════════════════════════════════════ */

function tinyDBStore(tag, value) {
  localStorage.setItem(tag, JSON.stringify(value));
}

/* ══════════════════════════════════════════════════════════════
   AES DECRYPTION
   Mirrors: call AES1.DecryptData cipherText: get global messageUtile
   ══════════════════════════════════════════════════════════════ */

function aesDecrypt(cipherText) {
  try {
    const key   = CryptoJS.enc.Utf8.parse(AES_KEY);
    const bytes = CryptoJS.AES.decrypt(cipherText, key, {
      mode    : CryptoJS.mode.ECB,
      padding : CryptoJS.pad.Pkcs7,
    });
    return bytes.toString(CryptoJS.enc.Utf8);
  } catch {
    return '';
  }
}

/* ══════════════════════════════════════════════════════════════
   TIMER LOGIC
   Mirrors: when Horloge1.Timer
   ══════════════════════════════════════════════════════════════ */

function onTimer() {
  // if Client_Bluetooth1.IsConnected
  if (!rxCharacteristic) return;

  const receivedData = receivedBuffer;
  if (!receivedData) return;

  labelReceived.textContent = receivedData;

  // set global received_data to call Client_Bluetooth1.ReceiveText
  // (data already accumulated in receivedBuffer via BLE notifications)

  // starts at text: get global received_data  piece: "#"
  const positionDebut = receivedData.indexOf('#');

  // starts at text: get global received_data  piece: "#"  (second occurrence)
  const positionFin   = receivedData.indexOf('#', positionDebut + 1);

  // if position_fin > 0 and position_fin >= position_debut
  if (positionFin > 0 && positionFin >= positionDebut) {
    // segment text: start=position_debut+1  length=position_fin - position_debut - 1
    const messageUtile = receivedData.substring(
      positionDebut + 1,
      positionFin
    );

    labelMessageUtile.textContent = messageUtile;

    // if mesure == "2"
    mesure++;
    if (mesure >= 2) {
      mesure = 0;

      // call AES1.DecryptData cipherText: get global messageUtile
      const messageClair = aesDecrypt(messageUtile);
      labelResultatAes.textContent = messageClair;

      // if not is empty get global messageClair
      if (messageClair) {
        // if segment text get global messageClair start:1 length:3 = "ENC"
        //    and length get global messageClair >= 3
        if (messageClair.length >= 3 && messageClair.substring(0, 3) === 'ENC') {
          // set global dateCourante to call Horloge1.FormatDateTime
          const dateCourante = formatDateTime(new Date());

          // segment text get global messageClair start:4 length: length-3
          const weightStr = messageClair.substring(3);

          // set Label5.Text to get global messageClair  (show current weight)
          zoneTexte.textContent = weightStr;

          // add items to list  list: get global Liste_poids  item: get global messageClair
          listePoids.push({ weight: weightStr, date: dateCourante });

          // call TinyDB1.StoreValue  tag:"donnees stocké"  valueToStore: Liste_poids
          tinyDBStore(DB_TAG, listePoids);

          renderList();

          // Clear buffer so we don't re-process the same frame
          receivedBuffer = '';
        }
      }
    }
  }
}

/* ══════════════════════════════════════════════════════════════
   DATE/TIME FORMATTING
   Mirrors: call Horloge1.FormatDateTime pattern:"MM/dd/yyyy hh:mm:ss a"
   ══════════════════════════════════════════════════════════════ */

function formatDateTime(date) {
  const pad = (n) => String(n).padStart(2, '0');
  const mm  = pad(date.getMonth() + 1);
  const dd  = pad(date.getDate());
  const yy  = date.getFullYear();
  let   hh  = date.getHours();
  const min = pad(date.getMinutes());
  const ss  = pad(date.getSeconds());
  const ampm = hh >= 12 ? 'PM' : 'AM';
  hh = hh % 12 || 12;
  return `${mm}/${dd}/${yy} ${pad(hh)}:${min}:${ss} ${ampm}`;
}

/* ══════════════════════════════════════════════════════════════
   BLUETOOTH
   Mirrors: ListPicker1.BeforePicking / AfterPicking / BREAK.Click
   ══════════════════════════════════════════════════════════════ */

btnConnect.addEventListener('click', async () => {
  if (!navigator.bluetooth) {
    alert('Web Bluetooth API non disponible dans ce navigateur.\n' +
          'Utilisez Chrome ou Edge sur Android / Desktop.');
    return;
  }

  try {
    // ListPicker1.BeforePicking → set ListPicker1.Elements to AddressesAndNames
    // (Web Bluetooth shows its own device picker dialog)
    bluetoothDevice = await navigator.bluetooth.requestDevice({
      filters: [{ services: [UART_SERVICE_UUID] }],
    });

    bluetoothDevice.addEventListener('gattserverdisconnected', onDisconnected);

    // ListPicker1.AfterPicking → call Client_Bluetooth1.Connect
    const server  = await bluetoothDevice.gatt.connect();
    const service = await server.getPrimaryService(UART_SERVICE_UUID);
    rxCharacteristic = await service.getCharacteristic(UART_RX_CHARACTERISTIC);

    await rxCharacteristic.startNotifications();
    rxCharacteristic.addEventListener('characteristicvaluechanged', onBleData);

    setConnected(true);

    // Start the App Inventor timer equivalent
    timerHandle = setInterval(onTimer, TIMER_INTERVAL_MS);

  } catch (err) {
    if (err.name !== 'NotFoundError') {
      console.error('Bluetooth connection error:', err);
      alert(`Erreur de connexion : ${err.message}`);
    }
  }
});

btnDisconnect.addEventListener('click', () => {
  // BREAK.Click → call Client_Bluetooth1.Disconnect
  if (bluetoothDevice && bluetoothDevice.gatt.connected) {
    bluetoothDevice.gatt.disconnect();
  }
});

function onDisconnected() {
  clearInterval(timerHandle);
  timerHandle      = null;
  rxCharacteristic = null;
  receivedBuffer   = '';
  setConnected(false);
}

function onBleData(event) {
  // Accumulate incoming bytes (mirrors ReceiveText in the timer)
  const value   = event.target.value;
  const decoder = new TextDecoder('utf-8');
  receivedBuffer += decoder.decode(value);
}

function setConnected(connected) {
  labelConnexion.textContent = connected ? 'Connecté' : 'Déconnecté';
  labelConnexion.className   = connected
    ? 'badge badge--connected'
    : 'badge badge--disconnected';
  btnConnect.disabled    =  connected;
  btnDisconnect.disabled = !connected;
  if (!connected) {
    zoneTexte.textContent   = '—';
  }
}

/* ══════════════════════════════════════════════════════════════
   VIDER LISTE BUTTON
   Mirrors: when Vider_liste.Click
   ══════════════════════════════════════════════════════════════ */

btnVider.addEventListener('click', () => {
  // set global Liste_poids to create empty list
  listePoids = [];

  // call TinyDB1.StoreValue  tag:"donnees stocké"  valueToStore: create empty list
  tinyDBStore(DB_TAG, listePoids);

  // set Zone_de_texte1.Text to ""
  zoneTexte.textContent = '—';

  // set Label5.Text to ""
  renderList();
});

/* ══════════════════════════════════════════════════════════════
   RENDER
   ══════════════════════════════════════════════════════════════ */

function renderList() {
  listePoidsDom.innerHTML = '';
  if (listePoids.length === 0) {
    const li = document.createElement('li');
    li.textContent = 'Aucune mesure enregistrée.';
    li.style.color = '#a0aec0';
    listePoidsDom.appendChild(li);
    return;
  }
  // Newest first
  [...listePoids].reverse().forEach(({ weight, date }) => {
    const li    = document.createElement('li');
    const wSpan = document.createElement('span');
    const dSpan = document.createElement('span');
    wSpan.className   = 'weight';
    dSpan.className   = 'date';
    wSpan.textContent = weight;
    dSpan.textContent = date;
    li.appendChild(wSpan);
    li.appendChild(dSpan);
    listePoidsDom.appendChild(li);
  });
}

/* ══════════════════════════════════════════════════════════════
   BOOTSTRAP
   ══════════════════════════════════════════════════════════════ */

screenInitialize();
