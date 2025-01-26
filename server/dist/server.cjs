"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const http_1 = require("http");
const ws_1 = require("ws");
// Express setup
const app = (0, express_1.default)();
app.use(express_1.default.json());
// Routes
app.get('/api/test', (_, res) => {
    res.json({ message: 'Success' });
});
app.get('/api/async_test', async (_, res) => {
    try {
        const result = await asyncOperation();
        res.json({ message: 'Success', data: result });
    }
    catch (error) {
        const message = error instanceof Error ? error.message : 'Unknown error';
        res.status(500).json({ message: 'Error', error: message });
    }
});
app.get('/api/cities', async (_, res) => {
    try {
        const response = await fetch('https://raw.githubusercontent.com/lutangar/cities.json/master/cities.json', {
            headers: { Accept: 'application/json' },
            signal: AbortSignal.timeout(5000),
        });
        if (!response.ok) {
            throw new Error(`HTTP error! status: ${response.status}`);
        }
        const rawCities = await response.json();
        const cities = transformCities(rawCities.slice(0, 10));
        res.json(cities);
    }
    catch (error) {
        const message = error instanceof Error ? error.message : 'Unknown error';
        res.status(500).json({ error: message });
    }
});
// Helper functions
async function asyncOperation() {
    return new Promise((resolve) => {
        setTimeout(() => resolve({ data: 'value' }), 1000);
    });
}
function transformCities(rawCities) {
    return rawCities.map((city) => ({
        name: city.name,
        latLng: {
            lat: parseFloat(city.lat),
            lng: parseFloat(city.lng),
        },
        population: city.population,
        width: Math.ceil(Math.log(city.population) * 2),
    }));
}
function validateWebSocketMessage(data) {
    if (!data || typeof data !== 'object')
        throw new Error('Invalid message');
    if (!('type' in data) || typeof data.type !== 'string')
        throw new Error('Invalid type');
    if (!('payload' in data))
        throw new Error('Missing payload');
    return data;
}
function handleWebSocketMessage(ws, message) {
    wss.clients.forEach((client) => {
        if (client !== ws && client.readyState === ws_1.WebSocket.OPEN) {
            client.send(JSON.stringify(message));
        }
    });
}
// WebSocket setup
const server = (0, http_1.createServer)(app);
const wss = new ws_1.WebSocketServer({ server });
wss.on('connection', (ws) => {
    console.log('Client connected');
    ws.on('message', (data) => {
        try {
            const message = validateWebSocketMessage(JSON.parse(data.toString()));
            handleWebSocketMessage(ws, message);
        }
        catch (error) {
            ws.send(JSON.stringify({
                type: 'error',
                payload: { message: 'Invalid message format' },
            }));
        }
    });
    ws.on('error', (error) => {
        console.error('WebSocket error:', error);
    });
    ws.on('close', () => {
        console.log('Client disconnected');
    });
});
// Graceful shutdown
const shutdownGracefully = () => {
    console.log('Shutting down gracefully...');
    server.close(() => {
        console.log('HTTP server closed');
        process.exit(0);
    });
};
process.on('SIGTERM', shutdownGracefully);
process.on('SIGINT', shutdownGracefully);
// Start server
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log(`Server running on port ${PORT}`));
