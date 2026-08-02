
const patientEmailInput = document.getElementById('patientEmail');
const pefInput = document.getElementById('pefValue');
const fev1Input = document.getElementById('fev1Value');
const fvcInput = document.getElementById('fvcValue');
const btnGenerate = document.getElementById('btnGenerate');
const btnSubmit = document.getElementById('btnSubmit');
const apiUrlInput = document.getElementById('apiUrl');
const severityBadge = document.getElementById('severityBadge');
const consoleOutput = document.getElementById('consoleOutput');

function logToConsole(message, type = 'info') {
    const span = document.createElement('span');
    span.className = `log-${type}`;

    const time = new Date().toLocaleTimeString();
    span.textContent = `[${time}] ${message}`;

    consoleOutput.appendChild(span);
    consoleOutput.scrollTop = consoleOutput.scrollHeight; 
}

let currentSimData = null;

function generateRandomMeasurements() {
    
    
    const pef = Math.floor(Math.random() * (600 - 150 + 1)) + 150;

    
    
    const fvc = (Math.random() * (5.5 - 2.5) + 2.5).toFixed(2);

    
    
    const ratio = Math.random() * (0.85 - 0.45) + 0.45;
    let fev1 = (fvc * ratio).toFixed(2);

    
    pefInput.value = pef;
    fvcInput.value = fvc;
    fev1Input.value = fev1;

    
    severityBadge.classList.remove('hidden', 'green', 'yellow', 'red');
    if (pef >= 450) {
        severityBadge.textContent = "Zona Verde (Controlado)";
        severityBadge.classList.add('green');
    } else if (pef >= 250) {
        severityBadge.textContent = "Zona Amarilla (Precaución)";
        severityBadge.classList.add('yellow');
    } else {
        severityBadge.textContent = "Zona Roja (Crisis)";
        severityBadge.classList.add('red');
    }

    
    currentSimData = {
        pef: parseInt(pef),
        fev1: parseFloat(fev1),
        fvc: parseFloat(fvc)
    };

    validateForm();
    logToConsole(`Nuevos valores biométricos generados: PEF=${pef}`, 'warn');
}

function validateForm() {
    const email = patientEmailInput.value.trim();
    if (email !== '' && currentSimData !== null && email.includes('@')) {
        btnSubmit.disabled = false;
    } else {
        btnSubmit.disabled = true;
    }
}

async function submitSpirometry() {
    const email = patientEmailInput.value.trim();
    const url = apiUrlInput.value.trim();

    
    
    const now = new Date();
    const pad = (num) => String(num).padStart(2, '0');

    const localISOTime = now.getFullYear() +
        '-' + pad(now.getMonth() + 1) +
        '-' + pad(now.getDate()) +
        'T' + pad(now.getHours()) +
        ':' + pad(now.getMinutes()) +
        ':' + pad(now.getSeconds());

    const payload = {
        user_identifier: email,
        pef: currentSimData.pef,
        fev1: currentSimData.fev1,
        measured_at: localISOTime
    };

    logToConsole(`Enviando paquete BLE simulado (${payload.pef} L/min) a ${email}...`, 'info');

    btnSubmit.disabled = true;
    btnSubmit.textContent = "Obteniendo ubicación...";

    
    if ("geolocation" in navigator) {
        navigator.geolocation.getCurrentPosition(
            (position) => {
                payload.latitude = position.coords.latitude;
                payload.longitude = position.coords.longitude;
                logToConsole(`GPS obtenido: ${payload.latitude.toFixed(4)}, ${payload.longitude.toFixed(4)}`, 'info');
                enviarPayload(url, payload);
            },
            (error) => {
                logToConsole(`Error GPS: ${error.message}. Enviando sin datos ambientales.`, 'warn');
                enviarPayload(url, payload); 
            },
            { timeout: 10000 } 
        );
    } else {
        logToConsole("Tu navegador no soporta GPS. Enviando sin datos ambientales.", 'warn');
        enviarPayload(url, payload); 
    }
}

async function enviarPayload(url, payload) {
    btnSubmit.textContent = "Transmitiendo...";

    try {
        const response = await fetch(url, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
                "x-api-key": "ClaveSecretaParaMaestros" 
            },
            body: JSON.stringify(payload)
        });

        if (response.ok) {
            const data = await response.json();
            logToConsole(`¡Éxito! DB aceptó el registro.`, 'success');

            
            currentSimData = null;
            pefInput.value = ''; fev1Input.value = ''; fvcInput.value = '';
            severityBadge.classList.add('hidden');
        } else {
            const err = await response.json();
            logToConsole(`Error del API: ${JSON.stringify(err)}`, 'error');
        }
    } catch (error) {
        logToConsole(`Fallo de conexión: ${error.message}. ¿Está corriendo FastAPI?`, 'error');
    } finally {
        btnSubmit.textContent = "Emitir Soplido (POST)";
        validateForm();
    }
}

btnGenerate.addEventListener('click', generateRandomMeasurements);
patientEmailInput.addEventListener('input', validateForm);
btnSubmit.addEventListener('click', submitSpirometry);
